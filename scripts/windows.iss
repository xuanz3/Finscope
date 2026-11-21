[Setup]
AppId=FinScope.XuanzeChen
AppName=FinScope
AppVersion=1.0.0-rc.5
AppPublisher=Xuanze Chen
DefaultDirName={localappdata}\Programs\FinScope
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=FinScope-Windows-Setup
SetupIconFile=icons\app_icon.ico
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{autoprograms}\FinScope"; Filename: "{app}\finscope.exe"
