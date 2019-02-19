unit main;

interface

uses
  Windows, Messages;
                                                                                  
function ImgLoadFromRes(Wnd:HWND; Memory:Pointer; Size: Integer; Left,Top:integer;Width,Height:Cardinal; Stretch,IsBkg:boolean):Longint; stdcall;
function ImgLoad(Wnd:HWND; FileName:PChar; Left,Top:integer;Width,Height:Cardinal; Stretch,IsBkg:boolean):Longint; stdcall;
procedure ImgSetPosition(img:Longint; NewLeft, NewTop, NewWidth, NewHeight:integer); stdcall;
procedure ImgGetPosition(img:Longint; var Left, Top, Width, Height:integer); stdcall;
procedure ImgSetVisiblePart(img:Longint; NewLeft, NewTop, NewWidth, NewHeight : integer); stdcall;
procedure ImgGetVisiblePart(img:Longint; var Left, Top, Width, Height : integer); stdcall;
procedure ImgSetTransparent(img:Longint; Value:integer); stdcall;
function ImgGetTransparent(img:Longint):integer; stdcall;
procedure ImgRelease(img:Longint); stdcall;
procedure ImgSetVisibility(img:Longint; Visible:boolean); stdcall;
function ImgGetVisibility(img:Longint):boolean; stdcall;
procedure ImgApplyChanges(h:HWND); stdcall;
procedure CreateFormFromImage(h:HWND; FileName:PChar); stdcall;
procedure SetMinimizeAnimation(Value: Boolean); stdcall;
function GetMinimizeAnimation: Boolean; stdcall;

function WndProc(Wnd : HWND; Msg : UINT; wParam : Integer; lParam: Integer):Longint; stdcall;
procedure DestroyImages;

implementation

uses
  for_png, addfunc;

procedure SetMinimizeAnimation(Value: Boolean); stdcall;
var
  Info: TAnimationInfo;
begin
  Info.cbSize := SizeOf(Info);
  Info.iMinAnimate := integer(Value);
  SystemParametersInfo(SPI_SETANIMATION, SizeOf(Info), @Info, 0);
end;

function GetMinimizeAnimation: Boolean; stdcall;
var
  Info: TAnimationInfo;
begin
  Info.cbSize := SizeOf(TAnimationInfo);
  if SystemParametersInfo(SPI_GETANIMATION, SizeOf(Info), @Info, 0) then
    Result := Info.iMinAnimate <> 0 else
    Result := False;
end;

procedure ImgApplyChanges(h:HWND); stdcall;
var
  k:integer;
  r:TRect;
begin
  k:=GetWndInd(h);
  if k=-1 then Exit;

  if IsRectEmpty(AWnd[k].UpdateBkgRect) and IsRectEmpty(AWnd[k].UpdateRect) then Exit;

  UnionRect(r,AWnd[k].UpdateBkgRect,AWnd[k].UpdateRect);

  if not IsRectEmpty(AWnd[k].UpdateRect) then begin
    SetFullImage(k,False,@AWnd[k].UpdateRect);
    SetRectEmpty(AWnd[k].UpdateRect);
  end;
  if not IsRectEmpty(AWnd[k].UpdateBkgRect) then begin
    SetFullImage(k,True,@AWnd[k].UpdateBkgRect);
    SetRectEmpty(AWnd[k].UpdateBkgRect);
  end;

//  DrawFormToDCMem(k,@r);
//  EnumChildWindows(h,@RefreshChildWnd,Longint(@r));

  AWnd[k].RefreshBtn:=True;
  InvalidateRect(h,@r,False);
  UpdateWindow(h);
end;

function WndProc(Wnd : HWND; Msg : UINT; wParam : Integer; lParam: Integer):Longint; stdcall;
var
  k:integer;
  r:TRect;
  DC:HDC;
  ps:TPaintStruct;
