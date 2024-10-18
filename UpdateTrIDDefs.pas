unit UpdateTrIDDefs;

interface

uses
  System.Classes, System.SysUtils, IdHTTP, IdSSLOpenSSL, MSHTML,
  RegularExpressions, vcl.Dialogs,
  IdComponent;

type
  TWorkProc = reference to procedure(AWorkCount, AWorkCountMax: Int64);

  TCheckTrIDDefsThread = class(TThread)
  private
    FOnWork: TWorkProc;
    FOnComplete: TProc; // 用于接收响应的事件
    AWorkCountMax: Int64; // 数据库文件大小（由IdHTTP的WorkBegin事件获取）
  protected
    procedure Execute; override;
    procedure WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure Work(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
  public
    HTML: string;
    constructor Create;
    property OnWork: TWorkProc read FOnWork write FOnWork;
    property OnComplete: TProc read FOnComplete write FOnComplete;
  end;

  TDownloadTrIDDefsThread = class(TThread)
  private
    FOnWork: TWorkProc;
    FOnComplete: TProc; // 用于接收响应的事件
    AWorkCountMax: Int64; // 数据库文件大小（由IdHTTP的WorkBegin事件获取）
  protected
    procedure Execute; override;
    procedure WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure Work(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
  public
    constructor Create;
    property OnWork: TWorkProc read FOnWork write FOnWork;
    property OnComplete: TProc read FOnComplete write FOnComplete;
  end;

  TUpdateTrIDDefs = class
  private
    HTML: string;
    CheckTrIDDefsThread: TCheckTrIDDefsThread;
    DownloadTrIDDefsThread: TDownloadTrIDDefsThread;
  protected
  public
    TRIDDEFSNUM: string; // 最新TrID数据库文件类型数量
    FILEDATE: string; // 最新TrID数据库文件的日期

    procedure CheckTrIDDefs(FOnWork: TWorkProc; FOnComplete: TProc);
    procedure DownloadTrIDDefs(FOnWork: TWorkProc; FOnComplete: TProc);
  end;

implementation

uses
  TrIDLib;

{ function }

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

{ TUpdateTrIDDefs }

// 检测最新数据库的入口函数
procedure TUpdateTrIDDefs.CheckTrIDDefs(FOnWork: TWorkProc; FOnComplete: TProc);
begin
  if Assigned(CheckTrIDDefsThread) then
  begin
    CheckTrIDDefsThread.Free;
  end;

  CheckTrIDDefsThread := TCheckTrIDDefsThread.Create;

  // 回调IdHTTP的OnWork，用于进度条显示
  CheckTrIDDefsThread.OnWork := FOnWork;

  // 线程结束后回调
  CheckTrIDDefsThread.OnComplete := procedure
    begin
      HTML := CheckTrIDDefsThread.HTML;
      TRIDDEFSNUM := GetTextBetweenStrings(HTML, '<!-- MKHP TRIDDEFSNUM-->',
        '<!-- MKHP -->');
      FILEDATE := GetTextBetweenStrings(HTML,
        '<!-- MKHP FILEDATE /homepage-mark0/download/triddefs.zip-->',
        '<!-- MKHP -->');
      FOnComplete; // 回调
    end;
  CheckTrIDDefsThread.Start;
end;

// 下载数据库的入口函数
procedure TUpdateTrIDDefs.DownloadTrIDDefs(FOnWork: TWorkProc;
  FOnComplete: TProc);
begin
  if Assigned(DownloadTrIDDefsThread) then
  begin
    DownloadTrIDDefsThread.Free;
  end;

  DownloadTrIDDefsThread := TDownloadTrIDDefsThread.Create;

  // 回调IdHTTP的OnWork，用于进度条显示
  DownloadTrIDDefsThread.OnWork := FOnWork;

  // 线程结束后回调
  DownloadTrIDDefsThread.OnComplete := FOnComplete;

  DownloadTrIDDefsThread.Start;
end;

{ TDownloadTrIDDefsThread }

constructor TDownloadTrIDDefsThread.Create;
begin
  FreeOnTerminate := True; // Execute执行完毕后，线程自动销毁
  inherited Create(True); // 创建线程但不立即启动
end;

procedure TDownloadTrIDDefsThread.Execute;
var
  IdHTTP: TIdHTTP;
  SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
const
  URL = 'https://mark0.net/download/triddefs.zip';
begin
  IdHTTP := TIdHTTP.Create(nil);
  { ##############################################
    需要OpenSSL库（libeay32.dll 和 ssleay32.dll）
    https://openssl-library.org/source/index.html
    https://wiki.overbyte.eu/wiki/index.php/ICS_Download
    ############################################## }
  SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  SSLHandler.SSLOptions.Method := sslvTLSv1_2; // 或其他你需要的版本
  try
    IdHTTP.IOHandler := SSLHandler; // 设置 SSL 处理程序

    IdHTTP.OnWorkBegin := WorkBegin;
    IdHTTP.OnWork := Work;


    var FileName := ExtractFilePath(Paramstr(0))+'TrIDDefs.zip';
    if FileExists(FileName) then DeleteFile(FileName);
    var FileStream := TFileStream.Create(FileName, fmCreate);
    IdHTTP.Get(URL, FileStream);
    FileStream.Free;

  finally
    IdHTTP.Free;
    SSLHandler.Free;
  end;

  Synchronize(
    procedure
    begin
      if Assigned(FOnComplete) then
      begin
        FOnComplete; // 触发事件
      end;
    end);

  // 解压

end;

procedure TDownloadTrIDDefsThread.WorkBegin(ASender: TObject;
AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
  Self.AWorkCountMax := AWorkCountMax
end;

procedure TDownloadTrIDDefsThread.Work(ASender: TObject; AWorkMode: TWorkMode;
AWorkCount: Int64);
begin
  Synchronize(
    procedure
    begin
      if Assigned(FOnWork) then
      begin
        FOnWork(AWorkCount, AWorkCountMax);
      end;
    end);
end;

{ TCheckTrIDDefsThread }

// 检测最新数据库子线程
constructor TCheckTrIDDefsThread.Create;
begin
  FreeOnTerminate := True; // Execute执行完毕后，线程自动销毁
  inherited Create(True); // 创建线程但不立即启动
end;

procedure TCheckTrIDDefsThread.Execute;
var
  IdHTTP: TIdHTTP;
  SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
const
  URL = 'https://mark0.net/soft-trid-e.html';
begin
  HTML := '';
  IdHTTP := TIdHTTP.Create(nil);
  { ##############################################
    需要OpenSSL库（libeay32.dll 和 ssleay32.dll）
    https://openssl-library.org/source/index.html
    https://wiki.overbyte.eu/wiki/index.php/ICS_Download
    ############################################## }
  SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  SSLHandler.SSLOptions.Method := sslvTLSv1_2; // 或其他你需要的版本
  try
    IdHTTP.IOHandler := SSLHandler; // 设置 SSL 处理程序

    IdHTTP.OnWorkBegin := WorkBegin;
    IdHTTP.OnWork := Work;

//AWorkCountMax := IdHTTP.Head('http://example.com/file.zip');

    HTML := IdHTTP.Get(URL);
  finally
    IdHTTP.Free;
    SSLHandler.Free;
  end;

  Synchronize(
    procedure
    begin
      if Assigned(FOnComplete) then
      begin
        FOnComplete; // 触发事件
      end;
    end);

end;

procedure TCheckTrIDDefsThread.WorkBegin(ASender: TObject; AWorkMode: TWorkMode;
AWorkCountMax: Int64);
begin
  Self.AWorkCountMax := AWorkCountMax;
end;

procedure TCheckTrIDDefsThread.Work(ASender: TObject; AWorkMode: TWorkMode;
AWorkCount: Int64);
begin
  Synchronize(
    procedure
    begin
      if Assigned(FOnWork) then
      begin
        FOnWork(AWorkCount, AWorkCountMax);
      end;
    end);
end;

end.
