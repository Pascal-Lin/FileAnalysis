unit PascalLin.MD5;

interface

uses
  System.Classes, System.SysUtils, System.Hash;

type
  TMD5ReadyEvent = reference to procedure(AWorkCountMax: Int64);
  TMD5ProgressEvent = reference to procedure(AWorkCount: Int64);
  // 在主线程里即使让OnComplete=nil，THashMD5中的OnComplete依然有值，即无法中止MD5计算
  TMD5CompleteEvent = reference to procedure(MD5Str: string);
  TMD5NotifyEvent = reference to procedure(Msg: string);

  TMD5 = class
  protected
  public
    __Abort: Boolean;
    procedure Calculate(FileName: string);
    constructor Create;
  published
    OnReady: TMD5ReadyEvent;
    OnProgress: TMD5ProgressEvent;
    OnComplete: TMD5CompleteEvent;
    OnNotify: TMD5NotifyEvent;
  end;

implementation

constructor TMD5.Create;
begin
  __Abort := False;
end;

procedure TMD5.Calculate(FileName: string);
var
  BytesHasRead: Integer;
begin
  BytesHasRead := 0;
  TThread.CreateAnonymousThread(
    procedure
    begin
      try
        var
          FileStream: TFileStream;
          // 尝试以共享模式打开文件
        FileStream := TFileStream.Create(FileName, fmOpenRead or
          fmShareDenyWrite);
        try
          var
            FileSize: Int64;
          FileSize := FileStream.Size;
          TThread.Synchronize(nil,
            procedure
            begin
              if Assigned(OnReady) then
              begin
                OnReady(FileSize);
              end;
            end);

          var
            Buffer: TBytes;
          SetLength(Buffer, 4096); // 设置缓冲区大小
          var
          HashMD5 := THashMD5.Create;
          try
            var
              BytesRead: Integer;
            while (FileStream.Position < FileSize) do
            begin
              BytesRead := FileStream.Read(Buffer[0], Length(Buffer));
              if BytesRead > 0 then
              begin
                BytesHasRead := BytesHasRead + BytesRead;
                HashMD5.Update(Buffer, BytesRead);
                // 更新进度
                TThread.Synchronize(nil,
                  procedure
                  begin
                    if Assigned(OnProgress) then
                    begin
                      OnProgress(BytesHasRead);
                    end;
                  end);
              end;
            end;

            // 返回 MD5 哈希字符串给回调函数
            TThread.Synchronize(nil,
              procedure
              begin
                if Assigned(OnComplete) then
                begin
                  OnComplete(HashMD5.HashAsString);
                end;
              end);

          finally
          end;
        finally
          FileStream.Free;
        end;
      except
        // TFileStream.Create相关异常
        on E: Exception do
          TThread.Synchronize(nil,
            procedure
            begin
              if Assigned(OnNotify) then
                OnNotify(E.Message);
            end);
      end;
    end).Start; // 启动匿名线程

end;

end.
