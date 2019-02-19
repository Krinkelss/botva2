unit for_png;

interface

uses
  Windows, ActiveX;

type
  PixelFormat = Integer;
  TPixelFormat = PixelFormat;

const
  PixelFormatAlpha       = $00040000; // Has an alpha component
  PixelFormatIndexed     = $00010000; // Indexes into a palette
  PixelFormatGDI         = $00020000; // Is a GDI-supported format
  PixelFormatPAlpha      = $00080000; // Pre-multiplied alpha
  PixelFormatExtended    = $00100000; // Extended color 16 bits/channel
  PixelFormatCanonical   = $00200000;

  PixelFormatUndefined      = 0;
  PixelFormatDontCare       = 0;

  PixelFormat1bppIndexed    = (1  or ( 1 shl 8) or PixelFormatIndexed or PixelFormatGDI);
  PixelFormat4bppIndexed    = (2  or ( 4 shl 8) or PixelFormatIndexed or PixelFormatGDI);
  PixelFormat8bppIndexed    = (3  or ( 8 shl 8) or PixelFormatIndexed or PixelFormatGDI);
  PixelFormat16bppGrayScale = (4  or (16 shl 8) or PixelFormatExtended);
  PixelFormat16bppRGB555    = (5  or (16 shl 8) or PixelFormatGDI);
  PixelFormat16bppRGB565    = (6  or (16 shl 8) or PixelFormatGDI);
  PixelFormat16bppARGB1555  = (7  or (16 shl 8) or PixelFormatAlpha or PixelFormatGDI);
  PixelFormat24bppRGB       = (8  or (24 shl 8) or PixelFormatGDI);
  PixelFormat32bppRGB       = (9  or (32 shl 8) or PixelFormatGDI);
  PixelFormat32bppARGB      = (10 or (32 shl 8) or PixelFormatAlpha or PixelFormatGDI or PixelFormatCanonical);
  PixelFormat32bppPARGB     = (11 or (32 shl 8) or PixelFormatAlpha or PixelFormatPAlpha or PixelFormatGDI);
  PixelFormat48bppRGB       = (12 or (48 shl 8) or PixelFormatExtended);
  PixelFormat64bppARGB      = (13 or (64 shl 8) or PixelFormatAlpha  or PixelFormatCanonical or PixelFormatExtended);
  PixelFormat64bppPARGB     = (14 or (64 shl 8) or PixelFormatAlpha  or PixelFormatPAlpha or PixelFormatExtended);
  PixelFormatMax            = 15;

//  PixelFormat32bppARGB      = (10 or (32 shl 8) or PixelFormatAlpha or $00020000 or $00200000);


const
  //StretchMode = (
  smNone         = 0; //не растягивать
  smProportional = 1; //растягивать пропорционально
  smFull         = 2; //растянуть на весь экран

type
  TRectF = packed record
    Left,
    Top,
    Right, 
    Bottom : Single;
  end;

  Status = (
    Ok,
    GenericError,
    InvalidParameter,
    OutOfMemory,
    ObjectBusy,
    InsufficientBuffer,
    NotImplemented,
    Win32Error,
    WrongState,
    Aborted,
    FileNotFound,
    ValueOverflow,
    AccessDenied,
    UnknownImageFormat,
    FontFamilyNotFound,
    FontStyleNotFound,
    NotTrueTypeFont,
    UnsupportedGdiplusVersion,
    GdiplusNotInitialized,
    PropertyNotFound,
    PropertyNotSupported
  );
  TStatus = Status;

  NotificationHookProc = function(out token: ULONG): Status; stdcall;
  NotificationUnhookProc = procedure(token: ULONG); stdcall;

  GdiplusStartupInput = packed record
    GdiplusVersion : Longint;
    DebugEventCallback : Longint;
    SuppressBackgroundThread : Longint;
    SuppressExternalCodecs : Longint;
  end;
  TGdiplusStartupInput = GdiplusStartupInput;
  PGdiplusStartupInput = ^TGdiplusStartupInput;

  GdiplusStartupOutput = packed record
    NotificationHook  : NotificationHookProc;
    NotificationUnhook: NotificationUnhookProc;
  end;
  TGdiplusStartupOutput = GdiplusStartupOutput;
  PGdiplusStartupOutput = ^TGdiplusStartupOutput;

  GpGraphics = Pointer;
  GpImage = Pointer;
  GpStatus = TStatus;
  PROPID = ULONG;

const
//  AC_SRC_ALPHA   = $01;
//  AC_SRC_OVER    = $00;
//  DIB_RGB_COLORS = 0;
//  GWL_EXSTYLE    = -20;
//  HWND_TOPMOST   = HWND(-1);
//  SWP_NOMOVE     = 2;
//  SWP_NOSIZE     = 1;
//  ULW_ALPHA      = $00000002;
//  WS_EX_LAYERED  = $00080000;
//  WM_PAINT       = $000F;

  WINGDIPDLL     = 'gdiplus.dll';

//  FrameDimensionTime:TGUID = '{6aedbd6d-3fb5-418a-83a6-7f45229dc872}';
//  PropertyTagFrameDelay    = $5100;

