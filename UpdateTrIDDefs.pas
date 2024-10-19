unit UpdateTrIDDefs;

interface

uses
  System.Classes, System.SysUtils, IdHTTP, IdSSLOpenSSL, MSHTML,
  RegularExpressions, vcl.Dialogs, System.Zip,
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
    procedure ZipFileOnProgress(Sender: TObject; FileName: string; Header: TZipHeader; Position: Int64);
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

  // FIXME 需要编写一个函数来统一实现修改进度条
  FOnWork(0, 100);

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

// FIXME 出现异常要返回主线程并提示
procedure TDownloadTrIDDefsThread.Execute;
var
  IdHTTP: TIdHTTP;
  SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
  ZipFileName: string;
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


    ZipFileName := ExtractFilePath(Paramstr(0))+'triddefs.zip';
    if FileExists(ZipFileName) then DeleteFile(ZipFileName);  // FIXME 当zip文件被打开时会报错
    var FileStream := TFileStream.Create(ZipFileName, fmCreate);
    IdHTTP.Get(URL, FileStream);
    FileStream.Free;
    Sleep(1000);  //暂停1秒等待进度条刷新
  finally
    IdHTTP.Free;
    SSLHandler.Free;
  end;

  // 解压
  var ZipFile: TZipFile;
  ZipFile := TZipFile.Create;
  try
    ZipFile.OnProgress := ZipFileOnProgress;
    ZipFile.Open(ZipFileName, zmRead);
    ZipFile.ExtractAll(ExtractFilePath(Paramstr(0))); // 解压到指定目录

  finally
    ZipFile.Free;
  end;

  Sleep(1000);  //暂停1秒等待进度条刷新

  Synchronize(
    procedure
    begin
      if Assigned(FOnComplete) then
      begin
        FOnComplete; // 触发事件
      end;
    end);
end;


procedure TDownloadTrIDDefsThread.ZipFileOnProgress(Sender: TObject; FileName: string; Header: TZipHeader; Position: Int64);
begin
  Synchronize(
    procedure
    begin
      if Assigned(FOnWork) then
      begin
        FOnWork(Position, Header.UncompressedSize);
      end;
    end);
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

  Sleep(1000);  //暂停1秒等待进度条刷新

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
