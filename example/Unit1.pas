unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, notify_Unit, Vcl.StdCtrls, system.Hash, system.Win.Registry;

type
  TForm1 = class(TForm)
    Button1: TButton;
    ModernNotification1: TModernNotification;
    procedure Button1Click(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

Procedure RegisterAppForNotifications;
const
  AppIDPrefix = 'Embarcadero.DesktopToasts.';
var
  Reg: TRegistry;
  AppID, IconPath: string;
begin
  AppID   := AppIDPrefix + THashBobJenkins.GetHashString(ParamStr(0));
  IconPath := 'C:\Users\abdelkader\AppData\Local\ChifaStat\icone1.png'; //ParamStr(0); // L'EXE lui-même contient l'icône

  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
   // if Reg.OpenKey('Software\Classes\AppUserModelId\' + AppID, True) then
     if Reg.OpenKey('Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\' + AppID, True) then
    try
      Reg.WriteString('DisplayName', 'b4all');
      Reg.WriteString('IconUri',     IconPath);
    finally
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  RegisterAppForNotifications;
  ShowNotification('b4a', 'welecome', 'C:\Users\abdelkader\AppData\Local\ChifaStat\button-ok.png');
end;

end.

