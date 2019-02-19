unit addfunc;

interface

uses
  Windows, Messages, ActiveX;

type
  PCBox = ^TgdipCheckBox;
  TgdipCheckBox = packed record
    Handle             : HWND;
    Left,
    Top,
    Width,
    Height             : integer;
    OldProc            : Longint;
    bsState            : DWORD;
    bsNextBtnTrack     : boolean;
    imgNormal,
    imgFocused,
    imgPressed,
    imgDisabled,
    imgChkNormal,
    imgChkFocused,
    imgChkPressed,
    imgChkDisabled     : Pointer;
    //hDCMem             : HDC;
    //hOld               : HGDIOBJ;
    //hBmp               : HBITMAP;
    NormalFontColor,
    FocusedFontColor,
    PressedFontColor,
    DisabledFontColor  : Cardinal;
    //OrigShadowWidth,
    //ShadowX,
    //ShadowY            : integer;
    OnClick,
    OnMouseEnter,
    OnMouseLeave,
    OnMouseMove,
    OnMouseDown,
    OnMouseUp          : Pointer;
    Cursor             : HCURSOR;
    //IsCheckbox         : boolean;
    IsMouseLeave       : boolean;
    TextFormat         : DWORD;
    //Text               : PChar;
    GroupID,
    TextIndent         : integer;
    //TextHorIndent,
    //TextVertIndent     : integer;
    Delete,
    Visible            : boolean;
  end;

  PBtn = ^TgdipButton;
  TgdipButton = packed record
    hBtn               : HWND;
    Left,
    Top,
    Width,
    Height             : integer;
    OldProc            : Longint;
    bsState            : DWORD;
    bsNextBtnTrack     : boolean;
    imgNormal,
    imgFocused,
    imgPressed,
    imgDisabled,
    imgChkNormal,
    imgChkFocused,
    imgChkPressed,
    imgChkDisabled     : Pointer;
    hDCMem             : HDC;
    hOld               : HGDIOBJ;
    hBmp               : HBITMAP;
    NormalFontColor,
    FocusedFontColor,
    PressedFontColor,
    DisabledFontColor  : Cardinal;
    OrigShadowWidth,
    ShadowX,
    ShadowY            : integer;
    OnClick,
    OnMouseEnter,
    OnMouseLeave,
    OnMouseMove,
    OnMouseDown,
    OnMouseUp          : Pointer;
    Cursor             : HCURSOR;
    IsCheckbox         : boolean;
    IsMouseLeave       : boolean;
    TextFormat         : DWORD;
    TextHorIndent,
    TextVertIndent     : integer;
    Delete,
    Visible            : boolean;
  end;

  PImg = ^TImg;
  TImg = packed record
    Image       : Pointer;
    Left,
    Top         : integer;
    Width,
    Height      : Cardinal;
    IsBkg,
    Visible,
    Stretch     : boolean;
    PPrevImg,
    PNextImg    : PImg;
    WndInd      : integer;
    Delete      : boolean;
    VisibleRect : TRect;
    Transparent : integer;
  end;

  TAWnd = packed record
    Wnd            : HWND;
    BImg           : Pointer;
    FImg           : Pointer;
    OldProc        : Longint;
    hDCMem         : HDC;
    hBmp           : HBITMAP;
    hOld           : HGDIOBJ;
    PFirstImg,
    PLastImg       : PImg;
    RefreshBtn     : boolean;
    UpdateBkgRect,
    UpdateRect     : TRect;
  end;

var
  AWnd :array of TAWnd;

const
  WM_USER   = $0400;
  WM_UPDATE = WM_USER + 158;

function FileExists(const FileName:string):boolean;
//function ColorToRGB(Color:integer):Longint;
//function MakeColor(a,r,g,b:Byte):DWORD;
function GetWndInd(h:HWND):integer;
function AddWnd(h:HWND):integer;   
function AddImageFromRes(Ind:integer; Memory:Pointer; Size: Integer; l,t:integer;w,h:Cardinal; Stretch,IsBkg:boolean):PImg;
function AddImage(Ind:integer; FileName:PChar; l,t:integer;w,h:Cardinal; Stretch,IsBkg:boolean):PImg;
procedure CreateImageFromRes(out img:Pointer; Memory:Pointer; Size: Integer);
procedure CreateImage(out img:Pointer; fn:PChar);
procedure SetFullImage(ind:integer;IsBkg:boolean;UpdRect:PRect);
procedure DeleteImage(wndind:integer;pimg:PImg);
procedure DeleteWnd(wndind:integer);
function RefreshChildWnd(Wnd:HWND; lParam:Longint):BOOL; stdcall;
procedure DrawFormToDCMem(WndInd:integer;UpdateRect:PRect);
function GetImg(img:Longint):PImg;

function CursorInBtn(btn:PBtn;p:TPoint):boolean;
function IsBtnState(btn:PBtn; State:DWORD):boolean;
procedure SetShadowWidth(btn:PBtn);
procedure DeleteBtn(btn:PBtn);
function GetBtn(btn:HWND):PBtn;
function GetCheckBox(btn:HWND):PCBox;
procedure DeleteCheckBox(btn:PCBox);
function IsCheckBoxState(btn:PCBox; State:DWORD):boolean;
function CursorInCheckBox(btn:PCBox;p:TPoint):boolean;
function StrPCopy(Dest: PChar; const Source: string): PChar;

