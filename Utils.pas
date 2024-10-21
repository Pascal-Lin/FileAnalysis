unit Utils;

interface

uses
  System.SysUtils, PascalLin.HTTP, RegularExpressions;

var
  HTTP: THTTP;

function GetTextBetweenStrings(OrginStr, LeftStr, RightStr: string): string;


implementation


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
