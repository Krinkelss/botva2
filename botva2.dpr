library botva2;

uses
  main,
  for_png,
  gdipButton,
  RgnUnit,
  gdipCheckBox;

{$R version.res}

exports
  CheckBoxCreate,
  CheckBoxRefresh,
  CheckBoxSetText,
  CheckBoxGetText,
  CheckBoxGetVisibility,
  CheckBoxSetVisibility,
  CheckBoxGetEnabled,
  CheckBoxSetEnabled,
  CheckBoxSetFont,
  CheckBoxSetFontColor,
  CheckBoxSetChecked,
  CheckBoxGetChecked,
  CheckBoxSetEvent,
  CheckBoxSetPosition,
  CheckBoxGetPosition,
  CheckBoxSetCursor,

  BtnCreate,
  BtnRefresh,
  BtnSetText,
  BtnGetText,
  BtnSetTextAlignment,
  BtnGetVisibility,
  BtnSetVisibility,
  BtnGetEnabled,
  BtnSetEnabled,
  BtnSetFont,
  BtnSetFontColor,
  BtnSetChecked,
  BtnGetChecked,
  BtnSetEvent,
  BtnSetPosition,
  BtnGetPosition,
  BtnSetCursor,
  GetSysCursorHandle,

  ImgLoad,
  ImgSetPosition,
  ImgGetPosition,
  ImgSetVisibility,
  ImgGetVisibility,
  ImgSetVisiblePart,
  ImgGetVisiblePart,
  ImgSetTransparent,
  ImgGetTransparent,
  ImgRelease,
  ImgApplyChanges,

  CreateFormFromImage,
  CreateBitmapRgn,
  SetMinimizeAnimation,
  GetMinimizeAnimation,

  CheckBoxCreateFromRes,
  BtnCreateFromRes,
  ImgLoadFromRes,

  gdipShutdown;

begin
end.
 