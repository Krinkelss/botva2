unit gdipCheckBox;

interface

uses
  Windows, Messages;

var
  ACBox : array of HWND;

procedure CheckBoxDestroy;
procedure CheckBoxSetText(h:HWND; Text:PChar); stdcall;
procedure CheckBoxGetText(h: HWND; Text: PChar; var NewSize: integer); stdcall;       
function CheckBoxCreateFromRes(hParent:HWND; Left,Top,Width,Height:integer; Memory:Pointer; GroupID, TextIndent:integer):HWND; stdcall;
function CheckBoxCreate(hParent:HWND; Left,Top,Width,Height:integer; FileName:PChar; GroupID, TextIndent:integer):HWND; stdcall;
procedure CheckBoxSetFont(h:HWND; Font:HFONT); stdcall;
procedure CheckBoxSetEvent(h:HWND; EventID:integer; Event:Pointer); stdcall;
procedure CheckBoxSetFontColor(h:HWND; NormalFontColor, FocusedFontColor, PressedFontColor, DisabledFontColor: Cardinal); stdcall;
function CheckBoxGetEnabled(h:HWND):boolean; stdcall;
procedure CheckBoxSetEnabled(h:HWND; Value:boolean); stdcall;
function CheckBoxGetVisibility(h:HWND):boolean; stdcall;
procedure CheckBoxSetVisibility(h:HWND; Value:boolean); stdcall;
procedure CheckBoxSetCursor(h:HWND; hCur:HICON); stdcall;
procedure CheckBoxSetChecked(h:HWND; Value:boolean); stdcall;
function CheckBoxGetChecked(h:HWND):boolean; stdcall;
procedure CheckBoxRefresh(h:HWND); stdcall;
procedure CheckBoxSetPosition(h:HWND; NewLeft, NewTop, NewWidth, NewHeight: integer); stdcall;
procedure CheckBoxGetPosition(h:HWND; var Left, Top, Width, Height: integer); stdcall;

implementation

uses
  for_png, addfunc, gdipButton;

procedure CheckBoxGroupChange(h:HWND);
var
  cb, cb2:PCBox;
  i:integer;
begin
  cb:=GetCheckBox(h);
  if cb=nil then Exit;

  for i:=Low(ACBox) to High(ACBox) do begin
    cb2:=GetCheckBox(ACBox[i]);
    if (cb2<>nil) and (cb<>cb2) and (cb^.GroupID=cb2^.GroupID) and IsCheckBoxState(cb2,bsChecked) then begin
      cb2^.bsState:=cb2^.bsState and not bsChecked;
      InvalidateRect(cb2.Handle,nil,False);
      UpdateWindow(cb2^.Handle);
    end;
  end;
end;

procedure CheckBoxGetPosition(h:HWND; var Left, Top, Width, Height: integer); stdcall;
var
  cbtn:PCBox;
begin
  cbtn:=GetCheckBox(h);
  if cbtn=nil then Exit;
  Left:=cbtn^.Left;
  Top:=cbtn^.Top;
  Width:=cbtn^.Width;
  Height:=cbtn^.Height;
end;

procedure CheckBoxSetPosition(h:HWND; NewLeft, NewTop, NewWidth, NewHeight: integer); stdcall;
begin
  MoveWindow(h, NewLeft, NewTop, NewWidth, NewHeight, True);
end;

procedure CheckBoxRefresh(h:HWND); stdcall;
begin
  BtnRefresh(h);
end;

function CheckBoxGetChecked(h:HWND):boolean; stdcall;
var
  cbtn:PCBox;
begin
  Result:=False;
  cbtn:=GetCheckBox(h);
  if cbtn=nil then Exit;
  Result:=IsCheckBoxState(cbtn,bsChecked);
end;

procedure CheckBoxSetChecked(h:HWND; Value:boolean); stdcall;
var
  cbtn:PCBox;
begin
  cbtn:=GetCheckBox(h);
  if cbtn=nil then Exit;

  if IsCheckBoxState(cbtn,bsChecked)<>Value then begin
    if Value then begin
      cbtn^.bsState:=cbtn^.bsState or bsChecked;
      if cbtn^.GroupID>0 then CheckBoxGroupChange(cbtn^.Handle);
    end else cbtn^.bsState:=cbtn^.bsState and not bsChecked;
    InvalidateRect(h,nil,False);
  end;
end;

procedure CheckBoxSetCursor(h:HWND; hCur:HICON); stdcall;
var
  cbtn:PCBox;
