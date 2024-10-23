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
  OnNotify('���ڻ�ȡGithub�ϵİ汾��Ϣ...');

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
              OnNotify('��������ƺ���һ���������������֣��������޷���������������磡');
          end);

        // Github Ping��ͨ����ֹ
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
                  OnNotify('�������°汾��' + TagName);
                  OnNotify('��ǰ����Ŀ��Github���أ�' + GithubURL);

                  if ID_YES = Application.MessageBox(PChar('�������°汾��' + TagName +
                    #13 + '�Ƿ�ǰ����Ŀ��Github��'), PChar('��ʾ'),
                    MB_YESNO + MB_SYSTEMMODAL) then
                  begin
                    ShellExecute(0, 'open', PChar(GithubURL), nil, nil, SW_SHOWNORMAL);
                  end;
                end;
              0, 1:
                OnNotify('��ǰ�������°汾��');
            end;
          end;
        end;

      HTTP.Get(URI, HTML);

    end).Start; // ���������߳�

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
      IcmpClient.ReceiveTimeout := 2000; // ���ý��ճ�ʱΪ2��
      IcmpClient.Ping; // ���� Ping ����

      Result := (IcmpClient.ReplyStatus.ReplyStatusType = rsEcho);
    finally
      IcmpClient.Free;
    end;
  end;

end.
