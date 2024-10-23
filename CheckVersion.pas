unit CheckVersion;

interface

uses
  System.Classes, System.JSON, PascalLin.HTTP, IdIcmpClient,
  Winapi.Windows, Vcl.Forms, Winapi.ShellAPI;

type
  TCheckVersion = class
  private
    function GetLatestTag(const AJsonStr: string): string;
    function PingHost(const AHost: string): Boolean;
  public
    OnNotify: THTTPNotifyEvent;
    OnComplete: THTTPCompleteEvent;
    procedure Start;
  end;

implementation

uses
  Utils;

const
  URI = 'https://api.github.com/repos/Pascal-Lin/FileAnalysis/releases/latest';

procedure TCheckVersion.Start;
var
  HTML: string;
begin
  OnNotify('正在获取Github上的版本信息...');

  TThread.CreateAnonymousThread(
    procedure
    begin
      // PING Github
      if not PingHost('api.github.com') then
      begin
        TThread.Synchronize(nil,
          procedure
          begin
            if Assigned(OnNotify) then
              OnNotify('你的网络似乎被一股神秘力量所笼罩，导致你无法触摸到外面的世界！');
          end);

        // Github Ping不通，中止
        Exit;
      end;

      var
      HTTP := THTTP.Create;
      HTTP.OnComplete := procedure()
        begin
          var
          TagName := GetLatestTag(HTML);
          if Assigned(OnNotify) then
          begin
            case CompareVersion(CurrentVersion, TagName) of
              - 1:
                begin
                  OnNotify('发现最新版本：' + TagName);
                  OnNotify('请前往项目的Github下载：' + GithubURL);

                  if ID_YES = Application.MessageBox(PChar('发现最新版本：' + TagName +
                    #13 + '是否前往项目的Github？'), PChar('提示'),
                    MB_YESNO + MB_SYSTEMMODAL) then
                  begin
                    ShellExecute(0, 'open', PChar(GithubURL), nil, nil, SW_SHOWNORMAL);
                  end;
                end;
              0, 1:
                OnNotify('当前已是最新版本！');
            end;
          end;
        end;

      HTTP.Get(URI, HTML);

    end).Start; // 启动匿名线程

end;

function TCheckVersion.GetLatestTag(const AJsonStr: string): string;
var
  JsonValue: TJSONValue;
  JsonObject: TJSONObject;
begin
  Result := '';
  JsonValue := TJSONObject.ParseJSONValue(AJsonStr);
  try
    if JsonValue is TJSONObject then
    begin
      JsonObject := JsonValue as TJSONObject;
      Result := JsonObject.GetValue<string>('tag_name');
    end
    else
      // Writeln('JSON is not an object.');
    finally
      JsonValue.Free;
    end;
  end;

  function TCheckVersion.PingHost(const AHost: string): Boolean;
  var
    IcmpClient: TIdIcmpClient;
  begin
    IcmpClient := TIdIcmpClient.Create(nil);
    try
      IcmpClient.Host := AHost;
      IcmpClient.ReceiveTimeout := 2000; // 设置接收超时为2秒
      IcmpClient.Ping; // 发送 Ping 请求

      Result := (IcmpClient.ReplyStatus.ReplyStatusType = rsEcho);
    finally
      IcmpClient.Free;
    end;
  end;

end.
