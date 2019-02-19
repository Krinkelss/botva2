unit gdipButton;

interface

uses
  Windows, Messages;

type
  TBtnEventProc = procedure(h:HWND); stdcall;

var
  ABtn : array of HWND;

const
  bsEnabled=$0001;
  bsFocused=$0010;
  bsPressed=$0100;
  bsChecked=$1000;

  balLeft    = DT_LEFT;    //0
  balCenter  = DT_CENTER;  //1
  balRight   = DT_RIGHT;   //2
  balVCenter = DT_VCENTER; //4 //не должен работать, но сделаем, чтобы работал
  DefaultTextFormat = DT_TOP or DT_WORDBREAK or DT_EDITCONTROL;

  BtnClickEventID      = 1;
  BtnMouseEnterEventID = 2;
  BtnMouseLeaveEventID = 3;
  BtnMouseMoveEventID  = 4;
  BtnMouseDownEventID  = 5;
  BtnMouseUpEventID    = 6;
                                      
function BtnCreateFromRes(hParent:HWND; Left,Top,Width,Height:integer; Memory:Pointer; ShadowWidth:integer; IsCheckBtn:boolean):HWND; stdcall;
function BtnCreate(hParent:HWND; Left,Top,Width,Height:integer; FileName:PChar; ShadowWidth:integer; IsCheckBtn:boolean):HWND; stdcall;
procedure BtnSetText(h:HWND; Text:PChar); stdcall;
procedure BtnGetText(h: HWND; Text: PChar; var NewSize: integer); stdcall;
procedure BtnSetTextAlignment(h:HWND; HorIndent, VertIndent:integer; Alignment:DWORD); stdcall;
function BtnGetVisibility(h:HWND):boolean; stdcall;
procedure BtnSetVisibility(h:HWND; Value:boolean); stdcall;
function BtnGetEnabled(h:HWND):boolean; stdcall;
procedure BtnSetEnabled(h:HWND; Value:boolean); stdcall;
procedure BtnSetFont(h:HWND; Font:HFONT); stdcall;
procedure BtnSetCursor(h:HWND; hCur:HICON); stdcall;
procedure BtnSetChecked(h:HWND; Value:boolean); stdcall;
function BtnGetChecked(h:HWND):boolean; stdcall;
procedure BtnSetFontColor(h:HWND; NormalFontColor, FocusedFontColor, PressedFontColor, DisabledFontColor: Cardinal); stdcall;
procedure BtnGetPosition(h:HWND; var Left, Top, Width, Height: integer); stdcall;
procedure BtnSetPosition(h:HWND; NewLeft, NewTop, NewWidth, NewHeight: integer); stdcall;
procedure BtnRefresh(h:HWND); stdcall;
procedure BtnSetEvent(h:HWND; EventID:integer; Event:Pointer); stdcall;
function GetSysCursorHandle(id:integer):Cardinal; stdcall;

