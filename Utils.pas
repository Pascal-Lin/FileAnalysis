unit Utils;

interface

uses
  System.SysUtils, PascalLin.HTTP, RegularExpressions, Winapi.ShellAPI,
  Winapi.Windows,
  ActiveX, ComObj, ShlObj;

var
  HTTP: THTTP;

function GetTextBetweenStrings(OrginStr, LeftStr, RightStr: string): string;
function GetLnkTarget(const ShortcutPath: string): string;
function MatchExt(const FilePath: string; Ext: string): Boolean;

implementation

// 匹配扩展名 MatchExt('c:/a.lnk', '.lnk')
function MatchExt(const FilePath: string; Ext: string): Boolean;
begin
  Result := LowerCase(ExtractFileExt(FilePath)) = Ext;
end;

// 快捷方式的真实地址
function GetLnkTarget(const ShortcutPath: string): string;
var
  Int_link: IShellLink;
  int_File: IPersistFile;
  SFileName: WideString;
  DirName: String;
  OutPutFileName: PChar;
  WinData: win32_find_data;
begin
  if not MatchExt(ShortcutPath, '.lnk') then
  begin
    Result := ShortcutPath;
    Exit;
  end;

  SFileName := PChar(ShortcutPath);
  Int_link := CreateComObject(CLSID_Shelllink) as IShellLink;
  int_File := Int_link as IPersistFile;
  int_File.Load(pwchar(SFileName), STGM_READ);
  Setlength(DirName, MAX_PATH);
  OutPutFileName := PChar(DirName);
  Int_link.GetPath(OutPutFileName, MAX_PATH, WinData, 0);
  Result := OutPutFileName;
end;

function GetTextBetweenStrings(OrginStr, LeftStr, RightStr: string): string;
var
  RegEx: TRegEx;
  Match: TMatch;
begin
  RegEx := TRegEx.Create(LeftStr + '(.*?)' + RightStr, [roSingleLine]);
  Match := RegEx.Match(OrginStr);

  if Match.Success then
  begin
    Result := Match.Groups[1].Value.Trim; // 返回提取的字符串
  end
  else
  begin
    Result := '';
  end;
end;

end.
