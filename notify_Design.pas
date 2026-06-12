unit notify_Design;

interface

procedure Register;

implementation

{$R 'modern_notification_design.res'}

uses
  System.Classes,
  System.SysUtils,
  Vcl.Graphics,
  Vcl.Dialogs,
  DesignIntf,
  DesignEditors,
  ToolsAPI,
  notify_Unit;

const
  SplashBitmapResourceName = 'TMODERNNOTIFICATION_32';
  SplashCaption = 'Modern Notification v1.0';

type
  TDefaultIconNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  TIconFileNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure Edit; override;
  end;

  TVersionProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
  end;

{ TDefaultIconNameProperty }

function TDefaultIconNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paValueList, paSortList];
end;

procedure TDefaultIconNameProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
  LIconNames: TStringList;
begin
  LIconNames := TStringList.Create;
  try
    GetModernNotificationDefaultIconNames(LIconNames);
    for I := 0 to LIconNames.Count - 1 do
      Proc(LIconNames[I]);
  finally
    LIconNames.Free;
  end;
end;

{ TIconFileNameProperty }

procedure TIconFileNameProperty.Edit;
var
  LDialog: TOpenDialog;
  LFileName: string;
begin
  LDialog := TOpenDialog.Create(nil);
  try
    LDialog.Filter :=
      'Images (*.png;*.bmp;*.jpg;*.jpeg;*.ico)|*.png;*.bmp;*.jpg;*.jpeg;*.ico|' +
      'PNG (*.png)|*.png|' +
      'Tous les fichiers (*.*)|*.*';
    LDialog.Options := [ofFileMustExist, ofPathMustExist, ofEnableSizing];

    LFileName := GetValue;
    if LFileName <> '' then
    begin
      LDialog.FileName := LFileName;
      if DirectoryExists(ExtractFilePath(LFileName)) then
        LDialog.InitialDir := ExtractFilePath(LFileName);
    end;

    if LDialog.Execute then
      SetValue(LDialog.FileName);
  finally
    LDialog.Free;
  end;
end;

function TIconFileNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paDialog];
end;

{ TVersionProperty }

function TVersionProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paReadOnly];
end;

procedure AddSplashScreen;
var
  LBitmap: TBitmap;
begin
  if SplashScreenServices = nil then
    Exit;

  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromResourceName(HInstance, SplashBitmapResourceName);
    SplashScreenServices.AddPluginBitmap(SplashCaption, LBitmap.Handle, False, '');
  finally
    LBitmap.Free;
  end;
end;

procedure Register;
begin
  System.Classes.RegisterComponents('Modern Notification', [TModernNotification]);
  RegisterPropertyEditor(TypeInfo(string), TModernNotification, 'DefaultIconName', TDefaultIconNameProperty);
  RegisterPropertyEditor(TypeInfo(string), TModernNotification, 'IconFileName', TIconFileNameProperty);
  RegisterPropertyEditor(TypeInfo(string), TModernNotification, 'Version', TVersionProperty);
end;

initialization
  AddSplashScreen;

end.