begin
  k:=GetWndInd(Wnd);
  if k=-1 then begin
    Result:=CallWindowProc(Pointer(GetWindowLong(Wnd,GWL_WNDPROC)),Wnd,Msg,wParam,lParam);
    Exit;
  end;
  case Msg of
    WM_ERASEBKGND: {if Longint(AWnd[k].hDCMem)=wParam then Result:=CallWindowProc(Pointer(AWnd[k].OldProc),Wnd,Msg,wParam,lParam) else} Result:=1;
    WM_PAINT: begin
      Result:=0;
      if (HDC(wParam)=0) then begin
        DC:=BeginPaint(Wnd,ps);
        //if not AWnd[k].RefreshBtn then DrawFormToDCMem(k,@ps.rcPaint) else AWnd[k].RefreshBtn:=False;
        DrawFormToDCMem(k,@ps.rcPaint);
        if AWnd[k].RefreshBtn then begin
          EnumChildWindows(Wnd,@RefreshChildWnd,Longint(@ps.rcPaint));
          AWnd[k].RefreshBtn:=False;
        end;
        BitBlt(DC,ps.rcPaint.Left,ps.rcPaint.Top,ps.rcPaint.Right-ps.rcPaint.Left,ps.rcPaint.Bottom-ps.rcPaint.Top,AWnd[k].hDCMem,ps.rcPaint.Left,ps.rcPaint.Top,SRCCOPY);
        EndPaint(Wnd,ps);
      end else begin
        GetClientRect(Wnd,r);
        BitBlt(HDC(wParam),0,0,r.Right,r.Bottom,AWnd[k].hDCMem,0,0,SRCCOPY);
      end;
    end;
    WM_DESTROY: begin
      while AWnd[k].PLastImg<>nil do DeleteImage(k,AWnd[k].PLastImg);
      DeleteWnd(k);
      Result:=CallWindowProc(Pointer(GetWindowLong(Wnd,GWL_WNDPROC)),Wnd,Msg,wParam,lParam);
    end;
    else Result:=CallWindowProc(Pointer(AWnd[k].OldProc),Wnd,Msg,wParam,lParam);
  end;
end;

function ImgGetVisibility(img:Longint):boolean; stdcall;
var
  cimg:PImg;
begin
  Result:=False;
  cimg:=GetImg(img);
  if cimg=nil then Exit;
  Result:=cimg^.Visible;     
end;

procedure ImgSetVisibility(img:Longint; Visible:boolean); stdcall;
var
  wr,r:TRect;
  cimg:PImg;
begin
  cimg:=GetImg(img);
  if cimg=nil then Exit;

  if Visible<>cimg^.Visible then begin
    cimg^.Visible:=Visible;
    SetRect(r,cimg^.Left,cimg^.Top,cimg^.Left+integer(cimg^.Width),cimg^.Top+integer(cimg^.Height));
    GetClientRect(AWnd[cimg^.WndInd].Wnd,wr);
    if cimg^.IsBkg then begin
      UnionRect(AWnd[cimg^.WndInd].UpdateBkgRect,AWnd[cimg^.WndInd].UpdateBkgRect,r);
      IntersectRect(AWnd[cimg^.WndInd].UpdateBkgRect,wr,AWnd[cimg^.WndInd].UpdateBkgRect);
    end else begin
      UnionRect(AWnd[cimg^.WndInd].UpdateRect,AWnd[cimg^.WndInd].UpdateRect,r);
      IntersectRect(AWnd[cimg^.WndInd].UpdateRect,wr,AWnd[cimg^.WndInd].UpdateRect);
    end;
  end;
end;

procedure ImgRelease(img:Longint); stdcall;
var
  wndind:integer;
  h:HWND;
  wr,r:TRect;
  IsBkg:boolean;
  cimg:PImg;
