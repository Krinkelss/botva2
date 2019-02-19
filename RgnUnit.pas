unit RgnUnit;

interface

uses
  Windows;

function CreateBitmapRgn(DC : hDC; Bitmap: hBitmap; TransClr: TColorRef; dX:integer=0; dY:integer=0): hRgn; stdcall;
{
������ ������� ������� ������, ��������� ��� ����� ����� Bitmap
� �������� �� ���� ���� TransClr. ��� ������� ������������ ���
���������� DC.

������ ������� ������� �� ���� ������:

������ ����� �������� ������ � �������� ���� �������� ����������� � �������
24 ���� �� �����, ��� �������, �.�. ���������� � ������ ���� ������
������� ������� ������ ����� ������� ���� ����� ��������� �����������.
������ ������ ��� ������ �� �������� ��� ���������
(��� ������������� ��������� �������), � ���� �� ��� ������ ��������
��� ����������� ��������� �����������. ������, ������������ ����� ������������
����� ������.

��� ��������� ������ ��� �������������� ����������� ������������ �������
WinAPI CreateDIBSection. ������ ������� �������� ������ � �������
���������� �����. ��� ������ ������ ������� ���������� ��������� ���������
BITMAPINFO, ��� ���������� �� ������.
��������! ��� ����������� Windows Bitmap ������������ ���������� � �������
dots per metr (pixels per metr), ������������ ���������� 72dpi �������������
2834dpm.

����������, ������ ������� ����� �� ������������, ������� ������� ������
��� ������������ �������� ��������� �����������.

��� ����������� � �������� ��������� ����������� � ��������� ������
������������ ������� WinAPI GetDIBits. ������� ���������� ��������� ���������:
�������� �����������, ���������� ����� ��� ��������, ��������� �� ������,
���� ������� ��������� �����������, ��������� BITMAPINFO � ����������� �������
������ ������� (������ ����� �������� ��������� ��� ���������������
�����������). ����������, ������ ������� ����� ��������� ����� �������� �����
� ����� ����������� �����.

������ ���� ����������� ������� ���������� �� ������� ������, ���� ����
�������� �������������� �����������, �������� �������� ������� � ������ ������.
��� �������� ������� ������������ ������� WinAPI ExtCreateRegion. ��� ������
������ ������� ���������� ��������� ��������� RGNDATA, ��������� �� ���������
RGNDATAHEADER � ������������ ���������� �������� RECT. � ������ ���������
RGNDATA ������� ���:

  _RGNDATA = record
    rdh: TRgnDataHeader;
    Buffer: array[0..0] of CHAR;
    Reserved: array[0..2] of CHAR;
  end;
  RGNDATA = _RGNDATA;

������ �����, ���� Reserved ���� ������� �������������� ������ ������ ��� ����,
����� � ��� �������� ���� �� ���� �������������, �.�. � Microsoft Platfrom SDK
����� ���� ���. ������, ������ ��������� ��� �� ��������, �.�. ��� ����������
��������� ����� ��������� ���������������. ��� ������� ���� ������ ����������
�������� ������ �������, � ������ RGNDATAHEADER � ���������� ���������������,
����������� ���, �������� ���� �������������� (����� RGNDATAHEADER),
��������� ��������� �� ��������� RGNDATA � ������� ��� �� ��������� ������.

�������������, �������� ��� ���� �������� �� ������: ������ ��� - ��� �������
���������� ���������������, � ������ - ��� ��� ������������ �� ���������
� ���������� ������.

���� ��������� �������� ��� ��������� �������� ������� ������, �� ��� ���
����� ���� ���������� � ����� �� ���������������. � ����� ������, ���� ���
������� � ������� ����������� ��� ��� ������� ���������� ������.

�� �������� ������ ������� ������������� ������, ���������� �� ��������������
����� � ��������� RGNDATA.
}

implementation

function Rect(Left, Top, Right, Bottom: Integer): TRect;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Bottom := Bottom;
  Result.Right := Right;
end;


