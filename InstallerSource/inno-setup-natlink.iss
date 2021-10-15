#define MyGUID "{{dd990001-bb89-11d2-b031-0060088dc929}"
#define Bits "32bit"

#define SitePackagesDir "{app}\site-packages"
#define CoreDir "{app}\site-packages\natlink"

[Setup]
AppId={#MyGUID}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
LicenseFile={#SourceRoot}\LICENSE
OutputDir={#BinaryRoot}\InstallerSource
OutputBaseFilename=natlink{#MyAppVersion}-py{#PythonVersion}-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "{#SourceRoot}\natlink\*.py"; DestDir: "{#CoreDir}"; Flags: ignoreversion
Source: "{#SourceRoot}\natlink\*.pyi"; DestDir: "{#CoreDir}"; Flags: ignoreversion
Source: "{#BinaryRoot}\NatlinkSource\Debug\_natlink_core.pyd"; DestDir: "{#CoreDir}"; Flags: ignoreversion regserver {#Bits}
Source: "{#PythonDLL}"; DestDir: "{#CoreDir}"; Flags: ignoreversion

[Icons]
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

[Code]


var
  DragonIniPage: TInputDirWizardPage;

function BestGuessDragonIniDir(): String;
var
  TestDir: String;
begin
  Result := '';
  TestDir := ExpandConstant('{commonappdata}\Nuance\NaturallySpeaking15');
  if DirExists(TestDir) then
  begin
    Result := TestDir;
    exit;
  end;
  TestDir := ExpandConstant('{commonappdata}\Nuance\NaturallySpeaking14');
  if DirExists(TestDir) then
  begin
    Result := TestDir;
    exit;
  end;
  TestDir := ExpandConstant('{commonappdata}\Nuance\NaturallySpeaking13');
  if DirExists(TestDir) then
  begin
    Result := TestDir;
    exit;
  end;
  TestDir := ExpandConstant('{commonappdata}\Nuance\NaturallySpeaking12');
  if DirExists(TestDir) then
  begin
    Result := TestDir;
    exit;
  end;
end;

procedure InitializeWizard();
begin
  DragonIniPage := CreateInputDirPage(wpSelectDir, 'Select Dragon Ini Directory',
    'Where are the Dragon .ini files nsapps.ini and nssystem.ini stored? '+
    'Natlink must modify them to register Natlink as a compatibility module.',
    'To continue, click Next. If you would like to select a different folder, ' +
    'click Browse.', False, '');
  DragonIniPage.Add('');
  DragonIniPage.Values[0] := BestGuessDragonIniDir();
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = wpSelectDir) then
  begin
    if not FileExists(DragonIniPage.Values[0]+'\nsapps.ini') then
    begin
      MsgBox('nsapps.ini not found in that directory', mbError, MB_OK);
      Result := False;
      exit;
    end;
    if not FileExists(DragonIniPage.Values[0]+'\nssystem.ini') then
    begin
      MsgBox('nssystem.ini not found in that directory', mbError, MB_OK);
      Result := False;
      exit;
    end;
  end;
end;

function IsAppRunning(const FileName : String): Boolean;
var
    FSWbemLocator: Variant;
    FWMIService   : Variant;
    FWbemObjectSet: Variant;
begin
    Result := False;
    FSWbemLocator := CreateOleObject('WBEMScripting.SWBEMLocator');
    FWMIService := FSWbemLocator.ConnectServer('', 'root\CIMV2', '', '');
    FWbemObjectSet :=
      FWMIService.ExecQuery(
        Format('SELECT Name FROM Win32_Process Where Name="%s"', [FileName]));
    Result := (FWbemObjectSet.Count > 0);
    FWbemObjectSet := Unassigned;
    FWMIService := Unassigned;
    FSWbemLocator := Unassigned;
end;

function IsDragonRunning(): Boolean;
begin
  Result := IsAppRunning('dragonbar.exe') or IsAppRunning('natspeak.exe')
end;

function CorrectPythonFound(): Boolean;
begin
  Result := RegKeyExists(HKCU, 'Software\Python\PythonCore\{#PythonVersion}')
end;

function GetPythonInstallPath(Param: String): String;
begin
 if not RegQueryStringValue(HKLM, 'Software\Python\PythonCore\{#PythonVersion}\InstallPath', '', Result) then 
  begin
    MsgBox('Could not find registry key HKLM\Software\Python\PythonCore\{#PythonVersion}\InstallPath',
           mbError, MB_OK);
    exit
  end
end;

function InitializeSetup(): Boolean;
begin
  Result := True
  if not CorrectPythonFound() then
  begin
    MsgBox('Could not find Python {#PythonVersion}, aborting. '
    + 'Please install this Python then try again.', mbError, MB_OK );
    Result := False;
    exit;
  end;
  if IsDragonRunning() then
  begin
    MsgBox('Dragon is running, aborting. '
    + 'Please close dragonbar.exe and/or natspeak.exe then try again.', mbError, MB_OK );
    Result := False;
    exit;
  end;
end;

function InitializeUninstall(): Boolean;
begin
  Result := True
  if IsDragonRunning() then
  begin
    MsgBox('Dragon is running, aborting. '
    + 'Please close dragonbar.exe and/or natspeak.exe then try again.', mbError, MB_OK );
    Result := False;
    exit;
  end;
end;

function GetDragonIniDir(Param: String): String;
begin
  Result := DragonIniPage.Values[0];
end;

[Registry]
Root: HKLM; Subkey: "Software\{#MyAppName}"; Flags: uninsdeletekey

Root: HKLM; Subkey: "Software\{#MyAppName}"; ValueType: string; ValueName: "installPath"; ValueData: "{app}"

Root: HKLM; Subkey: "Software\{#MyAppName}"; ValueType: string; ValueName: "coreDir"; ValueData: "{#CoreDir}"

Root: HKLM; Subkey: "Software\{#MyAppName}"; ValueType: string; ValueName: "sitePackagesDir"; ValueData: "{#SitePackagesDir}"

; Register which Dragon software was found and where .ini files were changed
Root: HKLM; Subkey: "Software\{#MyAppName}"; ValueType: string; ValueName: "dragonIniDir"; ValueData: "{code:GetDragonIniDir}"

; Register 'natlink' version
Root: HKLM; Subkey: "Software\{#MyAppName}"; ValueType: string; ValueName: "version"; ValueData: "{#MyAppVersion}"

; Add a key for natlink COM server (_natlink_core.pyd) to find the Python installation
Root: HKLM; Subkey: "Software\{#MyAppName}"; ValueType: string; ValueName: "pythonInstallPath"; ValueData: "{code:GetPythonInstallPath}"

; Register natlink with command line invocations of Python: the Natlink site packages directory
; is added as an additonal site package directory to sys.path during interpreter initialization.
Root: HKLM; Subkey: "Software\Python\PythonCore\{#PythonVersion}\PythonPath\{#MyAppName}"; ValueType: string; ValueData: "{#SitePackagesDir}"; Flags: uninsdeletekey

[INI]                                                                                                                                                   
Filename: "{code:GetDragonIniDir}\nssystem.ini"; Section: "Global Clients"; Key: ".{#MyAppName}"; String: "Python Macro System"; Flags: uninsdeleteentry
Filename: "{code:GetDragonIniDir}\nsapps.ini"; Section: ".{#MyAppName}"; Key: "App Support GUID"; String: "{#MyGUID}"; Flags: uninsdeletesection