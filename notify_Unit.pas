unit notify_Unit;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.Hash,
  System.SysUtils,
  System.Win.Registry,
  Winapi.DataRT,
  Winapi.WinRT,
  Winapi.UI.Notifications,
  System.Win.WinRT;

type
  TModernNotification = class(TComponent)
  private
    FAppID: string;
    FBody: string;
    FDefaultIcon: Boolean;
    FDefaultIconName: string;
    FIconFileName: string;
    FTitle: string;
    FUpdateRegistryIconUri: Boolean;
    FUseLargeIcon: Boolean;
    function GetVersion: string;
  protected
    function ResolveAppID: string; virtual;
    function ResolveIconFileName: string; virtual;
    function ResolveVersion: string; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Show; overload;
    procedure Show(const ATitle, ABody: string); overload;
  published
    property AppID: string read FAppID write FAppID;
    property Body: string read FBody write FBody;
    property DefaultIcon: Boolean read FDefaultIcon write FDefaultIcon default True;
    property DefaultIconName: string read FDefaultIconName write FDefaultIconName;
    property IconFileName: string read FIconFileName write FIconFileName;
    property Title: string read FTitle write FTitle;
    property UpdateRegistryIconUri: Boolean read FUpdateRegistryIconUri write FUpdateRegistryIconUri default True;
    property UseLargeIcon: Boolean read FUseLargeIcon write FUseLargeIcon default True;
    property Version: string read GetVersion stored False;
  end;

procedure ShowNotification(const ATitle, ABody: string); overload;
procedure ShowNotification(const ATitle, ABody, AIconFileName: string); overload;
procedure GetModernNotificationDefaultIconNames(AStrings: TStrings);

implementation

{$R modern_notification_resources.res}

const
  DefaultAppIDPrefix = 'Embarcadero.DesktopToasts.';
  DefaultIconRelativePath = 'images\button-info.png';
  DefaultIconNameValue = 'button-info';

type
  TEmbeddedIconInfo = record
    Name: string;
    ResourceName: string;
    TempFileName: string;
  end;

