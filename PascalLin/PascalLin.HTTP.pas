{
  以线程的方式封装了IdHTTP

  使用示例
procedure TMainForm.ToolButton5Click(Sender: TObject);
var
  html: string;
begin

  ProgressBar.Position := 0;

  if not Assigned(HTTP) then
  begin
    HTTP := THTTP.Create;
  end;

  HTTP.OnWorkBegin := procedure(AWorkCountMax: Int64)
    begin
      ProgressBar.Position := 0;
      ProgressBar.Max := AWorkCountMax;
      MessageRichEdit.Lines.Add('开始下载');
    end;
  HTTP.OnWork := procedure(AWorkCount: Int64)
    begin
      ProgressBar.Position := AWorkCount;
    end;
  HTTP.OnComplete := procedure
    begin
      ProgressBar.Position := 0;
      MessageRichEdit.Lines.Add('已完成');
      // 显示GET的HTML
      // MessageRichEdit.Text := html;
    end;
  // 获取HTML
  // HTTP.Get('https://mark0.net/soft-trid-e.html', html);
  // html在OnComplete中使用

  // 获取文件
  var FileName := ExtractFilePath(Paramstr(0))+'qq.exe';
  HTTP.GetFile('https://dldir1.qq.com/qqfile/qq/QQNT/Windows/QQ_9.9.15_241009_x64_01.exe', FileName);

end;


  每个THTTP实例中的Get、GetFile方法互斥，如果需要同时执行可创建多个THTTP实例

}

unit PascalLin.HTTP;

interface

uses
  System.Classes, Winapi.Windows, IdHTTP, IdSSLOpenSSL, IdComponent, System.SysUtils;

type
  // IdHTTP的OnWorkBegin只需要用到AWorkCount参数
  THTTPWorkBeginEvent = reference to procedure(AWorkCountMax: Int64);
  // IdHTTP的OnWork只需要用到AWorkCount参数
  THTTPWorkEvent = reference to procedure(AWorkCount: Int64);
  THTTPWorkEndEvent = TProc;
  THTTPCompleteEvent = TProc;
  THTTPConnectedEvent = TProc;
  THTTPDisconnectedEvent = TProc;
  THTTPNotifyEvent = reference to procedure(Msg: string);
  THTTPDebugEvent = reference to procedure(Msg: string);

  TIdHTTPThread = class(TThread)
  protected
    Callback: TProc;
    IdHTTP: TIdHTTP;
    SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
    FileStream: TFileStream;
    {}
    FOnWorkBegin: THTTPWorkBeginEvent;
    FOnWork: THTTPWorkEvent;
    FOnComplete: THTTPCompleteEvent;
    FOnDebug: THTTPDebugEvent;
    {}
    procedure Execute; override;
    procedure IdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCountMax: Int64);
    procedure IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode;
      AWorkCount: Int64);
  public
    constructor Create;
    procedure Disconnect;
    procedure Get(URL: string; HTML: PString);
    procedure GetFile(URL: string; FileName: string; Mode: Word = fmCreate);
  published
    property OnWorkBegin: THTTPWorkBeginEvent read FOnWorkBegin
      write FOnWorkBegin;
    property OnWork: THTTPWorkEvent read FOnWork write FOnWork;
    // IdHTTP在多线程强制Disconnect也会触发OnWorkEnd
    // property OnWorkEnd: THTTPWorkEndEvent read FOnWorkEnd write FOnWorkEnd;
    property OnComplete: THTTPCompleteEvent read FOnComplete write FOnComplete;
    property OnDebug: THTTPDebugEvent read FOnDebug write FOnDebug;
  end;

  THTTP = class
  protected
    IdHTTPThread: TIdHTTPThread;
  public
    procedure Get(URL: string; var HTML: string);
    procedure GetFile(URL: string; FileName: string; Mode: Word = fmCreate);
    procedure ShouldDisconnect;
  published
    OnWorkBegin: THTTPWorkBeginEvent;
    OnWork: THTTPWorkEvent;
    OnComplete: THTTPCompleteEvent;
    OnDebug: THTTPDebugEvent;
    OnNotify: THTTPNotifyEvent;
  end;

implementation

{ TIdHTTPThread }