begin
  cimg:=GetImg(img);
  if cimg=nil then Exit;

  wndind:=cimg^.WndInd;
  IsBkg:=cimg^.IsBkg;
  SetRect(r,cimg^.Left,cimg^.Top,cimg^.Left+integer(cimg^.Width),cimg^.Top+integer(cimg^.Height));
  DeleteImage(wndind,cimg);
  if AWnd[wndind].PFirstImg=nil then begin
    h:=AWnd[wndind].Wnd;
    DeleteWnd(wndind);
    EnumChildWindows(h,@RefreshChildWnd,Longint(@r));
    InvalidateRect(h,@r,True);
    UpdateWindow(h);
  end else begin
    GetClientRect(AWnd[wndind].Wnd,wr);
    if IsBkg then begin
      UnionRect(AWnd[wndind].UpdateBkgRect,AWnd[wndind].UpdateBkgRect,r);
      IntersectRect(AWnd[wndind].UpdateBkgRect,wr,AWnd[wndind].UpdateBkgRect);
    end else begin
      UnionRect(AWnd[wndind].UpdateRect,AWnd[wndind].UpdateRect,r);
      IntersectRect(AWnd[wndind].UpdateRect,wr,AWnd[wndind].UpdateRect);
    end;
  end;
end;

procedure ImgGetVisiblePart(img:Longint; var Left, Top, Width, Height : integer); stdcall;
var
  cimg:PImg;
begin
  cimg:=GetImg(img);
  if cimg=nil then Exit;

  Left:=cimg^.VisibleRect.Left;
  Top:=cimg^.VisibleRect.Top;
  Width:=cimg^.VisibleRect.Right;
  Height:=cimg^.VisibleRect.Bottom;
end;

procedure ImgSetVisiblePart(img:Longint; NewLeft, NewTop, NewWidth, NewHeight : integer); stdcall;
var
  cimg:PImg;
  wr,r:TRect;
begin
  cimg:=GetImg(img);
  if cimg=nil then Exit;

  SetRect(cimg^.VisibleRect,NewLeft,NewTop,NewWidth,NewHeight);

  SetRect(r,cimg^.Left,cimg^.Top,cimg^.Left+integer(cimg^.Width),cimg^.Top+integer(cimg^.Height));
  GetClientRect(AWnd[cimg^.WndInd].Wnd,wr);
  if cimg^.IsBkg then begin
    UnionRect(AWnd[cimg^.WndInd].UpdateBkgRect,AWnd[cimg^.WndInd].UpdateBkgRect,r);
    IntersectRect(AWnd[cimg^.WndInd].UpdateBkgRect,AWnd[cimg^.WndInd].UpdateBkgRect,wr);
  end else begin
    UnionRect(AWnd[cimg^.WndInd].UpdateRect,AWnd[cimg^.WndInd].UpdateRect,r);
    IntersectRect(AWnd[cimg^.WndInd].UpdateRect,AWnd[cimg^.WndInd].UpdateRect,wr);
  end;
end;

procedure ImgGetPosition(img:Longint; var Left, Top, Width, Height:integer); stdcall;
var
  cimg:PImg;
begin
  cimg:=GetImg(img);
  if cimg=nil then Exit;

  Left:=cimg^.Left;
  Top:=cimg^.Top;
  Width:=cimg^.Width;
  Height:=cimg^.Height;
end;

procedure ImgSetPosition(img:Longint; NewLeft, NewTop, NewWidth, NewHeight:integer); stdcall;
var
  wr,r,r2:TRect;
  cimg:PImg;
begin
  cimg:=GetImg(img);
  if cimg=nil then Exit;

  SetRect(r,cimg^.Left,cimg^.Top,cimg^.Left+integer(cimg^.Width),cimg^.Top+integer(cimg^.Height));
  cimg^.Left:=NewLeft;
  cimg^.Top:=NewTop;
  if cimg^.Stretch then begin
    cimg^.Width:=NewWidth;
    cimg^.Height:=NewHeight;
  end;
  SetRect(r2,cimg^.Left,cimg^.Top,cimg^.Left+integer(cimg^.Width),cimg^.Top+integer(cimg^.Height));

  GetClientRect(AWnd[cimg^.WndInd].Wnd,wr);
  if cimg^.IsBkg then begin
    UnionRect(AWnd[cimg^.WndInd].UpdateBkgRect,AWnd[cimg^.WndInd].UpdateBkgRect,r);
    UnionRect(AWnd[cimg^.WndInd].UpdateBkgRect,AWnd[cimg^.WndInd].UpdateBkgRect,r2);
    IntersectRect(AWnd[cimg^.WndInd].UpdateBkgRect,AWnd[cimg^.WndInd].UpdateBkgRect,wr);
  end else begin
    UnionRect(AWnd[cimg^.WndInd].UpdateRect,AWnd[cimg^.WndInd].UpdateRect,r);
    UnionRect(AWnd[cimg^.WndInd].UpdateRect,AWnd[cimg^.WndInd].UpdateRect,r2);
    IntersectRect(AWnd[cimg^.WndInd].UpdateRect,AWnd[cimg^.WndInd].UpdateRect,wr);
  end;
