unit PascalLin.Utils;

interface

uses
  System.Classes, System.SysUtils;

  procedure Wait(MilliSeconds: Cardinal; Callback: TProc);

implementation


procedure Wait(MilliSeconds: Cardinal; Callback: TProc);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(MilliSeconds); // 等待 1 秒钟
      TThread.Synchronize(nil,
        procedure
        begin
          Callback;
        end);
    end
  ).Start; // 启动匿名线程
end;

end.
