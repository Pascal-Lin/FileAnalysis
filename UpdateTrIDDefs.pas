unit UpdateTrIDDefs;

interface

uses
  System.Classes, System.SysUtils, IdHTTP, IdSSLOpenSSL, MSHTML, RegularExpressions, vcl.Dialogs;


type
  TCheckTrIDDefsThread = class(TThread)
  private
    FOnComplete: TProc; // 用于接收响应的事件
    procedure Complete;
  protected
    procedure Execute; override;
  public
    HTML: string;
    constructor Create;
    property OnComplete: TProc read FOnComplete write FOnComplete;
  end;


  TUpdateTrIDDefs = class
  private
    HTML: string;
    CheckTrIDDefsThread: TCheckTrIDDefsThread;
  protected
  public
    TRIDDEFSNUM: string; // 最新TrID数据库文件类型数量
    FILEDATE: string; // 最新TrID数据库文件的日期

    procedure CheckTrIDDefs(Callback: TProc);
  end;




implementation

uses
  TrIDLib;


{function}

function GetTextBetweenStrings(OrginStr, LeftStr, RightStr: string): string;
var
  RegEx: TRegEx;
  Match: TMatch;
begin
  RegEx := TRegEx.Create(LeftStr+'(.*?)'+RightStr, [roSingleLine]);
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

procedure TUpdateTrIDDefs.CheckTrIDDefs(Callback: TProc);
begin
  if Assigned(CheckTrIDDefsThread) then
  begin
    CheckTrIDDefsThread.Free;
  end;

  CheckTrIDDefsThread := TCheckTrIDDefsThread.Create;
  // 线程结束后回调
  CheckTrIDDefsThread.OnComplete := procedure
    begin
      HTML := CheckTrIDDefsThread.HTML;
      TRIDDEFSNUM := GetTextBetweenStrings(HTML, '<!-- MKHP TRIDDEFSNUM-->', '<!-- MKHP -->');
      FILEDATE := GetTextBetweenStrings(HTML, '<!-- MKHP FILEDATE /homepage-mark0/download/triddefs.zip-->', '<!-- MKHP -->');
      Callback; // 回调
    end;
  CheckTrIDDefsThread.Start;
end;



{ TCheckTrIDDefsThread }

constructor TCheckTrIDDefsThread.Create;
begin
  FreeOnTerminate := True;  // Execute执行完毕后，线程自动销毁
  inherited Create(True);  // 创建线程但不立即启动
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
    HTML := IdHTTP.Get(URL);
  finally
    IdHTTP.Free;
    SSLHandler.Free;
  end;
  Synchronize(Complete); // 在主线程中调用响应处理方法
end;

procedure TCheckTrIDDefsThread.Complete;
begin
  if Assigned(FOnComplete) then
  begin
    FOnComplete; // 触发事件
  end;
end;


end.
