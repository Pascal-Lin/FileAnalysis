unit UpdateTrIDDefs;

interface

uses
  System.Classes, System.SysUtils, System.Zip, PascalLin.HTTP, Task;

type
  TWorkProc = reference to procedure(AWorkCount, AWorkCountMax: Int64);

  TUpdateTrIDDefs = class(TTask)
  private
    function GetLocalTrIDDefsNum: Integer;
  protected
    HTTP: THTTP;
    procedure UnZip(FileName: string; Path: string);
    procedure ZipFileOnProgress(Sender: TObject; FileName: string; Header: TZipHeader; Position: Int64);
  public
    TRIDDEFSNUM: string; // 最新TrID数据库文件类型数量
    FILEDATE: string; // 最新TrID数据库文件的日期
    OnWorkBegin: THTTPWorkBeginEvent;
    OnWork: THTTPWorkEvent;
    OnComplete: THTTPCompleteEvent;
    OnNotify: THTTPNotifyEvent;
    procedure Start;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  TrIDLib, Utils;


{ TUpdateTrIDDefs }


constructor TUpdateTrIDDefs.Create;
begin
  HTTP := THTTP.Create;
end;

destructor TUpdateTrIDDefs.Destroy;
begin
  // 清理代码，例如释放资源
  HTTP.Free;
  inherited Destroy; // 调用基类析构函数
end;


procedure TUpdateTrIDDefs.Start;
var
  HTML: string;
  FileName: string;
begin
  FileName := ExtractFilePath(Paramstr(0))+'triddefs.zip';

  HTTP.OnWorkBegin := OnWorkBegin;
  HTTP.OnWork := OnWork;
  HTTP.OnNotify := OnNotify;
  HTTP.OnComplete := procedure
    begin
      // 提取HTML中的数据库信息
      TRIDDEFSNUM := GetTextBetweenStrings(HTML, '<!-- MKHP TRIDDEFSNUM-->',
        '<!-- MKHP -->');
      FILEDATE := GetTextBetweenStrings(HTML,
        '<!-- MKHP FILEDATE /homepage-mark0/download/triddefs.zip-->',
        '<!-- MKHP -->');

      // 转换TRIDDEFSNUM
      var RemoteTrIDDefsNum: Integer;
      if not TryStrToInt(TRIDDEFSNUM, RemoteTrIDDefsNum) then
      begin
        // TODO 给RichEdit编写通用方法，并支持高亮
        OnNotify('获取远程TrID数据库信息失败！此次更新中止！');
        if Assigned(OnComplete) then OnComplete;
        exit;
      end;

      // 在子线程里读取TrIDDefs
      TThread.CreateAnonymousThread(
        procedure
        begin
          Sleep(1000);
          var LocalTrIDDefsNum := GetLocalTrIDDefsNum;

          // 比对数据库
          if (RemoteTrIDDefsNum < LocalTrIDDefsNum) then
          begin
            TThread.Synchronize(nil,
              procedure
              begin
                OnNotify('你使用的TrID数据库可能来自于未来！作者感觉压力太大，有点害怕此次更新。');
                if Assigned(OnComplete) then OnComplete;
              end);
            exit;
          end;

          if (RemoteTrIDDefsNum = LocalTrIDDefsNum) then
          begin
            TThread.Synchronize(nil,
              procedure
              begin
                OnNotify('当前TrID数据库已经是最新的，不需要更新！');
                if Assigned(OnComplete) then OnComplete;
              end);
            exit;
          end;


          // 找到新的数据库文件，开始下载
          var
          Msg := '找到最新的TrID数据库：发布于' + FILEDATE + '，包含' +
            RemoteTrIDDefsNum.ToString + '个文件类型数据。';
          OnNotify(Msg);
          OnNotify('开始下载TrID数据库...');

          // 下载数据库文件
          // 上一次HTTP线程实际上并没有结束，因为这是在它的OnComplete里
          // 这里执行ShouldDisconnect，强行断开链接并销毁线程。
          HTTP.ShouldDisconnect;
          HTTP.OnComplete := procedure
            begin
              // 解压
              TThread.CreateAnonymousThread(
                procedure
                begin
                  Sleep(1000);
                  OnNotify('TrID数据库已下载，开始解压...');
                  UnZip(FileName, ExtractFilePath(Paramstr(0)));
                  TThread.Synchronize(nil,
                    procedure
                    begin
                      OnNotify('TrID数据库更新成功！');
                      OnNotify('当前TrID数据库含有' + RemoteTrIDDefsNum.ToString + '个文件类型。');
                      if Assigned(OnComplete) then OnComplete; // 触发事件
                    end);
                end
              ).Start; // 启动匿名线程


            end;
          HTTP.GetFile('https://mark0.net/download/triddefs.zip', FileName);

        end
      ).Start; // 启动匿名线程


    end;
  HTTP.Get('https://mark0.net/soft-trid-e.html', HTML);

end;


function TUpdateTrIDDefs.GetLocalTrIDDefsNum: Integer;
var
  sOut: string;
begin
  TrIDLib.LoadDefsPack(ExtractFilePath(Paramstr(0)));
  // load the definitions package (TrIDDefs.TRD) from current path
  Result := TrIDLib.GetInfo(TRID_GET_DEFSNUM, 0, sOut);
end;

procedure TUpdateTrIDDefs.UnZip(FileName: string; Path: string);
begin
  var ZipFile: TZipFile;
  ZipFile := TZipFile.Create;
  try
    ZipFile.OnProgress := ZipFileOnProgress;
    ZipFile.Open(FileName, zmRead);
    ZipFile.ExtractAll(Path); // 解压到指定目录
  finally
    ZipFile.Free;
  end;

end;


procedure TUpdateTrIDDefs.ZipFileOnProgress(Sender: TObject; FileName: string; Header: TZipHeader; Position: Int64);
begin
  TThread.Synchronize(nil, procedure
  begin
    if Assigned(OnWorkBegin) then OnWorkBegin(Header.UncompressedSize);
    if Assigned(OnWork) then OnWork(Position);
  end);
end;




end.