implementation

uses
  main, for_png, gdipButton;

function StrLCopy(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     ESI,EAX
        MOV     EDI,EDX
        MOV     EBX,ECX
        XOR     AL,AL
        TEST    ECX,ECX
        JZ      @@1
        REPNE   SCASB
        JNE     @@1
        INC     ECX
@@1:    SUB     EBX,ECX
        MOV     EDI,ESI
        MOV     ESI,EDX
        MOV     EDX,EDI
        MOV     ECX,EBX
        SHR     ECX,2
        REP     MOVSD
        MOV     ECX,EBX
        AND     ECX,3
        REP     MOVSB
        STOSB
        MOV     EAX,EDX
        POP     EBX
        POP     ESI
        POP     EDI
end;

function StrPCopy(Dest: PChar; const Source: string): PChar;
begin
  Result := StrLCopy(Dest, PChar(Source), Length(Source));
end;

function GetBtn(btn:HWND):PBtn;
var
  cbtn:PBtn;
begin
  Result:=nil;
  try
    if IsWindow(btn) then begin
      cbtn:=PBtn(GetWindowLong(btn,GWL_USERDATA));
      if Assigned(cbtn) then
        if not cbtn^.Delete then Result:=cbtn;
    end;
  except
  end;
end;

function GetCheckBox(btn:HWND):PCBox;
var
  cbtn:PCBox;
begin
  Result:=nil;
  try
    if IsWindow(btn) then begin
      cbtn:=PCBox(GetWindowLong(btn,GWL_USERDATA));
      if Assigned(cbtn) then
        if not cbtn^.Delete then Result:=cbtn;
    end;
  except
  end;
end;

function GetFormColor(k:integer):DWORD;
  const
//  AlphaShift = 24;
  RedShift   = 16;
  GreenShift = 8;
  BlueShift  = 0;
var
  MemDC:HDC;
  BMP,oldBMP:HBITMAP;
  {a,}r,g,b:byte;
  Clr:DWORD;
begin
  MemDC:=CreateCompatibleDC(AWnd[k].hDCMem);
  BMP:=CreateCompatibleBitmap(AWnd[k].hDCMem,1,1);
  oldBMP:=SelectObject(MemDC,BMP);
  CallWindowProc(Pointer(AWnd[k].OldProc),AWnd[k].Wnd,WM_ERASEBKGND,Longint(MemDC),0);
  Clr:=GetPixel(MemDC,0,0);
  SelectObject(MemDC,oldBMP);
  DeleteDC(MemDC);
  DeleteObject(BMP);
//  a:=$FF;
  b:=Clr shr RedShift;
  Clr:=Clr-(b shl RedShift);
  g:=Clr shr GreenShift;
  Clr:=Clr-(g shl GreenShift);
  r:=Clr shr BlueShift;
  Result:=(DWORD(b) shl  BlueShift) or (DWORD(g) shl GreenShift) or (DWORD(r) shl   RedShift){ or (DWORD(a) shl AlphaShift)};
end;

{procedure EraseBkg(k:integer;ur:PRect);
var
  BkgColor:DWORD;
  Brush:HBRUSH;
begin
  if not (ur=nil) then begin
    BkgColor:=GetFormColor(k);
    Brush:=CreateSolidBrush(BkgColor);
    FillRect(AWnd[k].hDCMem,ur^,Brush);
    DeleteObject(Brush);
  end else SendMessage(AWnd[k].Wnd,WM_ERASEBKGND,Longint(AWnd[k].hDCMem),0);
end;}

function GetImg(img:Longint):PImg;
begin
  Result:=nil;
  try
    if Assigned(PImg(img)) then
      if not PImg(img)^.Delete then Result:=PImg(img);
  except
  end;
end;

procedure DrawFormToDCMem(WndInd:integer;UpdateRect:PRect);
var
  pGraphics:Pointer;
  r:TRect;
  mdc:HDC;
  oldbmp:HGDIOBJ;
  bmp:HBITMAP;
begin
  GetClientRect(AWnd[WndInd].Wnd,r);
  //нужно очищать только UpdateRect, а не весь AWnd[WndInd].hDCMem
  //SendMessage(AWnd[WndInd].Wnd,WM_ERASEBKGND,Longint(AWnd[WndInd].hDCMem),0);
  //EraseBkg(WndInd,UpdateRect);

  mdc:=CreateCompatibleDC(AWnd[WndInd].hDCMem);
  bmp:=CreateCompatibleBitmap(AWnd[WndInd].hDCMem,r.Right,r.Bottom);
  oldbmp:=SelectObject(mdc,bmp);

//  CallWindowProc(Pointer(AWnd[WndInd].OldProc),AWnd[WndInd].Wnd,WM_ERASEBKGND,Longint(mdc),0);

  pGraphics:=nil;
  GdipCreateFromHDC(mdc{AWnd[WndInd].hDCMem},pGraphics);
  if AWnd[WndInd].BImg<>nil then
    //GdipDrawImageRectRectI(pGraphics,AWnd[WndInd].BImg,0,0,r.Right,r.Bottom,0,0,r.Right,r.Bottom,UnitPixel,nil,nil,nil);
    GdipDrawImageRectRectI(pGraphics,AWnd[WndInd].BImg,UpdateRect^.Left,UpdateRect^.Top,UpdateRect^.Right-UpdateRect^.Left,UpdateRect^.Bottom-UpdateRect^.Top,UpdateRect^.Left,UpdateRect^.Top,UpdateRect^.Right-UpdateRect^.Left,UpdateRect^.Bottom-UpdateRect^.Top,UnitPixel,nil,nil,nil);
  //этот WM_PAINT перерисует все содержимое в AWnd[WndInd].hDCMem
  //еще один буфер????????????
  CallWindowProc(Pointer(AWnd[WndInd].OldProc),AWnd[WndInd].Wnd,WM_PAINT,Longint(mdc{AWnd[WndInd].hDCMem}),0);
  if AWnd[WndInd].FImg<>nil then
    //GdipDrawImageRectRectI(pGraphics,AWnd[WndInd].FImg,0,0,r.Right,r.Bottom,0,0,r.Right,r.Bottom,UnitPixel,nil,nil,nil);
    GdipDrawImageRectRectI(pGraphics,AWnd[WndInd].FImg,UpdateRect^.Left,UpdateRect^.Top,UpdateRect^.Right-UpdateRect^.Left,UpdateRect^.Bottom-UpdateRect^.Top,UpdateRect^.Left,UpdateRect^.Top,UpdateRect^.Right-UpdateRect^.Left,UpdateRect^.Bottom-UpdateRect^.Top,UnitPixel,nil,nil,nil);
  GdipDeleteGraphics(pGraphics);

  BitBlt(AWnd[WndInd].hDCMem,UpdateRect^.Left,UpdateRect^.Top,UpdateRect^.Right-UpdateRect^.Left,UpdateRect^.Bottom-UpdateRect^.Top,mdc,UpdateRect^.Left,UpdateRect^.Top,SRCCOPY);

  SelectObject(mdc,oldbmp);
  DeleteDC(mdc);
  DeleteObject(bmp);
end;

function RefreshChildWnd(Wnd:HWND; lParam:Longint):BOOL; stdcall;
var
  ir,br:TRect;
begin
  if IsWindowVisible(Wnd) then begin
    GetWindowRect(Wnd,br);
    ScreenToClient(GetAncestor(Wnd,GA_PARENT){GetParent(Wnd)},br.TopLeft);
    ScreenToClient(GetAncestor(Wnd,GA_PARENT){GetParent(Wnd)},br.BottomRight);
    if IntersectRect(ir,br,PRect(lParam)^) then PostMessage(Wnd,WM_UPDATE,0,0);
  end;
  Result:=True;
end;

procedure SetShadowWidth(btn:PBtn);
var
  iHeight,iWidth:Cardinal;
  rc:TRect;
begin
  if btn^.OrigShadowWidth=0 then begin
    btn^.ShadowX:=0;
    btn^.ShadowY:=0;
  end else begin
    GetWindowRect(btn^.hBtn,rc);
    OffsetRect(rc,-rc.Left,-rc.Top);
    GdipGetImageWidth(btn^.imgNormal,iWidth);
    GdipGetImageHeight(btn^.imgNormal,iHeight);
    btn^.ShadowX:=Round(btn^.OrigShadowWidth*(rc.Right/iWidth));
    btn^.ShadowY:=Round(btn^.OrigShadowWidth*(rc.Bottom/iHeight));
  end;
end;

function IsBtnState(btn:PBtn; State:DWORD):boolean;
begin
  Result:=(btn^.bsState and State)=State;
end;

function IsCheckBoxState(btn:PCBox; State:DWORD):boolean;
begin
  Result:=(btn^.bsState and State)=State;
end;

function CursorInBtn(btn:PBtn;p:TPoint):boolean;
var
  rc:TRect;
begin
  ScreenToClient(btn^.hBtn,p);
  GetClientRect(btn^.hBtn,rc);
  Result:=False;
  SetRect(rc,btn^.ShadowX,btn^.ShadowY,rc.Right-btn^.ShadowX,rc.Bottom-btn^.ShadowY);
  if (p.X>=rc.Left) and (p.X<=rc.Right) and (p.Y>=rc.Top) and (p.Y<=rc.Bottom) then Result:=True;
end;

function CursorInCheckBox(btn:PCBox;p:TPoint):boolean;
var
  rc:TRect;
begin
  ScreenToClient(btn^.Handle,p);
  GetClientRect(btn^.Handle,rc);
  Result:=False;
  //SetRect(rc,btn^.ShadowX,btn^.ShadowY,rc.Right-btn^.ShadowX,rc.Bottom-btn^.ShadowY);
  if (p.X>=rc.Left) and (p.X<=rc.Right) and (p.Y>=rc.Top) and (p.Y<=rc.Bottom) then Result:=True;
end;

procedure DeleteBtn(btn:PBtn);
begin
  SetWindowLong(btn^.hBtn,GWL_WNDPROC,btn^.OldProc);
  SetWindowLong(btn^.hBtn,GWL_USERDATA,0);
  btn^.Delete:=True;

  if btn^.imgNormal<>nil then GdipDisposeImage(btn^.imgNormal);
  if btn^.imgFocused<>nil then  GdipDisposeImage(btn^.imgFocused);
  if btn^.imgPressed<>nil then GdipDisposeImage(btn^.imgPressed);
  if btn^.imgDisabled<>nil then GdipDisposeImage(btn^.imgDisabled);
  if btn^.imgChkNormal<>nil then GdipDisposeImage(btn^.imgChkNormal);
  if btn^.imgChkFocused<>nil then GdipDisposeImage(btn^.imgChkFocused);
  if btn^.imgChkPressed<>nil then GdipDisposeImage(btn^.imgChkPressed);
  if btn^.imgChkDisabled<>nil then GdipDisposeImage(btn^.imgChkDisabled);

  SelectObject(btn^.hDCMem, btn^.hOld);
  DeleteObject(btn^.hBmp);
  DeleteDC(btn^.hDCMem);

  DestroyCursor(btn^.Cursor);

  Dispose(btn);
end;

procedure DeleteCheckBox(btn:PCBox);
begin
  SetWindowLong(btn^.Handle,GWL_WNDPROC,btn^.OldProc);
  SetWindowLong(btn^.Handle,GWL_USERDATA,0);
  btn^.Delete:=True;

  if btn^.imgNormal<>nil then GdipDisposeImage(btn^.imgNormal);
  if btn^.imgFocused<>nil then  GdipDisposeImage(btn^.imgFocused);
  if btn^.imgPressed<>nil then GdipDisposeImage(btn^.imgPressed);
  if btn^.imgDisabled<>nil then GdipDisposeImage(btn^.imgDisabled);
  if btn^.imgChkNormal<>nil then GdipDisposeImage(btn^.imgChkNormal);
  if btn^.imgChkFocused<>nil then GdipDisposeImage(btn^.imgChkFocused);
  if btn^.imgChkPressed<>nil then GdipDisposeImage(btn^.imgChkPressed);
  if btn^.imgChkDisabled<>nil then GdipDisposeImage(btn^.imgChkDisabled);

  //SelectObject(btn^.hDCMem, btn^.hOld);
  //DeleteObject(btn^.hBmp);
  //DeleteDC(btn^.hDCMem);

  DestroyCursor(btn^.Cursor);

  Dispose(btn);
end;

procedure DeleteWnd(wndind:integer);
var
  Last:integer;
begin
  SetWindowLong(AWnd[wndind].Wnd,GWL_WNDPROC,AWnd[wndind].OldProc);
  if AWnd[wndind].BImg<>nil then GdipDisposeImage(AWnd[wndind].BImg);
  if AWnd[wndind].FImg<>nil then GdipDisposeImage(AWnd[wndind].FImg);
  SelectObject(AWnd[wndind].hDCMem, AWnd[wndind].hOld);
  DeleteObject(AWnd[wndind].hBmp);
  DeleteDC(AWnd[wndind].hDCMem);
  Last:=High(AWnd);
  if wndind<Last then move(AWnd[wndind+1],AWnd[wndind],(Last-wndind)*SizeOf(AWnd[wndind]));
  SetLength(AWnd,Last);
end;

procedure DeleteImage(wndind:integer;pimg:PImg);
begin
  pimg^.Delete:=True;
  if pimg^.Image<>nil then GdipDisposeImage(pimg^.Image);
  if pimg^.PNextImg<>nil then pimg^.PNextImg^.PPrevImg:=pimg^.PPrevImg else AWnd[wndind].PLastImg:=pimg^.PPrevImg;
  if pimg^.PPrevImg<>nil then pimg^.PPrevImg^.PNextImg:=pimg^.PNextImg else AWnd[wndind].PFirstImg:=pimg^.PNextImg;
  Dispose(pimg);
end;

procedure CreateEmptyImage(out img:Pointer; WndInd:integer);
var
  cRect:TRect;
//  pGraphics:Pointer;
begin
  GetClientRect(AWnd[WndInd].Wnd,cRect);
  //почему-то изображения созданные с помощью GdipCreateBitmapFromScan0 рисуются намного дольше, чем созданные способом ниже
  //не тот формат пикселя был
  GdipCreateBitmapFromScan0(cRect.Right,cRect.Bottom,0,PixelFormat32bppPARGB,nil,img);
//  pGraphics:=nil;
//  GdipCreateFromHWND(AWnd[WndInd].Wnd,pGraphics);
//  GdipCreateBitmapFromGraphics(cRect.Right,cRect.Bottom,pGraphics,img); //получаем 32-битный Image
//  GdipDeleteGraphics(pGraphics);
end;

function IsImgStretched(k11,k12,k21,k22:integer):boolean;
begin
  Result:=k11<>k12;
  Result:=Result or (k21<>k22);
end;

procedure SetFullImage(ind:integer;IsBkg:boolean;UpdRect:PRect);
var
  pGraphics:Pointer;
  img:Pointer;
  cimg:Pimg;
  cm:TColorMatrix;
  ImgAttr:GpImageAttributes;
  ImgRect,DrawRect,DstRect,SrcRect:TRect;
  DstRectF,SrcRectF:TRectF;
  kw,kh:Single;
  IsEmptyLayer:boolean;
  BkgColor:DWORD;
  //*******************************************************************
  procedure CMInit(var cm:TColorMatrix);
  var
    i,j:integer;
  begin
    for i:=0 to 4 do
      for j:=0 to 4 do
        if i=j then cm[i,j]:=1 else cm[i,j]:=0;
  end;
  //*******************************************************************

begin
  if IsBkg then img:=AWnd[ind].BImg else img:=AWnd[ind].FImg;
  if (AWnd[ind].PFirstImg<>nil) or IsBkg then begin
    if img=nil then CreateEmptyImage(img,ind);

    pGraphics:=nil;
    GdipGetImageGraphicsContext(img,pGraphics);
    GdipSetSmoothingMode(pGraphics, SmoothingModeHighSpeed{SmoothingModeAntiAlias});
    GdipSetInterpolationMode(pGraphics, InterpolationModeHighQualityBilinear{InterpolationModeHighQualityBicubic});

    if IsBkg then BkgColor:=$FF000000 or GetFormColor(ind) else BkgColor:=0;
    GdipSetClipRectI(pGraphics,UpdRect^.Left,UpdRect^.Top,UpdRect^.Right-UpdRect^.Left,UpdRect^.Bottom-UpdRect^.Top,CombineModeReplace);
    //если задний слой, то заливаем цветом формы-родителя, т.к. отключен WM_ERASEBKGND в DrawFormToDCMem
    GdipGraphicsClear(pGraphics,BkgColor);
    GdipResetClip(pGraphics);

    CMInit(cm);
    GdipCreateImageAttributes(ImgAttr);

    IsEmptyLayer:=True;
    cimg:=AWnd[ind].PFirstImg;
    while cimg<>nil do begin
      if (cimg^.IsBkg=IsBkg) and cimg^.Visible and (cimg^.Transparent>0) and (cimg^.VisibleRect.Right>0) and (cimg^.VisibleRect.Bottom>0) then begin
        if IsEmptyLayer then IsEmptyLayer:=False; //определяем пустой слой или нет
        //получаем прямоугольник изображения в координатах окна-родителя
        SetRect(ImgRect,cimg^.Left,cimg^.Top,cimg^.Left+integer(cimg^.Width),cimg^.Top+integer(cimg^.Height));
        if IntersectRect(DrawRect,ImgRect,UpdRect^) then begin
          //если нет масштабирования изображения
          if not IsImgStretched(cimg^.Width,cimg^.VisibleRect.Right,cimg^.Height,cimg^.VisibleRect.Bottom) then begin
            SetRect(SrcRect,(DrawRect.Left-cimg^.Left)+cimg^.VisibleRect.Left,  (DrawRect.Top-cimg^.Top)+cimg^.VisibleRect.Top,
                            (DrawRect.Right-cimg^.Left)+cimg^.VisibleRect.Left, (DrawRect.Bottom-cimg^.Top)+cimg^.VisibleRect.Top);
            if not IsRectEmpty(SrcRect) then begin
              SetRect(SrcRect,SrcRect.Left,SrcRect.Top,SrcRect.Right-SrcRect.Left,SrcRect.Bottom-SrcRect.Top);
              SetRect(DstRect,DrawRect.Left,DrawRect.Top,DrawRect.Right-DrawRect.Left,DrawRect.Bottom-DrawRect.Top);
              if cimg^.Transparent<>255 then begin
                cm[3,3]:=cimg^.Transparent/255; //alpha channel
                GdipSetImageAttributesColorMatrix(ImgAttr,ColorAdjustTypeDefault,True,@cm,nil,ColorMatrixFlagsDefault);
                GdipDrawImageRectRectI(pGraphics,cimg^.Image,DstRect.Left,DstRect.Top,DstRect.Right,DstRect.Bottom,SrcRect.Left,SrcRect.Top,SrcRect.Right,SrcRect.Bottom,UnitPixel,ImgAttr,nil,nil);
              end else GdipDrawImageRectRectI(pGraphics,cimg^.Image,DstRect.Left,DstRect.Top,DstRect.Right,DstRect.Bottom,SrcRect.Left,SrcRect.Top,SrcRect.Right,SrcRect.Bottom,UnitPixel,nil,nil,nil);
            end;
          end else begin  //если масштабированное изображение
            kw:=cimg^.Width/cimg^.VisibleRect.Right;
            kh:=cimg^.Height/cimg^.VisibleRect.Bottom;
            SetRectF(SrcRectF,(DrawRect.Left-cimg^.Left)/kw+cimg^.VisibleRect.Left, (DrawRect.Top-cimg^.Top)/kh+cimg^.VisibleRect.Top,
                            (DrawRect.Right-cimg^.Left)/kw+cimg^.VisibleRect.Left,  (DrawRect.Bottom-cimg^.Top)/kh+cimg^.VisibleRect.Top);
            if not IsRectFEmpty(SrcRectF) then begin
              SetRectF(SrcRectF,SrcRectF.Left,SrcRectF.Top,SrcRectF.Right-SrcRectF.Left,SrcRectF.Bottom-SrcRectF.Top);
              SetRectF(DstRectF,DrawRect.Left,DrawRect.Top,DrawRect.Right-DrawRect.Left,DrawRect.Bottom-DrawRect.Top);
              if cimg^.Transparent<>255 then begin
                cm[3,3]:=cimg^.Transparent/255; //alpha channel
                GdipSetImageAttributesColorMatrix(ImgAttr,ColorAdjustTypeDefault,True,@cm,nil,ColorMatrixFlagsDefault);
                GdipDrawImageRectRect(pGraphics,cimg^.Image,DstRectF.Left,DstRectF.Top,DstRectF.Right,DstRectF.Bottom,SrcRectF.Left,SrcRectF.Top,SrcRectF.Right,SrcRectF.Bottom,UnitPixel,ImgAttr,nil,nil);
              end else GdipDrawImageRectRect(pGraphics,cimg^.Image,DstRectF.Left,DstRectF.Top,DstRectF.Right,DstRectF.Bottom,SrcRectF.Left,SrcRectF.Top,SrcRectF.Right,SrcRectF.Bottom,UnitPixel,nil,nil,nil);
            end;
          end; {if not IsImgStretched}
        end;
      end;
      cimg:=cimg^.PNextImg;
    end; {while}
    if not IsBkg and IsEmptyLayer then begin  //если нет ни одной картинки относящейся к слою, то удаляем его
      //нельзя удалять задний слой, т.к. отключен WM_ERASEBKGND
      if img<>nil then GdipDisposeImage(img);
      img:=nil;
    end;
    GdipDisposeImageAttributes(ImgAttr);
  end else begin  //если был всего один слой и в нем удалили последнюю картинку, то удаляем сам слой (только для верхнего слоя)
    if img<>nil then GdipDisposeImage(img);
    img:=nil;
  end; {if}
  if IsBkg then AWnd[ind].BImg:=img else AWnd[ind].FImg:=img;
  GdipDeleteGraphics(pGraphics);
end;

{procedure CreateImage(out img:Pointer; fn:PChar);
var
  ns:integer;
begin
  if img<>nil then begin
    GdipDisposeImage(img);
    img:=nil;
  end;
  GdipLoadImageFromFile(StringToPWideChar(fn,ns),img);
end;}

{procedure CreateImage(out img: Pointer; FileName: PChar);
var
  Stream: IStream;
  hMem,hFile,FileSize: DWORD;
  MemPtr: Pointer;
  iw,ih:UINT;
  g,g1:Pointer;
  CloneImg:Pointer;
begin
  hFile:=CreateFileA(FileName,GENERIC_READ,FILE_SHARE_READ or FILE_SHARE_WRITE,nil,OPEN_EXISTING,0,0);
  if hFile=INVALID_HANDLE_VALUE then Exit;
  FileSize:=GetFileSize(hFile,nil);
  hMem:=LocalAlloc(LMEM_MOVEABLE,FileSize);
  if hMem=0 then begin
    CloseHandle(hFile);
    Exit;
  end;
  MemPtr:=LocalLock(hMem);
  if MemPtr=nil then begin
    LocalFree(hMem);
    CloseHandle(hFile);
    Exit;
  end;
  if not ReadFile(hFile,MemPtr^,GetFileSize(hFile,nil),FileSize,nil) then begin
    LocalUnlock(hMem);
    LocalFree(hMem);
    CloseHandle(hFile);
    Exit;
  end;
  LocalUnlock(hMem);
  CloseHandle(hFile);
  if not (CreateStreamOnHGlobal(hMem,true,Stream)=S_OK) then begin
    LocalFree(hMem);
    Exit;
  end;

  if img<>nil then begin
    GdipDisposeImage(img);
    img:=nil;
  end;

  CloneImg:=nil;
  GdipLoadImageFromStream(Stream,CloneImg);
  GdipGetImageWidth(CloneImg,iw);
  GdipGetImageHeight(CloneImg,ih);
  g1:=nil;
  GdipGetImageGraphicsContext(CloneImg,g1);
  img:=nil;
  GdipCreateBitmapFromGraphics(iw,ih,g1,img);
  g:=nil;
  GdipGetImageGraphicsContext(img,g);
  //GdipSetSmoothingMode(g,SmoothingModeAntiAlias);
  //GdipSetInterpolationMode(g,InterpolationModeHighQualityBicubic);
  GdipDrawImageRectI(g,CloneImg,0,0,integer(iw),integer(ih));
  GdipDeleteGraphics(g);
  GdipDisposeImage(CloneImg);
  GdipDeleteGraphics(g1);


  LocalFree(hMem);
  if Pointer(Stream)<>nil then begin
    Stream._Release;
    Pointer(Stream):=nil;
    //Stream:=nil;
  end;
end;  }

procedure CreateImageFromRes(out img:Pointer; Memory:Pointer; Size: Integer);
var
  hBuffer: DWORD;
  pBuffer: Pointer;
  pStream: IStream;
  iw,ih:UINT;
  g,g1:Pointer;
  CloneImg:Pointer;
  ns:integer;
begin
  if img<>nil then begin
    GdipDisposeImage(img);
    img:=nil;
  end;
  //для этого варианта нужно подключить модуль ActiveX
////  if SHCreateStreamOnFileEx(StringToPWideChar(fn,ns),
////        $40,      //STGM_DELETEONRELEASE =$4000000 //STGM_SHARE_DENY_NONE = $40; STGM_SHARE_EXCLUSIVE=$10 STGM_READWRITE=$2
////        FILE_SHARE_DELETE,{FILE_ATTRIBUTE_NORMAL {or FILE_ATTRIBUTE_TEMPORARY or FILE_SHARE_READ or FILE_SHARE_DELETE}
////        False ,nil, stm)=0 then begin
//  SHCreateStreamOnFile(fn,$10,stm);      //STGM_DELETEONRELEASE =$4000000 //STGM_SHARE_DENY_NONE = $40; STGM_SHARE_EXCLUSIVE=$10 STGM_READWRITE=$2
//  if stm<>nil then begin
//    GdipLoadImageFromStream(stm, img);
//    stm._Release;
//    Pointer(stm):=nil;
//    //stm:=nil;
//  end;


  CloneImg:=nil;

  hBuffer := GlobalAlloc(GMEM_MOVEABLE, Size);
  pBuffer := GlobalLock(hBuffer);

  CopyMemory(pBuffer, Memory, Size);
  pStream := nil;

  if CreateStreamOnHGlobal(hBuffer, FALSE, pStream) = S_OK then
    GdipLoadImageFromStream(pStream, CloneImg);

  GlobalUnlock(hBuffer);
  GlobalFree(hBuffer);

  GdipGetImageWidth(CloneImg,iw);
  GdipGetImageHeight(CloneImg,ih);
  g1:=nil;
  GdipGetImageGraphicsContext(CloneImg,g1);
  img:=nil;
  GdipCreateBitmapFromGraphics(iw,ih,g1,img);
  g:=nil;
  GdipGetImageGraphicsContext(img,g);
  GdipDrawImageRectI(g,CloneImg,0,0,integer(iw),integer(ih));
  GdipDeleteGraphics(g);
  GdipDisposeImage(CloneImg);
  GdipDeleteGraphics(g1);
end;

procedure CreateImage(out img:Pointer; fn:PChar);
var
//  stm:IStream;
  iw,ih:UINT;
  g,g1:Pointer;
  CloneImg:Pointer;
  ns:integer;
begin
  if img<>nil then begin
    GdipDisposeImage(img);
    img:=nil;
  end;
  //для этого варианта нужно подключить модуль ActiveX
////  if SHCreateStreamOnFileEx(StringToPWideChar(fn,ns),
////        $40,      //STGM_DELETEONRELEASE =$4000000 //STGM_SHARE_DENY_NONE = $40; STGM_SHARE_EXCLUSIVE=$10 STGM_READWRITE=$2
////        FILE_SHARE_DELETE,{FILE_ATTRIBUTE_NORMAL {or FILE_ATTRIBUTE_TEMPORARY or FILE_SHARE_READ or FILE_SHARE_DELETE}
////        False ,nil, stm)=0 then begin
//  SHCreateStreamOnFile(fn,$10,stm);      //STGM_DELETEONRELEASE =$4000000 //STGM_SHARE_DENY_NONE = $40; STGM_SHARE_EXCLUSIVE=$10 STGM_READWRITE=$2
//  if stm<>nil then begin
//    GdipLoadImageFromStream(stm, img);
//    stm._Release;
//    Pointer(stm):=nil;
//    //stm:=nil;
//  end;


  CloneImg:=nil;
  GdipLoadImageFromFile(StringToPWideChar(fn,ns),CloneImg);
  GdipGetImageWidth(CloneImg,iw);
  GdipGetImageHeight(CloneImg,ih);
  g1:=nil;
  GdipGetImageGraphicsContext(CloneImg,g1);
  img:=nil;
  GdipCreateBitmapFromGraphics(iw,ih,g1,img);
  g:=nil;
  GdipGetImageGraphicsContext(img,g);
  GdipDrawImageRectI(g,CloneImg,0,0,integer(iw),integer(ih));
  GdipDeleteGraphics(g);
  GdipDisposeImage(CloneImg);
  GdipDeleteGraphics(g1);
end;

function AddImageFromRes(Ind:integer; Memory:Pointer; Size:Integer; l,t:integer;w,h:Cardinal; Stretch,IsBkg:boolean):PImg;
var
  cimg:Pimg;
  OrigWidth,OrigHeight:Cardinal;
begin
  Result:=nil;
  try
    New(cimg);
  except
    Exit;
  end;
  if Memory = nil then begin
    Dispose(cimg);
    Exit;
  end;
  ZeroMemory(cimg,SizeOf(TImg));
  CreateImageFromRes(cimg^.Image, Memory, Size);

  GdipGetImageWidth(cimg^.Image,OrigWidth);
  GdipGetImageHeight(cimg^.Image,OrigHeight);
  SetRect(cimg^.VisibleRect,0,0,OrigWidth,OrigHeight);
  ConvertImageTo32bit(cimg^.Image,OrigWidth,OrigHeight);

  cimg^.Left:=l;
  cimg^.Top:=t;
  if Stretch then begin
    cimg^.Width:=w;
    cimg^.Height:=h;
  end else begin
    cimg^.Width:=OrigWidth;
    cimg^.Height:=OrigHeight;
  end;
  cimg^.IsBkg:=IsBkg;
  cimg^.Visible:=True;
  cimg^.Stretch:=Stretch;
  cimg^.Transparent:=255;

  cimg^.Delete:=False;
  cimg^.WndInd:=ind;
  cimg^.PNextImg:=nil;
  if AWnd[ind].PFirstImg=nil then begin
    cimg^.PPrevImg:=nil;
    AWnd[ind].PFirstImg:=cimg;
    AWnd[ind].PLastImg:=cimg;
  end else begin
    AWnd[ind].PLastImg^.PNextImg:=cimg;
    cimg^.PPrevImg:=AWnd[ind].PLastImg;
    AWnd[ind].PLastImg:=cimg;
  end;
  AWnd[Ind].RefreshBtn:=False;
  Result:=cimg;
end;

function AddImage(Ind:integer; FileName:PChar; l,t:integer;w,h:Cardinal; Stretch,IsBkg:boolean):PImg;
var
  cimg:Pimg;
  OrigWidth,OrigHeight:Cardinal;
begin
  Result:=nil;
  try
    New(cimg);
  except
    Exit;
  end;
  if not FileExists(FileName) then begin
    Dispose(cimg);
    Exit;
  end;
  ZeroMemory(cimg,SizeOf(TImg));
  CreateImage(cimg^.Image, FileName);

  GdipGetImageWidth(cimg^.Image,OrigWidth);
  GdipGetImageHeight(cimg^.Image,OrigHeight);
  SetRect(cimg^.VisibleRect,0,0,OrigWidth,OrigHeight);
  ConvertImageTo32bit(cimg^.Image,OrigWidth,OrigHeight);

  cimg^.Left:=l;
  cimg^.Top:=t;
  if Stretch then begin
    cimg^.Width:=w;
    cimg^.Height:=h;
  end else begin
    cimg^.Width:=OrigWidth;
    cimg^.Height:=OrigHeight;
  end;
  cimg^.IsBkg:=IsBkg;
  cimg^.Visible:=True;
  cimg^.Stretch:=Stretch;
  cimg^.Transparent:=255;

  cimg^.Delete:=False;
  cimg^.WndInd:=ind;
  cimg^.PNextImg:=nil;
  if AWnd[ind].PFirstImg=nil then begin
    cimg^.PPrevImg:=nil;
    AWnd[ind].PFirstImg:=cimg;
    AWnd[ind].PLastImg:=cimg;
  end else begin
    AWnd[ind].PLastImg^.PNextImg:=cimg;
    cimg^.PPrevImg:=AWnd[ind].PLastImg;
    AWnd[ind].PLastImg:=cimg;
  end;
  AWnd[Ind].RefreshBtn:=False;
  Result:=cimg;
end;

function AddWnd(h:HWND):integer;
var
  i:integer;
//  c:DWORD;
  rect:TRect;
  DC:HDC;
  BkgColor:DWORD;
  pGraphics:Pointer;
begin
  i:=Length(AWnd);
  Result:=i;
  SetLength(AWnd,i+1);
  AWnd[i].Wnd:=h;

//  c:=ColorToRGB(BkColor);
//  c:=MakeColor(255,GetRValue(c),GetGValue(c),GetBValue(c));
//  AWnd[i].BkColor:=c;

  AWnd[i].FImg:=nil;
  AWnd[i].BImg:=nil;

  AWnd[i].hDCMem:=CreateCompatibleDC(0);
  GetClientRect(h,rect);

  DC:=GetDC(h);
  AWnd[i].hBmp:=CreateCompatibleBitmap(DC,rect.right - rect.left,rect.bottom - rect.top);
  ReleaseDC(h,DC);

  AWnd[i].hOld:=SelectObject(AWnd[i].hDCMem,AWnd[i].hBmp);

  AWnd[i].PFirstImg:=nil;
  AWnd[i].PLastImg:=nil;
  SetRectEmpty(AWnd[i].UpdateBkgRect);
  SetRectEmpty(AWnd[i].UpdateRect);

  AWnd[i].OldProc:=SetWindowLong(h,GWL_WNDPROC,LongInt(@WndProc));

  CreateEmptyImage(AWnd[i].BImg,i);
  BkgColor:=$FF000000 or GetFormColor(i);
  GdipGetImageGraphicsContext(AWnd[i].BImg,pGraphics);
  GdipGraphicsClear(pGraphics,BkgColor);
  GdipDeleteGraphics(pGraphics);

end;

function GetWndInd(h:HWND):integer;
var
  i:integer;
begin
  Result:=-1;
  for i:=Low(AWnd) to High(AWnd) do begin
    if AWnd[i].Wnd=h then begin
      Result:=i;
      Break;
    end;
  end;
end;

{function ColorToRGB(Color:integer):Longint;
begin
  if Color<0 then Result:=GetSysColor(Color and $000000FF) else Result:=Color;
end;

function MakeColor(a,r,g,b:Byte):DWORD;
const
  AlphaShift = 24;
  RedShift   = 16;
  GreenShift = 8;
  BlueShift  = 0;
begin
  Result:=((DWORD(b) shl  BlueShift) or (DWORD(g) shl GreenShift) or (DWORD(r) shl   RedShift) or (DWORD(a) shl AlphaShift));
end;}

function FileExists(const FileName:string):boolean;
var
  Code:integer;
begin
  Code:=GetFileAttributes(PChar(FileName));
  Result:=(Code<>-1) and (FILE_ATTRIBUTE_DIRECTORY and Code=0);
end;

end.
