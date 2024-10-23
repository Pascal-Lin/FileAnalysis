unit Utils;

interface

uses
  System.SysUtils, PascalLin.HTTP, RegularExpressions, Winapi.ShellAPI,
  Winapi.Windows, System.Classes, System.Math,
  ActiveX, ComObj, ShlObj;

var
  HTTP: THTTP;

const
  CurrentVersion = '4.0.1';
  GithubURL = 'https://github.com/Pascal-Lin/FileAnalysis';
  TrIDWebSite = 'https://mark0.net';

function GetTextBetweenStrings(OrginStr, LeftStr, RightStr: string): string;
function GetLnkTarget(const ShortcutPath: string): string;
function MatchExt(const FilePath: string; Ext: string): Boolean;
function CompareVersion(const Version1, Version2: string): Integer;

implementation


// 比较版本号
{
  用法示例
  case CompareVersion('1.0.1', '2.1.3') of
    -1: Writeln('Version 1.0.1 is less than Version 2.1.3');
    1: Writeln('Version 1.0.1 is greater than Version 2.1.3');
    0: Writeln('Version 1.0.1 is equal to Version 2.1.3');
  end;
}
function CompareVersion(const Version1, Version2: string): Integer;
var
  Parts1, Parts2: TStringList;
  i, MinCount: Integer;
  Num1, Num2: Integer;
begin
  Parts1 := TStringList.Create;
  Parts2 := TStringList.Create;
  try
    Parts1.Delimiter := '.';
    Parts2.Delimiter := '.';
    Parts1.DelimitedText := Version1;
    Parts2.DelimitedText := Version2;

    MinCount := Min(Parts1.Count, Parts2.Count);
    for i := 0 to MinCount - 1 do
    begin
      Num1 := StrToInt(Parts1[i]);
      Num2 := StrToInt(Parts2[i]);
      if Num1 < Num2 then Exit(-1);
      if Num1 > Num2 then Exit(1);
    end;

    // 如果长度不同，比较剩余部分
    if Parts1.Count < Parts2.Count then
      Exit(-1)
    else if Parts1.Count > Parts2.Count then
      Exit(1);

    Result := 0; // 版本相同
  finally
    Parts1.Free;
    Parts2.Free;
  end;
end;




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