end;

procedure ImgSetTransparent(img:Longint; Value:integer); stdcall;
var
  cimg:PImg;
  wr,r:TRect;
begin
  cimg:=GetImg(img);
  if cimg=nil then Exit;

  if Value<0 then Value:=0;
  if Value>255 then Value:=255;
  if cimg^.Transparent<>Value then begin
    cimg^.Transparent:=Value;
    SetRect(r,cimg^.Left,cimg^.Top,cimg^.Left+integer(cimg^.Width),cimg^.Top+integer(cimg^.Height));
    GetClientRect(AWnd[cimg^.WndInd].Wnd,wr);
    if cimg^.IsBkg then begin
      UnionRect(AWnd[cimg^.WndInd].UpdateBkgRect,AWnd[cimg^.WndInd].UpdateBkgRect,r);
      IntersectRect(AWnd[cimg^.WndInd].UpdateBkgRect,AWnd[cimg^.WndInd].UpdateBkgRect,wr);
    end else begin
      UnionRect(AWnd[cimg^.WndInd].UpdateRect,AWnd[cimg^.WndInd].UpdateRect,r);
      IntersectRect(AWnd[cimg^.WndInd].UpdateRect,AWnd[cimg^.WndInd].UpdateRect,wr);
    end;
  end;
end;

function ImgGetTransparent(img:Longint):integer; stdcall;
var
  cimg:PImg;
begin
  Result:=-1;
  cimg:=GetImg(img);
  if cimg=nil then Exit;
  Result:=cimg^.Transparent;
end; 

function ImgLoadFromRes(Wnd:HWND; Memory:Pointer; Size: Integer; Left,Top:integer;Width,Height:Cardinal; Stretch,IsBkg:boolean):Longint; stdcall;
var
  k:integer;
  r:TRect;
  cimg:PImg;
begin
  Result:=0;
  if not gdipStart then Exit;
  k:=GetWndInd(Wnd);
  if k=-1 then k:=AddWnd(Wnd);
  cimg:=AddImageFromRes(k,Memory,Size,Left,Top,Width,Height,Stretch,IsBkg);
  if cimg<>nil then begin
    Result:=Longint(cimg);
    SetRect(r,Left,Top,Left+integer(cimg^.Width),Top+integer(cimg^.Height));
    if IsBkg then UnionRect(AWnd[k].UpdateBkgRect,AWnd[k].UpdateBkgRect,r)
      else UnionRect(AWnd[k].UpdateRect,AWnd[k].UpdateRect,r);
  end;
end;

function ImgLoad(Wnd:HWND; FileName:PChar; Left,Top:integer;Width,Height:Cardinal; Stretch,IsBkg:boolean):Longint; stdcall;
var
  k:integer;
  r:TRect;
  cimg:PImg;
begin
  Result:=0;
  if not gdipStart then Exit;
  k:=GetWndInd(Wnd);
  if k=-1 then k:=AddWnd(Wnd);
  cimg:=AddImage(k,FileName,Left,Top,Width,Height,Stretch,IsBkg);
  if cimg<>nil then begin
    Result:=Longint(cimg);
    SetRect(r,Left,Top,Left+integer(cimg^.Width),Top+integer(cimg^.Height));
    if IsBkg then UnionRect(AWnd[k].UpdateBkgRect,AWnd[k].UpdateBkgRect,r)
      else UnionRect(AWnd[k].UpdateRect,AWnd[k].UpdateRect,r);
  end;