//������� ������ �� ������ Bitmap ��� DC � ��������� ����� TransClr
//��������! TColorRef � TColor �� ���� � ����.
//��� �������� ������������ ������� ColorToRGB().

function CreateBitmapRgn(DC: hDC; Bitmap: hBitmap; TransClr: TColorRef; dX:integer=0; dY:integer=0): hRgn; stdcall;
var
  bmInfo: TBitmap;                //��������� BITMAP WinAPI
  W, H: Integer;                  //������ � ������ ������
  bmDIB: hBitmap;                 //���������� ������������ ������
  bmiInfo: BITMAPINFO;            //��������� BITMAPINFO WinAPI
  lpBits, lpOldBits: PRGBTriple;  //��������� �� ��������� RGBTRIPLE WinAPI
  lpData: PRgnData;               //��������� �� ��������� RGNDATA WinAPI
  X, Y, C, F, I: Integer;         //���������� ������
  Buf: Pointer;                   //���������
  BufSize: Integer;               //������ ���������
  rdhInfo: TRgnDataHeader;        //��������� RGNDATAHEADER WinAPI
  lpRect: PRect;                  //��������� �� TRect (RECT WinAPI)
begin
  Result:=0;
  if Bitmap=0 then Exit;          //���� ����� �� �����, �������

  GetObject(Bitmap, SizeOf(bmInfo), @bmInfo);  //������ ������� ������
  W:=bmInfo.bmWidth;                           //��������� ��������� BITMAP
  H:=bmInfo.bmHeight;
  I:=(W*3)-((W*3) div 4)*4;                    //���������� �������� � ������
  if I<>0 then I:=4-I;

//���������: ����� Windows Bitmap �������� ����� �����, ������ ������ ������
//����������� �������� ������� �� �� ��������� 4.
//��� 32-� ������ ������� ����� ����� ������ �� ����.

//��������� BITMAPINFO ��� �������� � CreateDIBSection

  bmiInfo.bmiHeader.biWidth:=W;             //������
  bmiInfo.bmiHeader.biHeight:=H;            //������
  bmiInfo.bmiHeader.biPlanes:=1;            //������ 1
  bmiInfo.bmiHeader.biBitCount:=24;         //��� ����� �� �������
  bmiInfo.bmiHeader.biCompression:=BI_RGB;  //��� ����������
  bmiInfo.bmiHeader.biSizeImage:=0;         //������ �� �����, ������ � ����
  bmiInfo.bmiHeader.biXPelsPerMeter:=2834;  //�������� �� ����, ���.
  bmiInfo.bmiHeader.biYPelsPerMeter:=2834;  //�������� �� ����, ����.
  bmiInfo.bmiHeader.biClrUsed:=0;           //������� ���, ��� � ����
  bmiInfo.bmiHeader.biClrImportant:=0;      //�� ��
  bmiInfo.bmiHeader.biSize:=SizeOf(bmiInfo.bmiHeader); //������ ���������
  bmDIB:=CreateDIBSection(DC, bmiInfo, DIB_RGB_COLORS,
                          Pointer(lpBits), 0, 0);
//������� ����������� ����� WxHx24, ��� �������, � ��������� lpBits ��������
//����� ������� ����� ����� ������. bmDIB - ���������� ������

//��������� ������ ����� ������ BITMAPINFO ��� �������� � GetDIBits

  bmiInfo.bmiHeader.biWidth:=W;             //������
  bmiInfo.bmiHeader.biHeight:=H;            //������
  bmiInfo.bmiHeader.biPlanes:=1;            //������ 1
  bmiInfo.bmiHeader.biBitCount:=24;         //��� ����� �� �������
  bmiInfo.bmiHeader.biCompression:=BI_RGB;  //��� ���������
  bmiInfo.bmiHeader.biSize:=SizeOf(bmiInfo.bmiHeader); //������ ���������
  //GetDIBits(DC, Bitmap, 0, H-1, lpBits, bmiInfo, DIB_RGB_COLORS);
  //��������, � �� ���� ������� ������� �� ������������� South
  GetDIBits(DC, Bitmap, 0, H{-1}, lpBits, bmiInfo, DIB_RGB_COLORS);