procedure BtnDestroy;
function BtnProc(hBtn: HWnd; Message: Cardinal; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;

implementation

uses
  for_png, addfunc;

function GetSysCursorHandle(id:integer):Cardinal; stdcall;
begin
  Result:=LoadCursor(0,PAnsiChar(id));
end;

procedure DrawButton(hBtnDC:HDC; r:TRect; btn:PBtn; img:Pointer; FontColor:DWORD);
var
  pGraphics:Pointer;
  rw,r2:TRect;
  TextBtn:string;
  LenTextBtn:integer;
  BtnFont:HFONT;
  hParent:HWND;
  h:integer;
begin
  if img=nil then Exit;
  // рисуем фон
  hParent:=GetAncestor(btn^.hBtn,GA_PARENT);//GetParent(btn^.hBtn);
  SendMessage(hParent,WM_ERASEBKGND,Longint(btn^.hDCMem),0);
  CallWindowProc(Pointer(GetWindowLong(hParent,GWL_WNDPROC)),hParent,WM_PAINT,Longint(btn^.hDCMem),0);
  // рисуем кнопку
  pGraphics:=nil;
  GdipCreateFromHDC(btn^.hDCMem,pGraphics);
  GdipSetSmoothingMode(pGraphics, SmoothingModeHighSpeed{SmoothingModeAntiAlias});
  GdipSetInterpolationMode(pGraphics, InterpolationModeHighQualityBilinear{InterpolationModeHighQualityBicubic});
  GdipDrawImageRectI(pGraphics,img,btn^.Left,btn^.Top,btn^.Width,btn^.Height);
  GdipDeleteGraphics(pGraphics);
  //выводим текст
  LenTextBtn:=0;
  BtnGetText(btn^.hBtn, PChar(TextBtn), LenTextBtn);
  if LenTextBtn>0 then begin
    SetLength(TextBtn, LenTextBtn);
    ZeroMemory(@TextBtn[1], LenTextBtn);
    BtnGetText(btn^.hBtn, PChar(TextBtn), LenTextBtn);

    SetRect(rw,btn^.Left+btn^.ShadowX+btn^.TextHorIndent,btn^.Top+btn^.ShadowY+btn^.TextVertIndent,btn^.Left+btn^.Width-btn^.ShadowX-btn^.TextHorIndent,btn^.Top+btn^.Height-btn^.ShadowY-btn^.TextVertIndent);
    SetBkMode(btn^.hDCMem,TRANSPARENT);
    BtnFont:=SendMessage(btn^.hBtn,WM_GETFONT,0,0);
    SelectObject(btn^.hDCMem,BtnFont);
    SetTextColor(btn^.hDCMem,FontColor);       //GetTextColor(hBtnDC)
    //выравнивание по центру
    if (btn^.TextFormat and balVCenter)=balVCenter then begin
      CopyRect(r2,rw);
      h:=DrawText(btn^.hDCMem,PChar(TextBtn),LenTextBtn,r2,btn^.TextFormat or DT_CALCRECT);
      if h<(rw.Bottom-rw.Top) then begin
        h:=(rw.Bottom-rw.Top-h) div 2;
        rw.Top:=rw.Top+h;
        rw.Bottom:=rw.Bottom-h;
      end;
    end;

    if IsBtnState(btn,bsPressed) and IsBtnState(btn,bsFocused) then OffsetRect(rw,1,0);

    DrawText(btn^.hDCMem,PChar(TextBtn),LenTextBtn,rw,btn^.TextFormat and not balVCenter); //DT_VCENTER не примен€ют вместе с DT_WORDBREAK
  end;

  BitBlt(hBtnDC,r.Left,r.Top,r.Right-r.Left,r.Bottom-r.Top,btn^.hDCMem,r.Left+btn^.Left,r.Top+btn^.Top,SRCCOPY);
end;

function BtnProc(hBtn: HWnd; Message: Cardinal; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  hBtnDC   : HDC;
  PBtnStr  : paintstruct;
  Pt       : TPoint;
  tme      : tagTRACKMOUSEEVENT;
  OldState : Cardinal;//integer;
  i        : Cardinal;
  btn      : PBtn;
begin
  Result:=0;
  btn:=nil;
  if Message<>WM_UPDATE then begin
    btn:=GetBtn(hBtn);
    if btn=nil then //begin
      //Result:=CallWindowProc(Pointer(GetWindowLong(hBtn,GWL_WNDPROC)),hBtn, Message, wParam, lParam);
      Exit;
    //end;
  end;

  case Message of
    WM_UPDATE: begin
      InvalidateRect(hBtn,nil,False);
      UpdateWindow(hBtn);
    end;
    WM_NCPAINT:;
    WM_ERASEBKGND: Result:=1;
    WM_MOUSEMOVE: begin
      OldState:=btn^.bsState;
      GetCursorPos(Pt);
      //сначала перерисовываем, потом все остальное
      if not CursorInBtn(btn,Pt) then begin
        if not btn^.IsMouseLeave then btn^.bsState:=btn^.bsState and not bsFocused;
      end else btn^.bsState:=btn^.bsState or bsFocused;  //это придетс€ выполн€ть всегда, несмотр€ на IsMouseLeave
      if btn^.bsState<>OldState then begin
        InvalidateRect(hBtn,nil,False);
        UpdateWindow(hBtn);
      end;
      //теперь все остальное, а то при вызове callback'ов кнопка не успевает перерисоватьс€
      if CursorInBtn(btn,Pt) then begin
        if not btn^.bsNextBtnTrack then begin
          tme.cbSize:=SizeOf(tagTRACKMOUSEEVENT);
          tme.hwndTrack:=hBtn;
          tme.dwFlags:=TME_LEAVE;
          tme.dwHoverTime:=HOVER_DEFAULT;
          btn^.bsNextBtnTrack:=TrackMouseEvent(tme);
          btn^.IsMouseLeave:=False;
          if btn^.OnMouseEnter<>nil then TBtnEventProc(btn^.OnMouseEnter)(hBtn);
        end;
        if not btn^.IsMouseLeave then begin
          if btn^.OnMouseMove<>nil then TBtnEventProc(btn^.OnMouseMove)(hBtn);
        end;
      end else begin
        if not btn^.IsMouseLeave then
          if not IsBtnState(btn,bsPressed) then begin
            btn^.IsMouseLeave:=True;
            btn^.bsNextBtnTrack:=False;
            if btn^.OnMouseLeave<>nil then TBtnEventProc(btn^.OnMouseLeave)(hBtn);
          end;
      end;
    end;
    WM_MOUSELEAVE: begin
      if not btn^.IsMouseLeave then begin
        OldState:=btn^.bsState;
        btn^.IsMouseLeave:=True;
        btn^.bsState:=btn^.bsState and not bsFocused;// and not bsPressed;  //добавил  and not bsPressed дл€ трэкбара
        btn^.bsNextBtnTrack:=False;
        if btn^.bsState<>OldState then begin
          InvalidateRect(hBtn,nil,False);
          UpdateWindow(hBtn);
        end;
        if btn^.OnMouseLeave<>nil then TBtnEventProc(btn^.OnMouseLeave)(hBtn);
      end;
    end;
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK: begin
      if IsBtnState(btn,bsEnabled) then begin
        GetCursorPos(Pt);
        if CursorInBtn(btn,Pt) then begin
          if GetCapture<>hBtn then SetCapture(hBtn);
          OldState:=btn^.bsState;
          btn^.bsState:=btn^.bsState or bsFocused or bsPressed;
          if btn^.bsState<>OldState then begin
            InvalidateRect(hBtn,nil,False);
            UpdateWindow(hBtn);
          end;
          if btn^.OnMouseDown<>nil then TBtnEventProc(btn^.OnMouseDown)(hBtn);
        end else Result:=SendMessage(GetAncestor(hBtn,GA_PARENT){GetParent(hBtn)},Message,wParam,lParam);       
      end;
    end;
    WM_LBUTTONUP: begin
      if IsBtnState(btn,bsEnabled) then begin
        ReleaseCapture;
        if IsBtnState(btn,bsPressed) then begin
          OldState:=btn^.bsState;
          btn^.bsState:=btn^.bsState and not bsPressed;
          GetCursorPos(Pt);
          if CursorInBtn(btn,Pt) then begin
            if btn^.IsCheckbox then begin
              if IsBtnState(btn,bsChecked) then btn^.bsState:=btn^.bsState and not bsChecked
                else btn^.bsState:=btn^.bsState or bsChecked;
            end;
          end;
          if btn^.bsState<>OldState then begin
            InvalidateRect(hBtn,nil,False);
            UpdateWindow(hBtn);
          end;
          if CursorInBtn(btn,Pt) then
            if btn^.OnClick<>nil then TBtnEventProc(btn^.OnClick)(hBtn);
        end;
        if btn^.OnMouseUp<>nil then TBtnEventProc(btn^.OnMouseUp)(hBtn);
      end;
    end;
    WM_ENABLE: begin
      OldState:=btn^.bsState;
      if boolean(wParam) then btn^.bsState:=btn^.bsState or bsEnabled else btn^.bsState:=0;;
      if btn^.bsState<>OldState then begin
        InvalidateRect(hBtn,nil,False);
        UpdateWindow(hBtn);
      end;
      Result:=CallWindowProc(Pointer(btn^.OldProc),hBtn, Message, wParam, lParam);
    end;
    WM_SETCURSOR: begin
      GetCursorPos(Pt);
      if CursorInBtn(btn,Pt) then SetCursor(btn^.Cursor)
        else Result:=SendMessage(GetAncestor(hBtn,GA_PARENT){GetParent(hBtn)},WM_SETCURSOR,GetAncestor(hBtn,GA_PARENT){GetParent(hBtn)},lParam);
    end;                           
    WM_WINDOWPOSCHANGING: begin
      if (PWindowPos(lParam)^.flags and SWP_NOSIZE = 0) or (PWindowPos(lParam)^.flags and SWP_NOMOVE = 0) then begin
        if PWindowPos(lParam)^.flags and SWP_NOSIZE = 0 then begin
          if btn^.OrigShadowWidth<>0 then begin
            GdipGetImageWidth(btn^.imgNormal,i);
            btn^.ShadowX:=Round(btn^.OrigShadowWidth*(PWindowPos(lParam)^.cx/i));
            GdipGetImageHeight(btn^.imgNormal,i);
            btn^.ShadowY:=Round(btn^.OrigShadowWidth*(PWindowPos(lParam)^.cy/i));
          end;
          btn^.Width:=PWindowPos(lParam)^.cx;
          btn^.Height:=PWindowPos(lParam)^.cy;
        end;
        if PWindowPos(lParam)^.flags and SWP_NOMOVE = 0 then begin
          btn^.Left:=PWindowPos(lParam)^.x;
          btn^.Top:=PWindowPos(lParam)^.y;
        end;
        PWindowPos(lParam)^.flags:=PWindowPos(lParam)^.flags or SWP_NOCOPYBITS;
      end;
    end;
    WM_PAINT: begin
      //–исуем на кнопке
      //if HDC(wParam)=0 then begin
      hBtnDC:=BeginPaint(hBtn,PBtnStr);
      if IsBtnState(btn,bsEnabled) then begin
        if IsBtnState(btn,bsPressed) and IsBtnState(btn,bsFocused) then begin
          if IsBtnState(btn,bsChecked) then DrawButton(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgChkPressed,btn^.PressedFontColor)//CheckPressed
            else DrawButton(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgPressed,btn^.PressedFontColor)//Pressed
        end else begin
          if not IsBtnState(btn,bsPressed) and IsBtnState(btn,bsFocused) then begin
            if IsBtnState(btn,bsChecked) then DrawButton(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgChkFocused,btn^.FocusedFontColor)//CheckFocused
              else DrawButton(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgFocused,btn^.FocusedFontColor)//Focused
          end else begin
            if IsBtnState(btn,bsChecked) then DrawButton(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgChkNormal,btn^.NormalFontColor)//CheckNormal
              else DrawButton(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgNormal,btn^.NormalFontColor)//Normal
          end;
        end;
      end else begin
        if IsBtnState(btn,bsChecked) then DrawButton(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgChkDisabled,btn^.DisabledFontColor)//CheckDisabled
          else DrawButton(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgDisabled,btn^.DisabledFontColor)//Disabled
      end;
      EndPaint(hBtn,PBtnStr);
      //end;
    end;
    WM_DESTROY: begin
      DeleteBtn(btn);
      Result:=CallWindowProc(Pointer(GetWindowLong(hBtn,GWL_WNDPROC)),hBtn, Message, wParam, lParam);
    end;
    else Result:=CallWindowProc(Pointer(btn^.OldProc),hBtn, Message, wParam, lParam);
  end;
end;

procedure BtnSetTextAlignment(h:HWND; HorIndent, VertIndent:integer; Alignment:DWORD); stdcall;
var
  cbtn:PBtn;
begin
  cbtn:=GetBtn(h);
  if cbtn=nil then Exit;
  cbtn^.TextFormat:=DefaultTextFormat or Alignment;
  cbtn^.TextHorIndent:=HorIndent;
  cbtn^.TextVertIndent:=VertIndent;
  InvalidateRect(h,nil,False);
end;

procedure BtnGetPosition(h:HWND; var Left, Top, Width, Height: integer); stdcall;
var
  cbtn:PBtn;
begin
  cbtn:=GetBtn(h);
  if cbtn=nil then Exit;
  Left:=cbtn^.Left;
  Top:=cbtn^.Top;
  Width:=cbtn^.Width;
  Height:=cbtn^.Height;
end;

procedure BtnSetPosition(h:HWND; NewLeft, NewTop, NewWidth, NewHeight: integer); stdcall;
begin
  MoveWindow(h, NewLeft, NewTop, NewWidth, NewHeight, True);
end;

procedure BtnRefresh(h:HWND); stdcall;
begin
  InvalidateRect(h,nil,False);
  UpdateWindow(h);
end;

function BtnGetChecked(h:HWND):boolean; stdcall;
var
  cbtn:PBtn;
begin
  Result:=False;
  cbtn:=GetBtn(h);
  if cbtn=nil then Exit;
  if cbtn^.IsCheckbox then Result:=IsBtnState(cbtn,bsChecked);
end;

procedure BtnSetChecked(h:HWND; Value:boolean); stdcall;
var
  cbtn:PBtn;
begin
  cbtn:=GetBtn(h);
  if cbtn=nil then Exit;
  if cbtn^.IsCheckbox then
    if IsBtnState(cbtn,bsChecked)<>Value then begin
      if Value then cbtn^.bsState:=cbtn^.bsState or bsChecked else cbtn^.bsState:=cbtn^.bsState and not bsChecked;
      InvalidateRect(h,nil,False);
    end;
end;

procedure BtnSetCursor(h:HWND; hCur:HICON); stdcall;
var
  cbtn:PBtn;
begin
  cbtn:=GetBtn(h);
  if (cbtn=nil) or (hCur=0) then Exit;
  DestroyCursor(cbtn^.Cursor);
  cbtn^.Cursor:=hCur;
end;

procedure BtnSetFont(h:HWND; Font:HFONT); stdcall;
begin
  if not IsWindow(h) or (Font=0) then Exit;
  SendMessage(h,WM_SETFONT,WPARAM(Font),integer(True));
  InvalidateRect(h,nil,False);
end;

function BtnGetVisibility(h:HWND):boolean; stdcall;
var
  cbtn:PBtn;
begin
  cbtn:=GetBtn(h);
  if cbtn=nil then begin
    Result:=False;
    Exit;
  end;
  Result:=cbtn^.Visible;
//  if not IsWindow(h) then begin
//    Result:=False;
//    Exit;
//  end;
//  Result:=IsWindowVisible(h);
end;

procedure BtnSetVisibility(h:HWND; Value:boolean); stdcall;
var
  cbtn:PBtn;
begin
  cbtn:=GetBtn(h);
  if cbtn=nil then Exit;
  if cbtn^.Visible<>Value then begin
    ShowWindow(h,integer(Value));
    cbtn^.Visible:=Value;
  end;
//  if not IsWindow(h) then Exit;
//  if (IsWindowVisible(h)<>Value) or not IsWindowVisible(GetParent(h)) then ShowWindow(h,integer(Value));
  //not IsWindowVisible(GetParent(h))нужен т.к. когда родительское окно невидимо,
  //IsWindowVisible(hBtn) всегда возвращает False
end;

function BtnGetEnabled(h:HWND):boolean; stdcall;
begin
  if not IsWindow(h) then begin
    Result:=False;
    Exit;
  end;
  Result:=IsWindowEnabled(h);
end;

procedure BtnSetEnabled(h:HWND; Value:boolean); stdcall;
begin
  if not IsWindow(h) then Exit;
  if IsWindowEnabled(h)<>Value then begin
    EnableWindow(h, Value);
  end;
end;

procedure BtnSetText(h: HWND; Text: PChar); stdcall;
var
  TextBtn: string;
  NewSize: integer;
begin
  if not IsWindow(h) then Exit;

  NewSize := 0;
  BtnGetText(h, PChar(TextBtn), NewSize);
  SetLength(TextBtn, NewSize);
  if NewSize > 0 then begin
    ZeroMemory(@TextBtn[1], NewSize);
    BtnGetText(h, PChar(TextBtn), NewSize);
  end;

  if TextBtn <> string(Text) then begin
    SetWindowText(h, Text);
    InvalidateRect(h, nil, False);
  end;
end;

procedure BtnGetText(h: HWND; Text: PChar; var NewSize: integer); stdcall;
var
  txt: string;
begin
  if not IsWindow(h) then Exit;

  if NewSize = 0 then begin
    NewSize := SendMessage(h, WM_GETTEXTLENGTH, 0, 0);
    Exit;
  end;

  SetLength(txt, NewSize + 1); //нужно делать +1 дл€ терминатора - #0
  ZeroMemory(@txt[1], NewSize + 1);
  GetWindowText(h, PChar(txt), NewSize + 1);

  StrPCopy(Text, txt);
end;

procedure BtnSetFontColor(h:HWND; NormalFontColor, FocusedFontColor, PressedFontColor, DisabledFontColor: Cardinal); stdcall;
var
  cbtn:PBtn;
begin
  cbtn:=GetBtn(h);
  if cbtn=nil then Exit;
  cbtn^.NormalFontColor:=NormalFontColor;
  cbtn^.DisabledFontColor:=DisabledFontColor;
  cbtn^.FocusedFontColor:=FocusedFontColor;
  cbtn^.PressedFontColor:=PressedFontColor;
  InvalidateRect(h,nil,False);
end;

procedure BtnSetEvent(h:HWND; EventID:integer; Event:Pointer); stdcall;
var
  btn:PBtn;
begin
  btn:=GetBtn(h);
  if btn=nil then Exit;
  case EventID of
    BtnClickEventID      : btn^.OnClick:=Event;
    BtnMouseEnterEventID : btn^.OnMouseEnter:=Event;
    BtnMouseLeaveEventID : btn^.OnMouseLeave:=Event;
    BtnMouseMoveEventID  : btn^.OnMouseMove:=Event;
    BtnMouseDownEventID  : btn^.OnMouseDown:=Event;
    BtnMouseUpEventID    : btn^.OnMouseUp:=Event;
  end;
end;

function BtnCreateFromRes(hParent:HWND; Left,Top,Width,Height:integer; Memory:Pointer; ShadowWidth:integer; IsCheckBtn:boolean):HWND; stdcall;
begin

end;

function BtnCreate(hParent:HWND; Left,Top,Width,Height:integer; FileName:PChar; ShadowWidth:integer; IsCheckBtn:boolean):HWND; stdcall;
var
  len,j:integer;
  img,simg,g,g1:Pointer;
  ImgCount,iw,ih:Cardinal;
  rect:TRect;
  DC:HDC;
  btn:PBtn;
begin
  Result:=0;
  try
    New(btn);
  except
    Exit;
  end;

  if not gdipStart then Exit;

  Result:=CreateWindow{Ex}({WS_EX_CONTROLPARENT,}'BUTTON','',WS_CHILD or WS_CLIPSIBLINGS or WS_TABSTOP or BS_OWNERDRAW or WS_VISIBLE,Left,Top,Width,Height,hParent,hInstance,0,nil);
  //BringWindowToTop(hBtn);
  if Result=0 then begin
    Dispose(btn);
    Exit;
  end;
  ZeroMemory(btn,SizeOf(TgdipButton));
  btn^.hBtn:=Result;
  btn^.bsState:=bsEnabled;
  btn^.bsNextBtnTrack:=False;
  //***************************
  img:=nil;
  CreateImage(img,FileName);
  GdipGetImageWidth(img,iw);
  GdipGetImageHeight(img,ih);
  if IsCheckBtn then ImgCount:=8 else ImgCount:=4;
  ih:=ih div ImgCount;
  g1:=nil;
  GdipGetImageGraphicsContext(img,g1);
  for j:=1 to ImgCount do begin
    simg:=nil;
    GdipCreateBitmapFromGraphics(iw,ih,g1,simg);
    g:=nil;
    GdipGetImageGraphicsContext(simg,g);
    GdipSetSmoothingMode(g,SmoothingModeAntiAlias);
    GdipSetInterpolationMode(g,InterpolationModeHighQualityBicubic);
    GdipDrawImageRectRectI(g,img,0,0,integer(iw),integer(ih),0,integer(ih)*(j-1),integer(iw),integer(ih),UnitPixel,nil,nil,nil);
    GdipDeleteGraphics(g);
    case j of
      1: btn^.imgNormal:=simg;
      2: btn^.imgFocused:=simg;
      3: btn^.imgPressed:=simg;
      4: btn^.imgDisabled:=simg;
      5: btn^.imgChkNormal:=simg;
      6: btn^.imgChkFocused:=simg;
      7: btn^.imgChkPressed:=simg;
      8: btn^.imgChkDisabled:=simg;
    end;
  end;
  GdipDisposeImage(img);
  GdipDeleteGraphics(g1);
  //***************************
  btn^.hDCMem:=CreateCompatibleDC(0);
  GetClientRect(hParent,rect);
  DC:=GetDC(hParent);
  btn^.hBmp:=CreateCompatibleBitmap(DC,rect.Right,rect.Bottom);
  ReleaseDC(hParent,DC);
  btn^.hOld:=SelectObject(btn^.hDCMem,btn^.hBmp);
  btn^.Left:=Left;
  btn^.Top:=Top;
  btn^.Width:=Width;
  btn^.Height:=Height;

  btn^.OnClick:=nil;
  btn^.OnMouseEnter:=nil;
  btn^.OnMouseLeave:=nil;
  btn^.OnMouseMove:=nil;
  btn^.OnMouseDown:=nil;
  btn^.OnMouseUp:=nil;
  btn^.IsMouseLeave:=True;

  btn^.OrigShadowWidth:=ShadowWidth;
  SetShadowWidth(btn);
  btn^.Cursor:=GetSysCursorHandle(OCR_NORMAL);
  btn^.IsCheckBox:=IsCheckBtn;

  btn^.NormalFontColor:=0;
  btn^.DisabledFontColor:=0;
  btn^.FocusedFontColor:=0;
  btn^.PressedFontColor:=0;

  btn^.TextFormat:=DefaultTextFormat or DT_CENTER or balVCenter;//DT_CENTER or DT_VCENTER or DT_SINGLELINE;
  btn^.TextHorIndent:=0;
  btn^.TextVertIndent:=0;

  btn^.Delete:=False;
  btn^.Visible:=True;

  BtnSetFont(Result,GetStockObject(DEFAULT_GUI_FONT));

  btn^.OldProc:=SetWindowLong(Result,GWL_WNDPROC,LongInt(@BtnProc));
  SetWindowLong(Result,GWL_USERDATA,Longint(btn));

  InvalidateRect(Result,nil,False);
  
  len:=Length(ABtn);
  SetLength(ABtn,len+1);
  Abtn[len]:=Result;
end;

procedure BtnDestroy;
var
  btn:PBtn;
  i:integer;
begin
  for i:=Low(ABtn) to High(ABtn) do begin
    btn:=GetBtn(ABtn[i]);
    if btn<>nil then DeleteBtn(btn);
  end;
  SetLength(ABtn,0);
end;

end.