begin
  cbtn:=GetCheckBox(h);
  if (cbtn=nil) or (hCur=0) then Exit;
  DestroyCursor(cbtn^.Cursor);
  cbtn^.Cursor:=hCur;
end;

function CheckBoxGetVisibility(h:HWND):boolean; stdcall;
var
  cbtn:PCBox;
begin
  cbtn:=GetCheckBox(h);
  if cbtn=nil then begin
    Result:=False;
    Exit;
  end;
  Result:=cbtn^.Visible;
end;

procedure CheckBoxSetVisibility(h:HWND; Value:boolean); stdcall;
var
  cbtn:PCBox;
begin
  cbtn:=GetCheckBox(h);
  if cbtn=nil then Exit;
  if cbtn^.Visible<>Value then begin
    ShowWindow(h,integer(Value));
    cbtn^.Visible:=Value;
  end;
end;

function CheckBoxGetEnabled(h:HWND):boolean; stdcall;
begin
  Result := BtnGetEnabled(h);
end;

procedure CheckBoxSetEnabled(h:HWND; Value:boolean); stdcall;
begin
  BtnSetEnabled(h, Value);
end;

procedure CheckBoxSetFontColor(h:HWND; NormalFontColor, FocusedFontColor, PressedFontColor, DisabledFontColor: Cardinal); stdcall;
var
  cbtn:PCBox;
begin
  cbtn:=GetCheckBox(h);
  if cbtn=nil then Exit;
  cbtn^.NormalFontColor:=NormalFontColor;
  cbtn^.DisabledFontColor:=DisabledFontColor;
  cbtn^.FocusedFontColor:=FocusedFontColor;
  cbtn^.PressedFontColor:=PressedFontColor;
  InvalidateRect(h,nil,False);
end;

procedure CheckBoxSetEvent(h:HWND; EventID:integer; Event:Pointer); stdcall;
var
  btn:PCBox;
begin
  btn:=GetCheckBox(h);
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

procedure CheckBoxSetFont(h:HWND; Font:HFONT); stdcall;
begin
  BtnSetFont(h, Font);
end;

procedure CheckBoxSetText(h:HWND; Text:PChar); stdcall;
begin
  BtnSetText(h, Text);
end;

procedure CheckBoxGetText(h: HWND; Text: PChar; var NewSize: integer); stdcall;
begin
  BtnGetText(h, Text, NewSize);
end;

procedure DrawCheckBox(hBtnDC:HDC; r:TRect; btn:PCBox; img:Pointer; FontColor:DWORD);
var
  pGraphics:Pointer;
  ir,rw,r2:TRect;
  TextBtn:string;
  LenTextBtn:integer;
  BtnFont:HFONT;
  hParent:HWND;
  h:integer;
  iw,ih:UINT;
  hPDC,hDCMem:HDC;
  hBmp:HBITMAP;