//������������ �������� ����� � ��� � ��� ������������ �� ������ lpBits

  lpOldBits:=lpBits;  //���������� ����� lpBits

//������ ������ - ������������ ����� ���������������, ����������� ���
//�������� �������
  C:=0;                         //������� ����
  for Y:=H-1 downto 0 do        //������ ����� �����
    begin
      X:=0;
      while X<W do              //�� 0 �� ������-1
        begin
//���������� ��������� ����, ���������� ���������� � ���������
          while (RGB(lpBits.rgbtRed, lpBits.rgbtGreen,
                     lpBits.rgbtBlue)=TransClr) and (X<W) do
            begin
              Inc(lpBits);
              X:=X+1;
            end;
//���� ����� �� ���������� ����, �� �������, ������� ����� � ���� �� ����
          if RGB(lpBits.rgbtRed, lpBits.rgbtGreen,
                 lpBits.rgbtBlue)<>TransClr then
            begin
              while (RGB(lpBits.rgbtRed, lpBits.rgbtGreen,
                      lpBits.rgbtBlue)<>TransClr) and (X<W) do
                begin
                  Inc(lpBits);
                  X:=X+1;
                end;
              C:=C+1;  //����������� ������� ���������������
            end;
        end;
//��� ����������, ���������� ��������� ��������� �� ��������� 4
      PChar(lpBits):=PChar(lpBits)+I;
    end;

  lpBits:=lpOldBits;  //��������������� �������� lpBits

//��������� ��������� RGNDATAHEADER
  rdhInfo.iType:=RDH_RECTANGLES;             //����� ������������ ��������������
  rdhInfo.nCount:=C;                         //�� ����������
  rdhInfo.nRgnSize:=0;                       //������ �������� ������ �� �����
  rdhInfo.rcBound:=Rect(0, 0, W, H);         //������ �������
  rdhInfo.dwSize:=SizeOf(rdhInfo);           //������ ���������

//�������� ������ ��� �������� RGNDATA:
//����� RGNDATAHEADER � ����������� �� ���������������
  BufSize:=SizeOf(rdhInfo)+SizeOf(TRect)*C;
  GetMem(Buf, BufSize);
  lpData:=Buf;             //������ ��������� �� ���������� ������
  lpData.rdh:=rdhInfo;     //������� � ������ RGNDATAHEADER

//���������� ������ ����������������
  lpRect:=@lpData.Buffer;  //������ �������������
  for Y:=H-1 downto 0 do
    begin
      X:=0;
      while X<W do
        begin
          while (RGB(lpBits.rgbtRed, lpBits.rgbtGreen,
                  lpBits.rgbtBlue)=TransClr) and (X<W) do
            begin
              Inc(lpBits);
              X:=X+1;
            end;
          if RGB(lpBits.rgbtRed, lpBits.rgbtGreen,
                 lpBits.rgbtBlue)<>TransClr then
            begin
              F:=X;
              while (RGB(lpBits.rgbtRed, lpBits.rgbtGreen,
                      lpBits.rgbtBlue)<>TransClr) and (X<W) do
                begin
                  Inc(lpBits);
                  X:=X+1;
                end;
//              lpRect^:=Rect(F, Y, X, Y+1);  //������� ����������
              lpRect^:=Rect(F+dX, Y+dY, X+dX, Y+1+dY);  //������� ����������
              Inc(lpRect);                  //��������� � ����������
            end;
        end;
      PChar(lpBits):=PChar(lpBits)+I;
    end;

//����� ��������� ���������� ��������� RGNDATA ����� ��������� ������.
//������������� ��� �� �����, ������ � nil, ��������� ������
//��������� ��������� � �� ����.
  Result:=ExtCreateRegion(nil, BufSize, lpData^);  //������� ������

  FreeMem(Buf, BufSize);  //������ ��������� RGNDATA ������ �� �����, �������
  DeleteObject(bmDIB);    //��������� ����� ���� �������
end;

end.