end;

procedure DestroyImages;
begin
  while Length(AWnd)>0 do begin
    while AWnd[High(AWnd)].PLastImg<>nil do DeleteImage(High(AWnd),AWnd[High(AWnd)].PLastImg);
    DeleteWnd(High(AWnd));
  end;
end;


procedure CreateFormFromImage(h:HWND; FileName:PChar); stdcall;
type
  TGPImage = packed record
    Height,
    Width          :Cardinal;
    Graphics,
    Image          :Pointer;
    mDC,
    DC             :HDC;
    tempBitmap     :BITMAPINFO;
    mainBitmap,
    oldBitmap      :HBITMAP;
  end;
  
var
  gpImg    : TGPImage;
  pvBits   : Pointer;
  winSize  : Size;
  srcPoint : TPoint;
  BF       : BLENDFUNCTION;
  ns       : integer;
  rt       : TREct;
  deskw,
  deskh,
  fLeft,
  fTop     : integer;
begin
  if not gdipStart then Exit;

  gpImg.Image:=nil;
  GdipLoadImageFromFile(StringToPWideChar(FileName,ns),gpImg.Image);
  GdipGetImageHeight(gpImg.Image,gpImg.Height);
  GdipGetImageWidth(gpImg.Image,gpImg.Width);

  SystemParametersInfo(SPI_GETWORKAREA,0,@rt,0);
  deskw:=rt.Right-rt.Left;
  deskh:=rt.Bottom-rt.Top;
  fLeft:=(deskw div 2)-(integer(gpImg.Width) div 2);
  fTop:=(deskh div 2)-(integer(gpImg.Height) div 2);

  MoveWindow(h,fLeft,fTop,gpImg.Width,gpImg.Height,False);
  SetWindowLong(h,GWL_EXSTYLE,GetWindowLong(h,GWL_EXSTYLE) or WS_EX_LAYERED);

  gpImg.DC:=GetDC(h);
  gpImg.mDC:=CreateCompatibleDC(gpImg.DC);
  ZeroMemory(@gpImg.tempBitmap, SizeOf(BITMAPINFO));
  with gpImg.tempBitmap.bmiHeader do begin
    biSize:=SizeOf(BITMAPINFOHEADER);
    biBitCount:=32;
    biWidth:=gpImg.Width;
    biHeight:=gpImg.Height;
    biPlanes:=1;
    biCompression:=BI_RGB;
    biSizeImage:=biWidth * biHeight * (biBitCount div 8);
  end;
  gpImg.mainBitmap:=CreateDIBSection(gpImg.mDC,gpImg.tempBitmap,DIB_RGB_COLORS,pvBits,0,0);
  gpImg.oldBitmap:=SelectObject(gpImg.mDC,gpImg.mainBitmap);
  GdipCreateFromHDC(gpImg.mDC,gpImg.Graphics);
  GdipDrawImageRectI(gpImg.Graphics,gpImg.Image,0,0,gpImg.Width,gpImg.Height);

  srcPoint.X:=0;
  srcPoint.Y:=0;
  winSize.cx:=gpImg.Width;
  winSize.cy:=gpImg.Height;
  with BF do begin
    AlphaFormat:=AC_SRC_ALPHA;
    BlendFlags:=0;
    BlendOp:=AC_SRC_OVER;
    SourceConstantAlpha:=255;
  end;
  UpdateLayeredWindow(h, gpImg.DC, nil, @winSize, gpImg.mDC, @srcPoint, 0, @BF, ULW_ALPHA);

  GdipDisposeImage(gpImg.Image);
  GdipDeleteGraphics(gpImg.Graphics);
  SelectObject(gpImg.mDC, gpImg.oldBitmap);
  DeleteObject(gpImg.mainBitmap);
  DeleteObject(gpImg.oldBitmap);
  DeleteDC(gpImg.mDC);
  ReleaseDC(h,gpImg.DC);
end;

end.