begin
  if img=nil then Exit;
  // рисуем фон
  hParent:=GetAncestor(btn^.Handle,GA_PARENT);

  GetClientRect(hParent,r2);
  hPDC:=GetDC(hParent);
  hDCMem:=CreateCompatibleDC(hPDC);
  hBmp:=CreateCompatibleBitmap(hPDC,r2.Right,r2.Bottom);
  SelectObject(hDCMem,hBmp);
  ReleaseDC(hParent,hPDC);           

  SendMessage(hParent,WM_ERASEBKGND,Longint(hDCMem),0);
  CallWindowProc(Pointer(GetWindowLong(hParent,GWL_WNDPROC)),hParent,WM_PAINT,Longint(hDCMem),0);
  // рисуем кнопку
  pGraphics:=nil;
  GdipCreateFromHDC(hDCMem,pGraphics);
  GdipSetSmoothingMode(pGraphics, SmoothingModeHighSpeed{SmoothingModeAntiAlias});
  GdipSetInterpolationMode(pGraphics, InterpolationModeHighQualityBilinear{InterpolationModeHighQualityBicubic});

  GdipGetImageWidth(img,iw);
  GdipGetImageHeight(img,ih);
  ir.Left:=btn^.Left;
  ir.Top:=btn^.Top + (btn^.Height div 2) - (integer(ih) div 2);
  ir.Right:=iw;
  ir.Bottom:=ih;

  GdipDrawImageRectI(pGraphics,img,ir.Left,ir.Top,ir.Right,ir.Bottom);

  //GdipDrawImageRectI(pGraphics,img,btn^.Left,btn^.Top,btn^.Width,btn^.Height);
  GdipDeleteGraphics(pGraphics);

  //выводим текст
  LenTextBtn:=0;
  CheckBoxGetText(btn^.Handle, PChar(TextBtn), LenTextBtn);
  if LenTextBtn > 0 then begin
    SetLength(TextBtn, LenTextBtn);
    ZeroMemory(@TextBtn[1], LenTextBtn);
    BtnGetText(btn^.Handle, PChar(TextBtn), LenTextBtn);
    //SetRect(rw,btn^.Left+btn^.ShadowX+btn^.TextHorIndent,btn^.Top+btn^.ShadowY+btn^.TextVertIndent,btn^.Left+btn^.Width-btn^.ShadowX-btn^.TextHorIndent,btn^.Top+btn^.Height-btn^.ShadowY-btn^.TextVertIndent);
    SetRect(rw,btn^.Left+integer(iw)+btn^.TextIndent,btn^.Top,btn^.Left+btn^.Width,btn^.Top+btn^.Height);
    SetBkMode(hDCMem,TRANSPARENT);
    BtnFont:=SendMessage(btn^.Handle,WM_GETFONT,0,0);
    SelectObject(hDCMem,BtnFont);
    SetTextColor(hDCMem,FontColor);       //GetTextColor(hBtnDC)
    //выравнивание по центру
    if (btn^.TextFormat and balVCenter)=balVCenter then begin
      CopyRect(r2,rw);
      h:=DrawText(hDCMem, PChar(TextBtn), LenTextBtn,r2,btn^.TextFormat or DT_CALCRECT);
      if h<(rw.Bottom-rw.Top) then begin
        h:=(rw.Bottom-rw.Top-h) div 2;
        rw.Top:=rw.Top+h;
        rw.Bottom:=rw.Bottom-h;
      end;
    end;

    //if IsCheckBoxState(btn,bsPressed) and IsCheckBoxState(btn,bsFocused) then OffsetRect(rw,1,0);

    DrawText(hDCMem, PChar(TextBtn), LenTextBtn,rw,btn^.TextFormat and not balVCenter); //DT_VCENTER не примен€ют вместе с DT_WORDBREAK
  end; 

  BitBlt(hBtnDC,r.Left,r.Top,r.Right-r.Left,r.Bottom-r.Top,hDCMem,r.Left+btn^.Left,r.Top+btn^.Top,SRCCOPY);

  DeleteObject(hBmp);
  DeleteDC(hDCMem);
end;

