; Oblivion - Windows installer script (Inno Setup 6)
;
; Compile from the repository root:
;   iscc windows\installer\oblivion.iss
;
; The script expects the Flutter release bundle under
; build\windows\x64\runner\Release and, optionally, a copy of
; vc_redist.x64.exe beside itself so machines without the Microsoft
; Visual C++ runtime get it installed silently. Everything the app
; needs (Aether core, Psiphon core, FFI bridge, tunnel helper, wintun)
; is carried inside the bundle, so the installed app needs nothing
; else on the machine.

#define MyAppName "Oblivion"
#define MyAppVersion "8.0.0"
#define MyAppPublisher "org.bepass"
#define MyAppURL "https://github.com/bepass-org/oblivion"
#define MyAppExeName "oblivion.exe"
#define ReleaseDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{7C4A9E2B-51D8-4C6F-9A3E-2B8F6D1C0E45}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\Oblivion
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=..\..\LICENSE
OutputDir=..\..\dist
OutputBaseFilename=Oblivion-Setup-x64
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
VersionInfoVersion={#MyAppVersion}.0
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} setup
VersionInfoProductName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: VCRedistNeeded

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing the Microsoft Visual C++ runtime..."; Check: VCRedistNeeded
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function VCRedistNeeded: Boolean;
begin
  Result := not FileExists(ExpandConstant('{sys}') + '\vcruntime140_1.dll');
end;