constructor TIdHTTPThread.Create;
begin
  IdHTTP := TIdHTTP.Create;
  { ##############################################
    需要OpenSSL库（libeay32.dll 和 ssleay32.dll）
    https://openssl-library.org/source/index.html
    https://wiki.overbyte.eu/wiki/index.php/ICS_Download
    ############################################## }
  SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create;
  SSLHandler.SSLOptions.Method := sslvSSLv23; // 设置 SSL 版本
  IdHTTP.IOHandler := SSLHandler; // 关联 SSL 处理程序

  IdHTTP.OnWorkBegin := IdHTTPWorkBegin;
  IdHTTP.OnWork := IdHTTPWork;

  FreeOnTerminate := True; // Execute执行完毕后，线程自动销毁
  inherited Create(True);  // 创建线程但不立即启动
end;

procedure TIdHTTPThread.Execute;
begin
  if Assigned(Callback) then Callback; // 执行回调
  Synchronize(procedure
    begin
      if Assigned(FOnComplete) then FOnComplete;
    end);

  if Assigned(IdHTTP) then IdHTTP.Free;
  if Assigned(SSLHandler) then SSLHandler.Free;
  Terminate;
end;

// 线程互斥，需要IdHTTP.Disconnect
procedure TIdHTTPThread.Disconnect;
begin
  Self.OnWorkBegin := nil;
  Self.OnWork := nil;
  Self.OnComplete := nil;
  try
    if Assigned(FileStream) then FreeAndNil(FileStream);
    IdHTTP.Disconnect;
  except

  end;
end;

procedure TIdHTTPThread.Get(URL: string; HTML: PString);
begin
  Callback := procedure
    begin
      HTML^ := IdHTTP.Get(URL);
    end;
end;

procedure TIdHTTPThread.GetFile(URL: string; FileName: string; Mode: Word = fmCreate);
begin
  Callback := procedure
    begin
      try
        FileStream := TFileStream.Create(FileName, Mode);
        IdHTTP.Get(URL, FileStream);
        FreeAndNil(FileStream)
      except
        on E : EFCreateError do
        begin
          FOnDebug('Error: ' + E.Message);
        end;
      end;
    end;
end;


procedure TIdHTTPThread.IdHTTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
AWorkCountMax: Int64);
begin
  if Assigned(FOnWorkBegin) then
  begin
    Synchronize(procedure
      begin
        FOnWorkBegin(AWorkCountMax); // 调用外部的 OnWorkBegin 回调初始化（进度条最大值）
      end);
  end;

end;

procedure TIdHTTPThread.IdHTTPWork(ASender: TObject; AWorkMode: TWorkMode;
AWorkCount: Int64);
begin
  if Assigned(FOnWork) then
  begin
    Synchronize(procedure
      begin
        FOnWork(AWorkCount); // 调用外部的 OnWork 回调更新进度
      end);
  end;

end;

























{ THTTP }

procedure THTTP.Get(URL: string; var HTML: string);
begin
  if Assigned(IdHTTPThread) and not IdHTTPThread.Terminated then
  begin
    IdHTTPThread.Disconnect;
    if Assigned(OnNotify) then OnNotify('已中断上次未完成的请求。开始执行新的请求...');
  end;

  IdHTTPThread := TIdHTTPThread.Create;
  IdHTTPThread.OnWorkBegin := OnWorkBegin;
  IdHTTPThread.OnWork := OnWork;
  IdHTTPThread.OnComplete := OnComplete;
  IdHTTPThread.Get(URL, @HTML);
  IdHTTPThread.Start;
end;

procedure THTTP.GetFile(URL: string; FileName: string; Mode: Word = fmCreate);
begin
  if Assigned(IdHTTPThread) and not IdHTTPThread.Terminated then
  begin
    IdHTTPThread.Disconnect;
    if Assigned(OnNotify) then OnNotify('已中断上次未完成的请求。开始执行新的请求...');
  end;

  IdHTTPThread := TIdHTTPThread.Create;
  IdHTTPThread.OnWorkBegin := OnWorkBegin;
  IdHTTPThread.OnWork := OnWork;
  IdHTTPThread.OnComplete := OnComplete;
  IdHTTPThread.OnDebug := OnDebug;
  IdHTTPThread.GetFile(URL, FileName, fmCreate);
  IdHTTPThread.Start;

end;

procedure THTTP.ShouldDisconnect;
begin
  if Assigned(IdHTTPThread) then
  begin
    IdHTTPThread.Disconnect;
    IdHTTPThread := nil;
  end;
end;


end.
