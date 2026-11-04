; Noise VPN - Windows installer (Inno Setup 6)
;
; One setup.exe does both jobs:
;   - not installed yet  -> fresh install
;   - already installed  -> in-place update (same folder, same shortcuts,
;                           running app is closed first, settings are kept)
; Windows recognises it as the same app because AppId never changes.
;
; The CI passes these with /D... ; the defaults let you build it locally too:
;   iscc windows\installer\noisevpn.iss

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef AppBuild
  #define AppBuild "0"
#endif
#ifndef BuildDir
  #define BuildDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist"
#endif
#ifndef OutputName
  #define OutputName "noise_vpn_windows_setup"
#endif

#define AppName      "Noise VPN"
#define AppExeName   "noisevpn.exe"
#define AppPublisher "Noise VPN"

[Setup]
; DO NOT CHANGE THIS GUID. It is what makes a newer setup an "update".
AppId={{6F1C7E2A-8B4D-4E9A-9C3F-2D5A7B1E0C84}
AppName={#AppName}
AppVersion={#AppVersion}.{#AppBuild}
AppVerName={#AppName} {#AppVersion} (build {#AppBuild})
AppPublisher={#AppPublisher}
VersionInfoVersion={#AppVersion}.{#AppBuild}
VersionInfoProductName={#AppName}
VersionInfoDescription={#AppName} Setup

DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Folder page only on first install; updates reuse the existing folder.
DisableDirPage=auto

; Program Files + TUN mode both need admin.
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0

OutputDir={#OutputDir}
OutputBaseFilename={#OutputName}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

; Close the app if it is running, don't restart it automatically.
CloseApplications=force
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[InstallDelete]
; Wipe old Flutter assets so files removed in a newer version don't linger.
; (User settings live in %APPDATA%, not here, so they survive updates.)
Type: filesandordirs; Name: "{app}\data"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Registry]
; The exe's manifest now asks for administrator itself, so the old
; "Always run as administrator" option is gone. Remove the compatibility
; flag older versions may have set.
Root: HKLM; Subkey: "SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"; ValueType: none; ValueName: "{app}\{#AppExeName}"; Flags: deletevalue uninsdeletevalue

[Run]
; shellexec so it still launches when "run as administrator" is on.
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent shellexec

[Code]
{ Close the app AND anything it started from the install folder (xray.exe,
  tun2socks.exe), otherwise they keep files locked and the update can't
  replace them.

  The window is asked to close first: the app then stops the VPN before it
  exits. Killing it outright while connected leaves flutter_vless's Windows
  Filtering Platform barrier in place, and the machine has no internet until
  the app is opened again and disconnected. Whatever is still running after
  10 seconds is killed. }
procedure KillAppProcesses();
var
  ResultCode: Integer;
  Dir, Cmd: String;
begin
  Dir := ExpandConstant('{app}');
  if not DirExists(Dir) then
    Exit;
  Cmd :=
    '$d = ''' + Dir + '\''; ' +
    '$m = { $_.Path -and $_.Path.StartsWith($d, [System.StringComparison]::OrdinalIgnoreCase) }; ' +
    '$p = @(Get-Process | Where-Object $m); ' +
    '$p | ForEach-Object { [void]$_.CloseMainWindow() }; ' +
    '$p | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue; ' +
    'Get-Process | Where-Object $m | Stop-Process -Force -ErrorAction SilentlyContinue';
  Exec(ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe'),
    '-NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "' + Cmd + '"',
    '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(800);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  KillAppProcesses();
  Result := '';
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    KillAppProcesses();
end;