const
  EmbeddedIcons: array[0..28] of TEmbeddedIconInfo = (
    (Name: 'button-cancel'; ResourceName: 'MODERN_NOTIFICATION_ICON_BUTTON_CANCEL'; TempFileName: 'modern_notification_button_cancel.png'),
    (Name: 'button-download'; ResourceName: 'MODERN_NOTIFICATION_ICON_BUTTON_DOWNLOAD'; TempFileName: 'modern_notification_button_download.png'),
    (Name: 'button-error'; ResourceName: 'MODERN_NOTIFICATION_ICON_BUTTON_ERROR'; TempFileName: 'modern_notification_button_error.png'),
    (Name: 'button-help'; ResourceName: 'MODERN_NOTIFICATION_ICON_BUTTON_HELP'; TempFileName: 'modern_notification_button_help.png'),
    (Name: 'button-info'; ResourceName: 'MODERN_NOTIFICATION_ICON_BUTTON_INFO'; TempFileName: 'modern_notification_button_info.png'),
    (Name: 'button-ok'; ResourceName: 'MODERN_NOTIFICATION_ICON_BUTTON_OK'; TempFileName: 'modern_notification_button_ok.png'),
    (Name: 'button-refresh'; ResourceName: 'MODERN_NOTIFICATION_ICON_BUTTON_REFRESH'; TempFileName: 'modern_notification_button_refresh.png'),
    (Name: 'button-trend-down'; ResourceName: 'MODERN_NOTIFICATION_ICON_BUTTON_TREND_DOWN'; TempFileName: 'modern_notification_button_trend_down.png'),
    (Name: 'button-update'; ResourceName: 'MODERN_NOTIFICATION_ICON_BUTTON_UPDATE'; TempFileName: 'modern_notification_button_update.png'),
    (Name: 'chart-pie-2d'; ResourceName: 'MODERN_NOTIFICATION_ICON_CHART_PIE_2D'; TempFileName: 'modern_notification_chart_pie_2d.png'),
    (Name: 'chart-pie-2d-exploded'; ResourceName: 'MODERN_NOTIFICATION_ICON_CHART_PIE_2D_EXPLODED'; TempFileName: 'modern_notification_chart_pie_2d_exploded.png'),
    (Name: 'charts'; ResourceName: 'MODERN_NOTIFICATION_ICON_CHARTS'; TempFileName: 'modern_notification_charts.png'),
    (Name: 'charts-colors'; ResourceName: 'MODERN_NOTIFICATION_ICON_CHARTS_COLORS'; TempFileName: 'modern_notification_charts_colors.png'),
    (Name: 'charts-area-color'; ResourceName: 'MODERN_NOTIFICATION_ICON_CHARTS_AREA_COLOR'; TempFileName: 'modern_notification_charts_area_color.png'),
    (Name: 'emoticon-happy'; ResourceName: 'MODERN_NOTIFICATION_ICON_EMOTICON_HAPPY'; TempFileName: 'modern_notification_emoticon_happy.png'),
    (Name: 'emoticon-sad'; ResourceName: 'MODERN_NOTIFICATION_ICON_EMOTICON_SAD'; TempFileName: 'modern_notification_emoticon_sad.png'),
    (Name: 'emoticon-smile'; ResourceName: 'MODERN_NOTIFICATION_ICON_EMOTICON_SMILE'; TempFileName: 'modern_notification_emoticon_smile.png'),
    (Name: 'find'; ResourceName: 'MODERN_NOTIFICATION_ICON_FIND'; TempFileName: 'modern_notification_find.png'),
    (Name: 'fire'; ResourceName: 'MODERN_NOTIFICATION_ICON_FIRE'; TempFileName: 'modern_notification_fire.png'),
    (Name: 'fire2'; ResourceName: 'MODERN_NOTIFICATION_ICON_FIRE2'; TempFileName: 'modern_notification_fire2.png'),
    (Name: 'flag-algeria'; ResourceName: 'MODERN_NOTIFICATION_ICON_FLAG_ALGERIA'; TempFileName: 'modern_notification_flag_algeria.png'),
    (Name: 'gift'; ResourceName: 'MODERN_NOTIFICATION_ICON_GIFT'; TempFileName: 'modern_notification_gift.png'),
    (Name: 'internet'; ResourceName: 'MODERN_NOTIFICATION_ICON_INTERNET'; TempFileName: 'modern_notification_internet.png'),
    (Name: 'light-bulb'; ResourceName: 'MODERN_NOTIFICATION_ICON_LIGHT_BULB'; TempFileName: 'modern_notification_light_bulb.png'),
    (Name: 'new'; ResourceName: 'MODERN_NOTIFICATION_ICON_NEW'; TempFileName: 'modern_notification_new.png'),
    (Name: 'on-off'; ResourceName: 'MODERN_NOTIFICATION_ICON_ON_OFF'; TempFileName: 'modern_notification_on_off.png'),
    (Name: 'reminder'; ResourceName: 'MODERN_NOTIFICATION_ICON_REMINDER'; TempFileName: 'modern_notification_reminder.png'),
    (Name: 'save'; ResourceName: 'MODERN_NOTIFICATION_ICON_SAVE'; TempFileName: 'modern_notification_save.png'),
    (Name: 'user-profile'; ResourceName: 'MODERN_NOTIFICATION_ICON_USER_PROFILE'; TempFileName: 'modern_notification_user_profile.png')
  );

function FileNameToFileUri(const AFileName: string): string;
var
  LFileName: string;
begin
  LFileName := StringReplace(ExpandFileName(AFileName), '\', '/', [rfReplaceAll]);
  Result := 'file:///' + LFileName;
end;

procedure UpdateNotificationRegistryIconUri(const AAppID, AIconFileName: string);
const
  NotificationsSettingsKey = 'Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\';
var
  LRegistry: TRegistry;
begin
  if (AAppID = '') or (AIconFileName = '') or not FileExists(AIconFileName) then
    Exit;

  LRegistry := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    LRegistry.RootKey := HKEY_CURRENT_USER;
    if LRegistry.OpenKey(NotificationsSettingsKey + AAppID, True) then
    begin
      LRegistry.WriteString('IconUri', ExpandFileName(AIconFileName));
      LRegistry.WriteInteger('ShowInActionCenter', 1);
    end;
  finally
    LRegistry.Free;
  end;
end;

function GetFileVersionString(const AFileName: string): string;
var
  LBuffer: TBytes;
  LFileInfo: PVSFixedFileInfo;
  LHandle: DWORD;
  LInfoSize: DWORD;
  LLen: UINT;
begin
  Result := '';
  if not FileExists(AFileName) then
    Exit;

  LInfoSize := GetFileVersionInfoSize(PChar(AFileName), LHandle);
  if LInfoSize = 0 then
    Exit;

  SetLength(LBuffer, LInfoSize);
  if not GetFileVersionInfo(PChar(AFileName), LHandle, LInfoSize, Pointer(LBuffer)) then
    Exit;

  if VerQueryValue(Pointer(LBuffer), '\', Pointer(LFileInfo), LLen) and (LFileInfo <> nil) then
    Result := Format('%d.%d.%d.%d', [
      HiWord(LFileInfo.dwFileVersionMS),
      LoWord(LFileInfo.dwFileVersionMS),
      HiWord(LFileInfo.dwFileVersionLS),
      LoWord(LFileInfo.dwFileVersionLS)
    ]);
end;

function GetModuleFileNameString(const AModuleHandle: HINST): string;
var
  LBuffer: array[0..MAX_PATH - 1] of Char;
  LLength: DWORD;
begin
  Result := '';
  LLength := GetModuleFileName(AModuleHandle, LBuffer, Length(LBuffer));
  if LLength > 0 then
    SetString(Result, LBuffer, LLength);
end;

function FindEmbeddedIconInfo(const AIconName: string; out AInfo: TEmbeddedIconInfo): Boolean;
var
  I: Integer;
  LIconName: string;
begin
  LIconName := Trim(AIconName);
  if LIconName = '' then
    LIconName := DefaultIconNameValue;

  for I := Low(EmbeddedIcons) to High(EmbeddedIcons) do
    if SameText(EmbeddedIcons[I].Name, LIconName) then
    begin
      AInfo := EmbeddedIcons[I];
      Exit(True);
    end;

  for I := Low(EmbeddedIcons) to High(EmbeddedIcons) do
    if SameText(EmbeddedIcons[I].Name, DefaultIconNameValue) then
    begin
      AInfo := EmbeddedIcons[I];
      Exit(True);
    end;

  Result := False;
end;

function ExtractEmbeddedIconFromResource(const AIconName: string): string;
var
  LIconInfo: TEmbeddedIconInfo;
  LModuleHandle: HINST;
  LResourceStream: TResourceStream;
begin
  if not FindEmbeddedIconInfo(AIconName, LIconInfo) then
    Exit('');

  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + LIconInfo.TempFileName;

  try
    LModuleHandle := FindClassHInstance(TModernNotification);
    LResourceStream := TResourceStream.Create(LModuleHandle, LIconInfo.ResourceName, RT_RCDATA);
    try
      LResourceStream.SaveToFile(Result);
    finally
      LResourceStream.Free;
    end;
  except
    Result := '';
  end;
end;

procedure SetTextNode(const ANodeList: Xml_Dom_IXmlNodeList; const AIndex: Cardinal; const AValue: string);
begin
  if ANodeList.Length > AIndex then
    (ANodeList.Item(AIndex) as Xml_Dom_IXmlNodeSerializer).InnerText := TWindowsString.Create(AValue);
end;

procedure GetModernNotificationDefaultIconNames(AStrings: TStrings);
var
  I: Integer;
begin
  if AStrings = nil then
    Exit;

  AStrings.BeginUpdate;
  try
    AStrings.Clear;
    for I := Low(EmbeddedIcons) to High(EmbeddedIcons) do
      AStrings.Add(EmbeddedIcons[I].Name);
  finally
    AStrings.EndUpdate;
  end;
end;

{ TModernNotification }

constructor TModernNotification.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDefaultIcon := True;
  FDefaultIconName := DefaultIconNameValue;
  FUpdateRegistryIconUri := True;
  FUseLargeIcon := True;
end;

function TModernNotification.ResolveAppID: string;
begin
  Result := Trim(FAppID);
  if Result = '' then
    Result := DefaultAppIDPrefix + THashBobJenkins.GetHashString(ParamStr(0));
end;

function TModernNotification.ResolveIconFileName: string;
begin
  Result := Trim(FIconFileName);
  if (Result <> '') and FileExists(Result) then
    Exit;

  if not FDefaultIcon then
  begin
    Result := '';
    Exit;
  end;

  Result := ExtractEmbeddedIconFromResource(FDefaultIconName);
  if Result = '' then
    Result := ExtractFilePath(ParamStr(0)) + DefaultIconRelativePath;
end;

function TModernNotification.ResolveVersion: string;
var
  LModuleFileName: string;
begin
  LModuleFileName := GetModuleFileNameString(FindClassHInstance(TModernNotification));
  Result := GetFileVersionString(LModuleFileName);
end;

function TModernNotification.GetVersion: string;
begin
  Result := ResolveVersion;
end;

procedure TModernNotification.Show;
begin
  Show(FTitle, FBody);
end;

procedure TModernNotification.Show(const ATitle, ABody: string);
var
  LAppID: string;
  LHasIcon: Boolean;
  LIconPath: string;
  LImageElement: Xml_Dom_IXmlElement;
  LImageNodes: Xml_Dom_IXmlNodeList;
  LTextNodes: Xml_Dom_IXmlNodeList;
  LToastNotification: IToastNotification;
  LToastNotifier: IToastNotifier;
  LToastXML: Xml_Dom_IXmlDocument;
begin
  LIconPath := ResolveIconFileName;
  LHasIcon := (LIconPath <> '') and FileExists(LIconPath);

  if LHasIcon then
    LToastXML := TToastNotificationManager.Statics.GetTemplateContent(ToastTemplateType.ToastImageAndText02)
  else
    LToastXML := TToastNotificationManager.Statics.GetTemplateContent(ToastTemplateType.ToastText02);

  LTextNodes := LToastXML.GetElementsByTagName(TWindowsString.Create('text'));
  SetTextNode(LTextNodes, 0, ATitle);
  SetTextNode(LTextNodes, 1, ABody);

  if LHasIcon then
  begin
    LImageNodes := LToastXML.GetElementsByTagName(TWindowsString.Create('image'));
    if LImageNodes.Length > 0 then
    begin
      LImageElement := LImageNodes.Item(0) as Xml_Dom_IXmlElement;
      LImageElement.SetAttribute(TWindowsString.Create('src'), TWindowsString.Create(FileNameToFileUri(LIconPath)));

      if FUseLargeIcon then
        LImageElement.SetAttribute(TWindowsString.Create('placement'), TWindowsString.Create('appLogoOverride'));
    end;
  end;

  LToastNotification := TToastNotification.Factory.CreateToastNotification(LToastXML);
  LAppID := ResolveAppID;
  if FUpdateRegistryIconUri and LHasIcon then
    UpdateNotificationRegistryIconUri(LAppID, LIconPath);
  LToastNotifier := TToastNotificationManager.Statics.CreateToastNotifier(TWindowsString.Create(LAppID));
  LToastNotifier.Show(LToastNotification);
end;

procedure ShowNotification(const ATitle, ABody: string);
begin
  ShowNotification(ATitle, ABody, '');
end;

procedure ShowNotification(const ATitle, ABody, AIconFileName: string);
var
  LNotification: TModernNotification;
begin
  LNotification := TModernNotification.Create(nil);
  try
    LNotification.IconFileName := AIconFileName;
    LNotification.Show(ATitle, ABody);
  finally
    LNotification.Free;
  end;
end;

end.