type
{  GpSolidFill = Pointer;
  GpBrush = Pointer;

  ImageCodecInfo = packed record
    Clsid             : TGUID;
    FormatID          : TGUID;
    CodecName         : PWCHAR;
    DllName           : PWCHAR;
    FormatDescription : PWCHAR;
    FilenameExtension : PWCHAR;
    MimeType          : PWCHAR;
    Flags             : DWORD;
    Version           : DWORD;
    SigCount          : DWORD;
    SigSize           : DWORD;
    SigPattern        : PBYTE;
    SigMask           : PBYTE;
  end;
  TImageCodecInfo = ImageCodecInfo;
  PImageCodecInfo = ^TImageCodecInfo;

  EncoderParameter = packed record
    Guid           : TGUID;   // GUID of the parameter
    NumberOfValues : ULONG;   // Number of the parameter values
    Type_          : ULONG;   // Value type, like ValueTypeLONG  etc.
    Value          : Pointer; // A pointer to the parameter values
  end;
  TEncoderParameter = EncoderParameter;
  PEncoderParameter = ^TEncoderParameter;

  EncoderParameters = packed record
    Count     : UINT;               // Number of parameters in this structure
    Parameter : array[0..0] of TEncoderParameter;  // Parameter values
  end;
  TEncoderParameters = EncoderParameters;
  PEncoderParameters = ^TEncoderParameters;
  
  PixelFormat = Integer;
  TPixelFormat = PixelFormat;

//  TGUIDDynArray = array of TGUID;
{  PropertyItem = record // NOT PACKED !!
    id       : PROPID;  // ID of this property
    length   : ULONG;   // Length of the property value, in bytes
    type_    : WORD;    // Type of the value, as one of TAG_TYPE_XXX
    value    : Pointer; // property value
  end;
  TPropertyItem = PropertyItem;
  PPropertyItem = ^TPropertyItem;
}
  ARGB   = DWORD;

{  TGPImage = packed record
    ImageIsGIF     :boolean;
    hThread        :Cardinal;
    ThreadID       :LongWord;
    Height,
    Width          :Cardinal;
    FrameCount,
    FrameCur,
    MinFrameDelay,
    FrameDelay     :integer;
    Graphics,
    Image          :Pointer;
    GUID           :TGUID;
    DC             :HDC;
    tempBitmap     :BITMAPINFO;
    mainBitmap,
    oldBitmap      :HBITMAP;
    hWnd           :HWND;
    PIFrameDelay   :PPropertyItem;
    DimensionIDs   :PGUID;
  end;

  Tmas = array of Longword;
}
  //**** slideshow ****
  GpBitmap = Pointer;
//  GpSolidFill = Pointer;
//  GpBrush = Pointer;
  GpImageAttributes = Pointer;
//  {$EXTERNALSYM ImageAbort}
  ImageAbort = function: BOOL; stdcall;
//  {$EXTERNALSYM DrawImageAbort}
  DrawImageAbort = ImageAbort;

  TUnit = (
    UnitWorld,      // 0 -- World coordinate (non-physical unit)
    UnitDisplay,    // 1 -- Variable -- for PageTransform only
    UnitPixel,      // 2 -- Each unit is one device pixel.
    UnitPoint,      // 3 -- Each unit is a printer's point, or 1/72 inch.
    UnitInch,       // 4 -- Each unit is 1 inch.
    UnitDocument,   // 5 -- Each unit is 1/300 inch.
    UnitMillimeter  // 6 -- Each unit is 1 millimeter.
  );
  GpUnit = TUnit;

  PColorMatrix = ^TColorMatrix;
  TColorMatrix = packed array[0..4, 0..4] of Single;// = ((1,0,0,0,0),(0,1,0,0,0),(0,0,1,0,0),(0,0,0,1,0),(0,0,0,0,1));

  ColorAdjustType = (
    ColorAdjustTypeDefault,
    ColorAdjustTypeBitmap,
    ColorAdjustTypeBrush,
    ColorAdjustTypePen,
    ColorAdjustTypeText,
    ColorAdjustTypeCount,
    ColorAdjustTypeAny      // Reserved
  );

  ColorMatrixFlags = (
    ColorMatrixFlagsDefault,
    ColorMatrixFlagsSkipGrays,
    ColorMatrixFlagsAltGray
  );   

  QualityMode = (
    QualityModeInvalid   = -1,
    QualityModeDefault   =  0,
    QualityModeLow       =  1, // Best performance
    QualityModeHigh      =  2  // Best rendering quality
  );

  SmoothingMode = (
    SmoothingModeInvalid     = ord(QualityModeInvalid),
    SmoothingModeDefault     = ord(QualityModeDefault),
    SmoothingModeHighSpeed   = ord(QualityModeLow),
    SmoothingModeHighQuality = ord(QualityModeHigh),
    SmoothingModeNone,
    SmoothingModeAntiAlias
  );

  InterpolationMode = (
    InterpolationModeInvalid          = ord(QualityModeInvalid),
    InterpolationModeDefault          = ord(QualityModeDefault),
    InterpolationModeLowQuality       = ord(QualityModeLow),
    InterpolationModeHighQuality      = ord(QualityModeHigh),
    InterpolationModeBilinear,
    InterpolationModeBicubic,
    InterpolationModeNearestNeighbor,
    InterpolationModeHighQualityBilinear,
    InterpolationModeHighQualityBicubic
  );

  CombineMode = (
    CombineModeReplace,     // 0
    CombineModeIntersect,   // 1
    CombineModeUnion,       // 2
    CombineModeXor,         // 3
    CombineModeExclude,     // 4
    CombineModeComplement   // 5 (Exclude From)
  );
//  TCombineMode = CombineMode;

var
  GDIPSI :GdiplusStartupInput;
  Token  :DWORD=0;

//function GdipImageGetFrameCount(image: GPIMAGE; dimensionID: PGUID;  var count: UINT): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipImageGetFrameCount';
//function GdipImageSelectActiveFrame(image: GPIMAGE; dimensionID: PGUID; frameIndex: UINT): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipImageSelectActiveFrame';
//function GdipImageGetFrameDimensionsCount(image: GPIMAGE; var count: UINT): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipImageGetFrameDimensionsCount';
//function GdipImageGetFrameDimensionsList(image: GPIMAGE; dimensionIDs: PGUID; Count: UINT): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipImageGetFrameDimensionsList';
//function GdipGetPropertyItemSize(image: GPIMAGE; propId: PROPID; var size: UINT): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipGetPropertyItemSize';
//function GdipGetPropertyItem(image: GPIMAGE; propId: PROPID; propSize: UINT; buffer: PPROPERTYITEM): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipGetPropertyItem';
//function GdipDrawImageRect(graphics: GPGRAPHICS; image: GPIMAGE; x: Single; y: Single; width: Single; height: Single): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipDrawImageRect';
//function GdipLoadImageFromFile(filename: PWCHAR; out image: GPIMAGE): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipLoadImageFromFile';
//function GdipGetImageWidth(image: GPIMAGE; var width: UINT): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipGetImageWidth';
//function GdipGetImageHeight(image: GPIMAGE; var height: UINT): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipGetImageHeight';
//function GdipDisposeImage(image: GPIMAGE): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipDisposeImage';
//function GdiplusStartup(out token: ULONG; input: PGdiplusStartupInput; output: PGdiplusStartupOutput): Status; stdcall; external WINGDIPDLL name 'GdiplusStartup';
//function GdipCreateFromHDC(hdc: HDC; out graphics: GPGRAPHICS): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipCreateFromHDC';
//function GdipDeleteGraphics(graphics: GPGRAPHICS): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipDeleteGraphics';
//procedure GdiplusShutdown(Token: DWord); stdcall; external 'GdiPlus.dll';
//function DrawGIF(Param:Pointer):integer;
//procedure DeInitGIF;
//procedure InitGIF;
//function AllocMem(Size: Integer): Pointer;
//function PWideCharToString(pw : PWideChar): String;
function StringToPWideChar(sStr: string; var iNewSize: integer): PWideChar;

//procedure GdiPImageResize(out Img:Pointer; NewWidth, NewHeight:integer; {BkgColor:DWORD;} StretchMode: integer);
//function GdipGetImageGraphicsContext(image: GPIMAGE; out graphics: GPGRAPHICS): GPSTATUS; stdcall;external WINGDIPDLL name 'GdipGetImageGraphicsContext';
//function GdipSetSmoothingMode(graphics: GPGRAPHICS; smoothingMode: SMOOTHINGMODE): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipSetSmoothingMode';
//function GdipSetInterpolationMode(graphics: GPGRAPHICS; interpolationMode: INTERPOLATIONMODE): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipSetInterpolationMode';
//function GdipCreateBitmapFromGraphics(width: Integer; height: Integer; target: GPGRAPHICS; out bitmap: GPBITMAP): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipCreateBitmapFromGraphics';
//function GdipCreateSolidFill(color: ARGB; out brush: GPSOLIDFILL): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipCreateSolidFill';
//function GdipFillRectangleI(graphics: GPGRAPHICS; brush: GPBRUSH; x: Integer; y: Integer; width: Integer; height: Integer): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipFillRectangleI';
//function GdipCreateImageAttributes(out imageattr: GPIMAGEATTRIBUTES): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipCreateImageAttributes';
//function GdipSetImageAttributesColorMatrix(imageattr: GPIMAGEATTRIBUTES; type_: COLORADJUSTTYPE; enableFlag: Bool; colorMatrix: PCOLORMATRIX; grayMatrix: PCOLORMATRIX; flags: COLORMATRIXFLAGS): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipSetImageAttributesColorMatrix';
//function GdipDrawImageRectRectI(graphics: GPGRAPHICS; image: GPIMAGE; dstx: Integer; dsty: Integer; dstwidth: Integer; dstheight: Integer; srcx: Integer; srcy: Integer; srcwidth: Integer; srcheight: Integer; srcUnit: GPUNIT; imageAttributes: GPIMAGEATTRIBUTES; callback: DRAWIMAGEABORT; callbackData: Pointer): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipDrawImageRectRectI';
//function GdipDisposeImageAttributes(imageattr: GPIMAGEATTRIBUTES): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipDisposeImageAttributes';
//function GdipDeleteBrush(brush: GPBRUSH): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipDeleteBrush';


//function GdipBitmapGetPixel(bitmap: GPBITMAP; x: Integer; y: Integer;
//    var color: ARGB): GPSTATUS; stdcall;  external WINGDIPDLL name 'GdipBitmapGetPixel';

//function GdipCreateFromHWND(hwnd: HWND; out graphics: GPGRAPHICS): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipCreateFromHWND';
//function GdipGraphicsClear(graphics: GPGRAPHICS; color: ARGB): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipGraphicsClear';

//function GetEncoderClsid(format: String; out pClsid: TGUID): integer;
//function GdipGetImageEncodersSize(out numEncoders: UINT; out size: UINT): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipGetImageEncodersSize';
//function GdipGetImageEncoders(numEncoders: UINT; size: UINT; encoders: PIMAGECODECINFO): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipGetImageEncoders';
//function GdipSaveImageToFile(image: GPIMAGE; filename: PWCHAR; clsidEncoder: PGUID; encoderParams: PENCODERPARAMETERS): GPSTATUS; stdcall; external WINGDIPDLL name 'GdipSaveImageToFile';
//function GdipCreateBitmapFromScan0(width: Integer; height: Integer; stride: Integer; format: PIXELFORMAT; scan0: PBYTE; out bitmap: GPBITMAP): GPSTATUS; stdcall;external WINGDIPDLL name 'GdipCreateBitmapFromScan0';
//function GdipCreateBitmapFromHBITMAP(hbm: HBITMAP; hpal: HPALETTE; out bitmap: GPBITMAP): GPSTATUS; stdcall;   external WINGDIPDLL name 'GdipCreateBitmapFromHBITMAP';

function gdipStart:boolean;
procedure gdipShutdown; stdcall;
procedure ConvertImageTo32bit(out img:Pointer; Width, Height: Cardinal);

procedure SetRectF(var Rect:TRectF; Left, Top, Right, Bottom : Single);
function IsRectFEmpty(Rect:TRectF):boolean;

//procedure WriteLog(s:string);

type
  TGdiplusStartup                    = function (out token: ULONG; input: PGdiplusStartupInput; output: PGdiplusStartupOutput): Status; stdcall;
  TGdiplusShutdown                   = procedure (Token: DWord); stdcall;
  TGdipLoadImageFromStream           = function (stream: IStream; out image: GPIMAGE): GPSTATUS; stdcall;
  TGdipLoadImageFromFile             = function (filename: PWCHAR; out image: GPIMAGE): GPSTATUS; stdcall;
  TGdipDrawImageRectI                = function (graphics: GPGRAPHICS; image: GPIMAGE; x: integer; y: integer; width: integer; height: integer): GPSTATUS; stdcall;
  TGdipGetImageWidth                 = function (image: GPIMAGE; var width: UINT): GPSTATUS; stdcall;
  TGdipGetImageHeight                = function (image: GPIMAGE; var height: UINT): GPSTATUS; stdcall;
  TGdipDisposeImage                  = function (image: GPIMAGE): GPSTATUS; stdcall;
  TGdipCreateFromHDC                 = function (hdc: HDC; out graphics: GPGRAPHICS): GPSTATUS; stdcall;
  TGdipDeleteGraphics                = function (graphics: GPGRAPHICS): GPSTATUS; stdcall;
  TGdipGetImageGraphicsContext       = function (image: GPIMAGE; out graphics: GPGRAPHICS): GPSTATUS; stdcall;
  TGdipSetSmoothingMode              = function (graphics: GPGRAPHICS; smoothingMode: SMOOTHINGMODE): GPSTATUS; stdcall;
  TGdipSetInterpolationMode          = function (graphics: GPGRAPHICS; interpolationMode: INTERPOLATIONMODE): GPSTATUS; stdcall;
  TGdipCreateBitmapFromGraphics      = function (width: Integer; height: Integer; target: GPGRAPHICS; out bitmap: GPBITMAP): GPSTATUS; stdcall;
  TGdipDrawImageRectRectI            = function (graphics: GPGRAPHICS; image: GPIMAGE; dstx: Integer; dsty: Integer; dstwidth: Integer; dstheight: Integer; srcx: Integer; srcy: Integer; srcwidth: Integer; srcheight: Integer; srcUnit: GPUNIT; imageAttributes: GPIMAGEATTRIBUTES; callback: DRAWIMAGEABORT; callbackData: Pointer): GPSTATUS; stdcall;
  TGdipCreateFromHWND                = function (hwnd: HWND; out graphics: GPGRAPHICS): GPSTATUS; stdcall;
  TGdipGraphicsClear                 = function (graphics: GPGRAPHICS; color: ARGB): GPSTATUS; stdcall;
  TGdipCreateBitmapFromHBITMAP       = function (hbm: HBITMAP; hpal: HPALETTE; out bitmap: GPBITMAP): GPSTATUS; stdcall;

  TGdipCreateImageAttributes         = function (out imageattr: GPIMAGEATTRIBUTES): GPSTATUS; stdcall;
  TGdipSetImageAttributesColorMatrix = function (imageattr: GPIMAGEATTRIBUTES; type_: COLORADJUSTTYPE; enableFlag: Bool; colorMatrix: PCOLORMATRIX; grayMatrix: PCOLORMATRIX; flags: COLORMATRIXFLAGS): GPSTATUS; stdcall;
  TGdipDisposeImageAttributes        = function (imageattr: GPIMAGEATTRIBUTES): GPSTATUS; stdcall;

  TGdipSetClipRectI                  = function (graphics: GPGRAPHICS; x: Integer; y: Integer; width: Integer; height: Integer; combineMode: COMBINEMODE): GPSTATUS; stdcall;
  TGdipResetClip                     = function (graphics: GPGRAPHICS): GPSTATUS; stdcall;
  TGdipCloneBitmapAreaI              = function (x: Integer; y: Integer; width: Integer; height: Integer; format: PIXELFORMAT; srcBitmap: GPBITMAP; out dstBitmap: GPBITMAP): GPSTATUS; stdcall;
  TGdipGetImagePixelFormat           = function (image: GPIMAGE; out format: TPIXELFORMAT): GPSTATUS; stdcall;

  TGdipDrawImageRectRect             = function (graphics: GPGRAPHICS; image: GPIMAGE; dstx: Single; dsty: Single; dstwidth: Single; dstheight: Single; srcx: Single; srcy: Single; srcwidth: Single; srcheight: Single; srcUnit: GPUNIT; imageAttributes: GPIMAGEATTRIBUTES; callback: DRAWIMAGEABORT; callbackData: Pointer): GPSTATUS; stdcall;
  TGdipCreateBitmapFromScan0         = function (width: Integer; height: Integer; stride: Integer; format: PIXELFORMAT; scan0: PBYTE; out bitmap: GPBITMAP): GPSTATUS; stdcall; 

var
  hGDIPlus                          : LongWord;
  GdiplusStartup                    : TGdiplusStartup;
  GdiplusShutdown                   : TGdiplusShutdown;     
  GdipLoadImageFromStream           : TGdipLoadImageFromStream;
  GdipLoadImageFromFile             : TGdipLoadImageFromFile;
  GdipDrawImageRectI                : TGdipDrawImageRectI;
  GdipGetImageWidth                 : TGdipGetImageWidth;
  GdipGetImageHeight                : TGdipGetImageHeight;
  GdipDisposeImage                  : TGdipDisposeImage;
  GdipCreateFromHDC                 : TGdipCreateFromHDC;
  GdipDeleteGraphics                : TGdipDeleteGraphics;
  GdipGetImageGraphicsContext       : TGdipGetImageGraphicsContext;
  GdipSetSmoothingMode              : TGdipSetSmoothingMode;
  GdipSetInterpolationMode          : TGdipSetInterpolationMode;
  GdipCreateBitmapFromGraphics      : TGdipCreateBitmapFromGraphics;
  GdipCreateFromHWND                : TGdipCreateFromHWND;
  GdipGraphicsClear                 : TGdipGraphicsClear;
  GdipCreateBitmapFromHBITMAP       : TGdipCreateBitmapFromHBITMAP;
  GdipDrawImageRectRectI            : TGdipDrawImageRectRectI;
  GdipCreateImageAttributes         : TGdipCreateImageAttributes;
  GdipSetImageAttributesColorMatrix : TGdipSetImageAttributesColorMatrix;
  GdipDisposeImageAttributes        : TGdipDisposeImageAttributes;
  GdipSetClipRectI                  : TGdipSetClipRectI;
  GdipResetClip                     : TGdipResetClip;
  GdipCloneBitmapAreaI              : TGdipCloneBitmapAreaI;
  GdipGetImagePixelFormat           : TGdipGetImagePixelFormat;
  GdipDrawImageRectRect             : TGdipDrawImageRectRect;
  GdipCreateBitmapFromScan0         : TGdipCreateBitmapFromScan0;

implementation

uses
  main, gdipButton, gdipCheckBox;

procedure SetRectF(var Rect:TRectF;Left,Top,Right,Bottom:Single);
begin
  Rect.Left:=Left;
  Rect.Top:=Top;
  Rect.Right:=Right;
  Rect.Bottom:=Bottom;
end;

function IsRectFEmpty(Rect:TRectF):boolean;
begin
  Result:=((Rect.Right-Rect.Left)=0) or ((Rect.Bottom-Rect.Top)=0)
end;

{function IsAlphaPixelFormat(pixfmt: PixelFormat): BOOL;
begin
  result := (pixfmt and PixelFormatAlpha) <> 0;
end;}

procedure ConvertImageTo32bit(out img:Pointer; Width, Height: Cardinal);
var
  CloneImg:Pointer;
//  pf:TPixelFormat;
begin
  //32-битные изображения рисуются быстрее 24-битных
  //GdipGetImagePixelFormat(img,pf);
  //if not IsAlphaPixelFormat(pf) then begin
    GdipCloneBitmapAreaI(0,0,Width,Height,PixelFormat32bppPARGB,img,CloneImg);
    GdipDisposeImage(img);
    img:=CloneImg;
  //end;
  //тест скорость отрисовки 256-ти кадров
  //pargb - 4260-4290 мс
  //argb  - 4460-4480 мс
  //rgb   - 4680-4720 мс
  //имеем, что изображения в PixelFormat32bppPARGB выводятся быстрее всего
  //поэтому переводим в этот формат все изображения
  //правда оперативки под это отводится в 3-3.5 раза больше
end;

procedure gdipShutdown; stdcall;
begin
  CheckBoxDestroy;
  BtnDestroy;
  DestroyImages;
  if Token<>0 then begin
    GdiplusShutdown(Token);
    Token:=0;
  end;
end;

function ExtractFileName(const Path:string; WithoutLastSimbolsCount:integer=0):string;
var
  i:integer;
begin
  Result:='';
  i:=Length(Path);
  while (Path[i]<>'\') and (i>0) do dec(i);
  if i>0 then Result:=Copy(Path,i+1,Length(Path)-i-WithoutLastSimbolsCount);
end;

function GetModuleName:string;
var
  fName: string;
  nSize: Cardinal;
begin
  nSize:=255;
  SetLength(fName,nSize);
  SetLength(fName,GetModuleFileName(hInstance,PChar(fName),nSize));
  Result:=fName;
end;

function gdipStart:boolean;
begin
  Result:=False;
  if hGDIPlus=0 then Exit;
  if Token=0 then begin
    FillChar(GDIPSI,SizeOf(GDIPSI),0);
    GDIPSI.GdiplusVersion:=1;
    if GdiplusStartup(Token,@GDIPSI,nil)=Ok then Result:=True;
  end else Result:=True;
end;

function AllocMem(Size: Integer): Pointer;
asm     //cmd    //opd
  TEST     EAX, EAX
  JZ       @@exit
  PUSH     EAX
  CALL     System.@GetMem
  POP      EDX
  PUSH     EAX
  MOV      CL, 0
  CALL     System.@FillChar
  POP      EAX
@@exit:
end;

{function PWideCharToString(pw : PWideChar): String;
var
 p: PChar;
 iLen: integer;
begin
 iLen := lstrlenw(pw) + 1;
 GetMem(p, iLen);
 WideCharToMultiByte(CP_ACP, 0, pw, iLen, p, iLen*2, nil, nil);
 Result := p;
 FreeMem(p, iLen);
end;}

function StringToPWideChar(sStr: string; var iNewSize: integer): PWideChar;
var
 pw : PWideChar;
 iSize : integer;
begin
 iSize := Length(sStr) + 1;
 iNewSize := iSize*2;
 pw := AllocMem(iNewSize);
 MultiByteToWideChar(CP_ACP, 0, PChar(sStr), iSize, pw, iNewSize);
 Result := pw;
end;

{function GetImageEncodersSize(out numEncoders, size: UINT): TStatus;
begin
  result := GdipGetImageEncodersSize(numEncoders, size);
end;

function GetImageEncoders(numEncoders, size: UINT;  encoders: PImageCodecInfo): TStatus;
begin
  result := GdipGetImageEncoders(numEncoders, size, encoders);
end;

function GetEncoderClsid(format: String; out pClsid: TGUID): integer;
var
  num, size, j: UINT;
  ImageCodecInfo: PImageCodecInfo;
Type
  ArrIMgInf = array of TImageCodecInfo;
begin
  num  := 0; // number of image encoders
  size := 0; // size of the image encoder array in bytes
  result := -1;

  GetImageEncodersSize(num, size);
  if (size = 0) then exit;

  GetMem(ImageCodecInfo, size);
  if(ImageCodecInfo = nil) then exit;

  GetImageEncoders(num, size, ImageCodecInfo);

  for j := 0 to num - 1 do
  begin
    if( ArrIMgInf(ImageCodecInfo)[j].MimeType = format) then
    begin
      pClsid := ArrIMgInf(ImageCodecInfo)[j].Clsid;
      result := j;  // Success
    end;
  end;
  FreeMem(ImageCodecInfo, size);
end; }

{procedure GdiPImageResize(out Img:Pointer; NewWidth, NewHeight:integer; {BkgColor:DWORD; }{StretchMode: integer);
var
  g1,g2   :Pointer;
  w,h     :Cardinal;
  k,k1,k2 :Single;
  //Clsid   :TGUID;
  NewImg  :Pointer;
//  Brush:Pointer;
begin
  GdipGetImageWidth(Img,w);
  GdipGetImageHeight(Img,h);

  case StretchMode of
    //smNone: k:=1;
    smProportional: begin
      k1:=NewHeight/h;
      k2:=NewWidth/w;
      if (k1>k2) then k:=k2 else k:=k1;
      w:=Round(w*k);
      h:=Round(h*k);
    end;
    smFull: begin
      w:=NewWidth;
      h:=NewHeight;
    end;
  end;

  GdipGetImageGraphicsContext(Img,g1);
  GdipSetSmoothingMode(g1,SmoothingModeAntiAlias);
  GdipSetInterpolationMode(g1,InterpolationModeHighQualityBicubic);

  GdipCreateBitmapFromGraphics(NewWidth,NewHeight,g1,NewImg);
  GdipGetImageGraphicsContext(NewImg,g2);
  GdipSetSmoothingMode(g2,SmoothingModeAntiAlias);
  GdipSetInterpolationMode(g2,InterpolationModeHighQualityBicubic);

//  GdipCreateSolidFill(BkgColor,Brush);
//  GdipFillRectangleI(g2,Brush,0,0,NewWidth,NewHeight);

  GdipDrawImageRect(g2,Img,(NewWidth-w) div 2,(NewHeight-h) div 2,w,h);
  //GdipDrawImageRectRectI(g2,img,img2.lt.X,img2.lt.Y,img2.Size.cx,img2.Size.cy,0,0,img2.Size.cx,img2.Size.cy,UnitPixel,ImgAttr,nil,nil);
  //сохранить в файл
  //GetEncoderClsid('image/png', Clsid);
  //GdipSaveImageToFile(NewImg, 'd:\screennew.png', @ClsId, nil);
  GdipDisposeImage(Img);
  Img:=NewImg;
  GdipDeleteGraphics(g1);
  GdipDeleteGraphics(g2);
//  GdipDeleteBrush(Brush);
end; }

{procedure DeInitGIF;
begin
  FreeMem(GdPImage.PIFrameDelay);
  FreeMem(GdPImage.DimensionIDs);
end;

procedure InitGIF;
var
  DIDs:TGUID;
  Count:Cardinal;
begin
  Count:=0;
  GdipImageGetFrameDimensionsCount(GdPImage.Image,Count);
  GetMem(GdPImage.DimensionIDs,Count*SizeOf(TGUID));
  GdipImageGetFrameDimensionsList(GdPImage.Image, GdPImage.dimensionIDs, Count);

  Count:=0;
  DIDs:=TGUIDDynArray(GdPImage.DimensionIDs)[0];
  GdipImageGetFrameCount(GdPImage.Image,@DIDs,Count);
  GdPImage.FrameCount:=Count;

  Count:=0;
  GdipGetPropertyItemSize(GdPImage.Image, PropertyTagFrameDelay, Count);
  GetMem(GdPImage.PIFrameDelay,Count);
  GdipGetPropertyItem(GdPImage.Image, PropertyTagFrameDelay, Count, GdPImage.PIFrameDelay);
  SetLength(Tmas(GdPImage.PIFrameDelay^.value),GdPImage.FrameCount);
end;

procedure WriteLog(s:string);
const
  fn='e:\Programs\ForInno\Splash\3\Project1.log';
var
  f:TextFile;
begin
  AssignFile(f,fn);
  Append(f);
  Writeln(f, s);
  Flush(f);
  CloseFile(f);
end;         }

{function DrawGIF(Param:Pointer):integer;
var
  f:boolean;
  DIDs:TGUID;
  Count:Cardinal;
begin
  Result:=0;

  Count:=0;
  GdipImageGetFrameDimensionsCount(GdPImage.Image,Count);
  GetMem(Splash_GdPImage.DimensionIDs,Count*SizeOf(TGUID));
  GdipImageGetFrameDimensionsList(Splash_GdPImage.Image, Splash_GdPImage.dimensionIDs, Count);

  Count:=0;
  DIDs:=TGUIDDynArray(Splash_GdPImage.DimensionIDs)[0];
  GdipImageGetFrameCount(Splash_GdPImage.Image,@DIDs,Count);
  Splash_GdPImage.FrameCount:=Count;

  if Splash_GdPImage.FrameCount>1 then begin
    Count:=0;
    GdipGetPropertyItemSize(Splash_GdPImage.Image, PropertyTagFrameDelay, Count);
    GetMem(Splash_GdPImage.PIFrameDelay,Count);
    GdipGetPropertyItem(Splash_GdPImage.Image, PropertyTagFrameDelay, Count, Splash_GdPImage.PIFrameDelay);
    SetLength(Tmas(Splash_GdPImage.PIFrameDelay^.value),Splash_GdPImage.FrameCount);

    Splash_GdPImage.FrameCur:=0;
    EnterCriticalSection(Splash_CS);
    try
      f:=Splash_CanExecThread;
    finally
      LeaveCriticalSection(Splash_CS);
    end;
    while f do begin
  //    InvalidateRect(GdPImage.hWnd,nil,False);
      GdipImageSelectActiveFrame(Splash_GdPImage.Image,@FrameDimensionTime,Splash_GdPImage.FrameCur);
      GdipGraphicsClear(Splash_GdPImage.Graphics,RGB(128,128,128));
      GdipDrawImageRect(Splash_GdPImage.Graphics,Splash_GdPImage.Image,0,0,Splash_GdPImage.Width,Splash_GdPImage.Height);
      PostMessage(Splash_GdPImage.hWnd,WM_PAINT,0,0);
  //    InvalidateRect(GdPImage.hWnd,nil,False);
      Splash_GdPImage.FrameDelay:=Tmas(Splash_GdPImage.PIFrameDelay^.Value)[Splash_GdPImage.FrameCur]*10;
      if (Splash_GdPImage.FrameDelay<Splash_GdPImage.MinFrameDelay) then Splash_GdPImage.FrameDelay:=Splash_GdPImage.MinFrameDelay;
      if Splash_GdPImage.FrameDelay>0 then Sleep(Splash_GdPImage.FrameDelay);
      Splash_GdPImage.FrameCur:=Splash_GdPImage.FrameCur+1;
      if (Splash_GdPImage.FrameCur>(Splash_GdPImage.FrameCount-1)) then Splash_GdPImage.FrameCur:=0;
      EnterCriticalSection(Splash_CS);
      try
        f:=Splash_CanExecThread;
      finally
        LeaveCriticalSection(Splash_CS);
      end;
    end;
    FreeMem(Splash_GdPImage.PIFrameDelay);
  end;
  FreeMem(Splash_GdPImage.DimensionIDs);
  EndThread(0);
end;             }

procedure GDIPlusInit;
begin
  if CharUpper(PChar(ExtractFileName(GetModuleName,4)))<>'BOTVA2' then begin
    hGDIPlus:=0;
    Exit;
  end;

  hGDIPlus:=LoadLibrary(PChar('GDIPlus'));
  if hGDIPlus=0 then Exit;
  @GdiplusStartup                    := GetProcAddress(hGDIPlus,PChar('GdiplusStartup'));
  @GdiplusShutdown                   := GetProcAddress(hGDIPlus,PChar('GdiplusShutdown'));
  @GdipLoadImageFromFile             := GetProcAddress(hGDIPlus,PChar('GdipLoadImageFromFile'));
  @GdipDrawImageRectI                := GetProcAddress(hGDIPlus,PChar('GdipDrawImageRectI'));
  @GdipGetImageWidth                 := GetProcAddress(hGDIPlus,PChar('GdipGetImageWidth'));
  @GdipGetImageHeight                := GetProcAddress(hGDIPlus,PChar('GdipGetImageHeight'));
  @GdipDisposeImage                  := GetProcAddress(hGDIPlus,PChar('GdipDisposeImage'));
  @GdipCreateFromHDC                 := GetProcAddress(hGDIPlus,PChar('GdipCreateFromHDC'));
  @GdipDeleteGraphics                := GetProcAddress(hGDIPlus,PChar('GdipDeleteGraphics'));
  @GdipGetImageGraphicsContext       := GetProcAddress(hGDIPlus,PChar('GdipGetImageGraphicsContext'));
  @GdipSetSmoothingMode              := GetProcAddress(hGDIPlus,PChar('GdipSetSmoothingMode'));
  @GdipSetInterpolationMode          := GetProcAddress(hGDIPlus,PChar('GdipSetInterpolationMode'));
  @GdipCreateBitmapFromGraphics      := GetProcAddress(hGDIPlus,PChar('GdipCreateBitmapFromGraphics'));
  @GdipCreateFromHWND                := GetProcAddress(hGDIPlus,PChar('GdipCreateFromHWND'));
  @GdipGraphicsClear                 := GetProcAddress(hGDIPlus,PChar('GdipGraphicsClear'));
  @GdipCreateBitmapFromHBITMAP       := GetProcAddress(hGDIPlus,PChar('GdipCreateBitmapFromHBITMAP'));
  @GdipDrawImageRectRectI            := GetProcAddress(hGDIPlus,PChar('GdipDrawImageRectRectI'));
  @GdipCreateImageAttributes         := GetProcAddress(hGDIPlus,PChar('GdipCreateImageAttributes'));
  @GdipSetImageAttributesColorMatrix := GetProcAddress(hGDIPlus,PChar('GdipSetImageAttributesColorMatrix'));
  @GdipDisposeImageAttributes        := GetProcAddress(hGDIPlus,PChar('GdipDisposeImageAttributes'));
  @GdipSetClipRectI                  := GetProcAddress(hGDIPlus,PChar('GdipSetClipRectI'));
  @GdipResetClip                     := GetProcAddress(hGDIPlus,PChar('GdipResetClip'));
  @GdipCloneBitmapAreaI              := GetProcAddress(hGDIPlus,PChar('GdipCloneBitmapAreaI'));
  @GdipGetImagePixelFormat           := GetProcAddress(hGDIPlus,PChar('GdipGetImagePixelFormat'));
  @GdipDrawImageRectRect             := GetProcAddress(hGDIPlus,PChar('GdipDrawImageRectRect'));
  @GdipCreateBitmapFromScan0         := GetProcAddress(hGDIPlus,PChar('GdipCreateBitmapFromScan0'));
end;

procedure GDIPlusDeInit;
begin
  if hGDIPlus<>0 then FreeLibrary(hGDIPlus);
end;

initialization
  GDIPlusInit;

finalization
  GDIPlusDeInit;

end.
