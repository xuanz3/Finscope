[Setup]
AppId=FinScope.XuanzeChen
AppName=Finscope
AppVersion=1.0.0-rc.7
AppPublisher=Xuanze Chen
DefaultDirName={localappdata}\Programs\FinScope
PrivilegesRequired=lowest
OutputDir=..\dist
OutputBaseFilename=Finscope-Windows-Setup
SetupIconFile=icons\app_icon.ico
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{autoprograms}\Finscope"; Filename: "{app}\finscope.exe"
