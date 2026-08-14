#define MyAppName "Arcist"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "Arc Studio"
#define MyAppURL "https://github.com/yash-pamireddy/Arcist"
#define MyAppExeName "arcist.exe"

[Setup]
AppId={{A92C3D1E-8B3F-43C0-9A2E-1D8C43F291BB}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes

; --- Modern Setup Styling ---
WizardStyle=modern
SetupIconFile=windows\runner\resources\app_icon.ico
OutputDir=build\windows\installer
OutputBaseFilename=arcist-setup-v{#MyAppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Packages arcist.exe along with all required .dll files and assets
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent