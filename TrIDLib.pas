// TrIDLib wrapper Unit
// http://mark0.ne/code-tridlib-e.html

unit TrIDLib;

interface

const
  // Constants FOR TrID_GetInfo
  TRID_GET_RES_NUM         = 1;     // Get the number of results available
  TRID_GET_RES_FILETYPE    = 2;     // Filetype descriptions
  TRID_GET_RES_FILEEXT     = 3;     // Filetype extension
  TRID_GET_RES_POINTS      = 4;     // Matching points

  TRID_GET_VER             = 1001;  // TrIDLib version (major * 100 + minor)
  TRID_GET_DEFSNUM         = 1004;  // Number of filetypes definitions loaded

  // Additional constants for the full version
  TRID_GET_DEF_ID          = 100;   // Get the id of the filetype's definition for a given result
  TRID_GET_DEF_FILESCANNED = 101;   // Various info about that def
  TRID_GET_DEF_AUTHORNAME  = 102;   //     "
  TRID_GET_DEF_AUTHOREMAIL = 103;   //     "
  TRID_GET_DEF_AUTHORHOME  = 104;   //     "
  TRID_GET_DEF_FILE        = 105;   //     "
  TRID_GET_DEF_REMARK      = 106;   //     "
  TRID_GET_DEF_RELURL      = 107;   //     "
  TRID_GET_DEF_TAG         = 108;   //     "
  TRID_GET_DEF_MIMETYPE    = 109;   //     "

  TRID_GET_ISTEXT          = 1005;  // Check if the submitted file is text or binary one

  // DLL Functions
  function TrID_Analyze: integer; stdcall; external 'tridlib.dll' name 'TrID_Analyze';
  // Additional DLL function for the full version
  function TrID_SetDefsPack(lDefsPtr: integer): integer; stdcall; external 'tridlib.dll' name 'TrID_SetDefsPack';
  // Wrapped DLL functions
  function TrID_SubmitFileA(szFileName: PAnsiChar): integer; stdcall; external 'tridlib.dll' name 'TrID_SubmitFileA';
  function TrID_LoadDefsPack(szPath: PAnsiChar): integer; stdcall; external 'tridlib.dll' name 'TrID_LoadDefsPack';
  function TrID_GetInfo(lInfoType: integer; lInfoIdx: integer; sBuf: PAnsiChar): integer; stdcall; external 'tridlib.dll' name 'TrID_GetInfo';

  // Wrappers that use the standard Delphi strings
  function LoadDefsPack(sPath: string): integer;
  function SubmitFileA(sFileName: string): integer;
  function GetInfo(lInfoType: integer; lInfoIdx: integer; var sOut: string): integer;

implementation

function LoadDefsPack(sPath: string): integer;
begin
  Result := TrID_LoadDefsPack(PAnsiChar(AnsiString(sPath)));
end;

function SubmitFileA(sFileName: string): integer;
begin
  Result := TrID_SubmitFileA(PAnsiChar(AnsiString(sFileName)));
end;

function GetInfo(lInfoType: integer; lInfoIdx: integer; var sOut: string): integer;
var
  szBuf: array[0..4095] of AnsiChar;
  Temp : PAnsiChar;
begin
  Temp := szBuf;
  Result := TrID_GetInfo(lInfoType, lInfoIdx, Temp);
  sOut := Temp;
end;

end.