function CheckBoxProc(hBtn: HWnd; Message: Cardinal; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  hBtnDC   : HDC;
  PBtnStr  : paintstruct;
  Pt       : TPoint;
  tme      : tagTRACKMOUSEEVENT;
  OldState : Cardinal;//integer;
//  i        : Cardinal;
  btn      : PCBox;
begin
  Result:=0;
  btn:=nil;
  if Message<>WM_UPDATE then begin
    btn:=GetCheckBox(hBtn);
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
      if not CursorInCheckBox(btn,Pt) then begin
        if not btn^.IsMouseLeave then btn^.bsState:=btn^.bsState and not bsFocused;
      end else btn^.bsState:=btn^.bsState or bsFocused;  //это придетс€ выполн€ть всегда, несмотр€ на IsMouseLeave
      if btn^.bsState<>OldState then begin
        InvalidateRect(hBtn,nil,False);
        UpdateWindow(hBtn);
      end;
      //теперь все остальное, а то при вызове callback'ов кнопка не успевает перерисоватьс€
      if CursorInCheckBox(btn,Pt) then begin
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
          if not IsCheckBoxState(btn,bsPressed) then begin
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
      if IsCheckBoxState(btn,bsEnabled) then begin
        GetCursorPos(Pt);
        if CursorInCheckBox(btn,Pt) then begin
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
      if IsCheckBoxState(btn,bsEnabled) then begin
        ReleaseCapture;
        if IsCheckBoxState(btn,bsPressed) then begin
          OldState:=btn^.bsState;
          btn^.bsState:=btn^.bsState and not bsPressed;
          GetCursorPos(Pt);
          if CursorInCheckBox(btn,Pt) then begin
          //  if btn^.IsCheckbox then begin
            if btn^.GroupID>0 then begin
              btn^.bsState:=btn^.bsState or bsChecked;
              CheckBoxGroupChange(hBtn);
            end else begin
              if IsCheckBoxState(btn,bsChecked) then btn^.bsState:=btn^.bsState and not bsChecked
                else btn^.bsState:=btn^.bsState or bsChecked;
            end;
          //  end;
          end;
          if btn^.bsState<>OldState then begin
            InvalidateRect(hBtn,nil,False);
            UpdateWindow(hBtn);
          end;
          if CursorInCheckBox(btn,Pt) and (btn^.OnClick<>nil) then TBtnEventProc(btn^.OnClick)(hBtn);
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
      if CursorInCheckBox(btn,Pt) then SetCursor(btn^.Cursor)
        else Result:=SendMessage(GetAncestor(hBtn,GA_PARENT){GetParent(hBtn)},WM_SETCURSOR,GetAncestor(hBtn,GA_PARENT){GetParent(hBtn)},lParam);
    end;                           
    WM_WINDOWPOSCHANGING: begin
      if (PWindowPos(lParam)^.flags and SWP_NOSIZE = 0) or (PWindowPos(lParam)^.flags and SWP_NOMOVE = 0) then begin
        if PWindowPos(lParam)^.flags and SWP_NOSIZE = 0 then begin
          //if btn^.OrigShadowWidth<>0 then begin
          //  GdipGetImageWidth(btn^.imgNormal,i);
          //  btn^.ShadowX:=Round(btn^.OrigShadowWidth*(PWindowPos(lParam)^.cx/i));
          //  GdipGetImageHeight(btn^.imgNormal,i);
          //  btn^.ShadowY:=Round(btn^.OrigShadowWidth*(PWindowPos(lParam)^.cy/i));
          //end;
          btn^.Width:=PWindowPos(lParam)^.cx;
          btn^.Height:=PWindowPos(lParam)^.cy;
        end;
        if PWindowPos(lParam)^.flags and SWP_NOMOVE = 0 then begin
          btn^.Left:=PWindowPos(lParam)^.x;
          btn^.Top:=PWindowPos(lParam)^.y;
        end;
        PWindowPos(lParam)^.flags:=PWindowPos(lParam)^.flags or SWP_NOCOPYBITS;
        //PostMessage(hBtn,WM_UPDATE,0,0);
      end;
    end;
    WM_PAINT: begin
      //–исуем на кнопке
      //if HDC(wParam)=0 then begin
      hBtnDC:=BeginPaint(hBtn,PBtnStr);
      if IsCheckBoxState(btn,bsEnabled) then begin
        if IsCheckBoxState(btn,bsPressed) and IsCheckBoxState(btn,bsFocused) then begin
          if IsCheckBoxState(btn,bsChecked) then DrawCheckBox(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgChkPressed,btn^.PressedFontColor)//CheckPressed
            else DrawCheckBox(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgPressed,btn^.PressedFontColor)//Pressed
        end else begin
          if not IsCheckBoxState(btn,bsPressed) and IsCheckBoxState(btn,bsFocused) then begin
            if IsCheckBoxState(btn,bsChecked) then DrawCheckBox(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgChkFocused,btn^.FocusedFontColor)//CheckFocused
              else DrawCheckBox(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgFocused,btn^.FocusedFontColor)//Focused
          end else begin
            if IsCheckBoxState(btn,bsChecked) then DrawCheckBox(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgChkNormal,btn^.NormalFontColor)//CheckNormal
              else DrawCheckBox(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgNormal,btn^.NormalFontColor)//Normal
          end;
        end;
      end else begin
        if IsCheckBoxState(btn,bsChecked) then DrawCheckBox(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgChkDisabled,btn^.DisabledFontColor)//CheckDisabled
          else DrawCheckBox(hBtnDC,PBtnStr.rcPaint,btn,btn^.imgDisabled,btn^.DisabledFontColor)//Disabled
      end;
      EndPaint(hBtn,PBtnStr);
      //end;
    end;
    WM_DESTROY: begin
      DeleteCheckBox(btn);
      Result:=CallWindowProc(Pointer(GetWindowLong(hBtn,GWL_WNDPROC)),hBtn, Message, wParam, lParam);
    end;
    else Result:=CallWindowProc(Pointer(btn^.OldProc),hBtn, Message, wParam, lParam);
  end;
end;

function CheckBoxCreateFromRes(hParent:HWND; Left,Top,Width,Height:integer; Memory:Pointer; GroupID, TextIndent:integer):HWND; stdcall;
begin
  Result:=0;
end;

function CheckBoxCreate(hParent:HWND; Left,Top,Width,Height:integer; FileName:PChar; GroupID, TextIndent:integer):HWND; stdcall;
var
  len,j:integer;
  img,simg,g,g1:Pointer;
  ImgCount,iw,ih:Cardinal;
//  rect:TRect;
//  DC:HDC;
  cb:PCBox;
begin
  Result:=0;
  if not gdipStart then Exit;
  try
    New(cb);
  except
    Exit;
  end;

  Result:=CreateWindow{Ex}({WS_EX_CONTROLPARENT,}'BUTTON','',WS_CHILD or WS_CLIPSIBLINGS or WS_TABSTOP or BS_OWNERDRAW or WS_VISIBLE,Left,Top,Width,Height,hParent,hInstance,0,nil);
  //BringWindowToTop(hBtn);
  if Result=0 then begin
    Dispose(cb);
    Exit;
  end;
  ZeroMemory(cb,SizeOf(TgdipCheckBox));
  cb^.Handle:=Result;
  cb^.bsState:=bsEnabled;
  cb^.bsNextBtnTrack:=False;
  //***************************
  img:=nil;
  CreateImage(img,FileName);
  GdipGetImageWidth(img,iw);
  GdipGetImageHeight(img,ih);
  ImgCount:=8;  //8 состо€ний
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
      1: cb^.imgNormal:=simg;
      2: cb^.imgFocused:=simg;
      3: cb^.imgPressed:=simg;
      4: cb^.imgDisabled:=simg;
      5: cb^.imgChkNormal:=simg;
      6: cb^.imgChkFocused:=simg;
      7: cb^.imgChkPressed:=simg;
      8: cb^.imgChkDisabled:=simg;
    end;
  end;
  GdipDisposeImage(img);
  GdipDeleteGraphics(g1);
  //***************************
  //cb^.hDCMem:=CreateCompatibleDC(0);
  //GetClientRect(hParent,rect);
  //DC:=GetDC(hParent);
  //cb^.hBmp:=CreateCompatibleBitmap(DC,rect.Right,rect.Bottom);
  //ReleaseDC(hParent,DC);
  //cb^.hOld:=SelectObject(cb^.hDCMem,cb^.hBmp);
  cb^.Left:=Left;
  cb^.Top:=Top;
  cb^.Width:=Width;
  cb^.Height:=Height;

  cb^.OnClick:=nil;
  cb^.OnMouseEnter:=nil;
  cb^.OnMouseLeave:=nil;
  cb^.OnMouseMove:=nil;
  cb^.OnMouseDown:=nil;
  cb^.OnMouseUp:=nil;
  cb^.IsMouseLeave:=True;

  //cb^.OrigShadowWidth:=ShadowWidth;
  //SetShadowWidth(btn);
  cb^.Cursor:=GetSysCursorHandle(OCR_NORMAL);
  //btn^.IsCheckBox:=IsCheckBtn;

  cb^.NormalFontColor:=0;
  cb^.DisabledFontColor:=0;
  cb^.FocusedFontColor:=0;
  cb^.PressedFontColor:=0;

  cb^.TextFormat:=balLeft or balVCenter;// DefaultTextFormat or DT_CENTER or balVCenter;//DT_CENTER or DT_VCENTER or DT_SINGLELINE;
  //cb^.Text:='CheckBox';
  cb^.TextIndent:=TextIndent;
  cb^.GroupID:=GroupID;
  //cb^.TextHorIndent:=0;
  //cb^.TextVertIndent:=0;

  cb^.Delete:=False;
  cb^.Visible:=True;

  //SendMessage(Result,WM_SETFONT,GetStockObject(DEFAULT_GUI_FONT),0);
  CheckBoxSetFont(Result,GetStockObject(DEFAULT_GUI_FONT));

  cb^.OldProc:=SetWindowLong(Result,GWL_WNDPROC,LongInt(@CheckBoxProc));
  SetWindowLong(Result,GWL_USERDATA,Longint(cb));
  InvalidateRect(Result,nil,False);

  len:=Length(ACBox);
  SetLength(ACBox,len+1);
  ACBox[len]:=Result;
end;

procedure CheckBoxDestroy;
var
  btn:PCBox;
  i:integer;
begin
  for i:=Low(ACBox) to High(ACBox) do begin
    btn:=GetCheckBox(ACBox[i]);
    if btn<>nil then DeleteCheckBox(btn);
  end;
  SetLength(ACBox,0);
end;

end.
