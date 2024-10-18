unit Md5Thd;

interface

uses
  System.Classes, System.SysUtils, System.Hash, Vcl.ComCtrls;

type
  TMd5Thd = class(TThread)
  private
    FMD5Hash: string; // 保存文件最终的md5值
    FFileName: string;
    FMessageRichEdit: TRichEdit;
    FProgressBar: TProgressBar;
    procedure UpdateProgress(Position: Integer);
    procedure UpdateMessage(Msg: string);
    { Private declarations }
  protected
    procedure Execute; override;
  public
    constructor Create(AFileName: string; AMessageRichEdit: TRichEdit; AProgressBar: TProgressBar);
  end;


implementation


constructor TMd5Thd.Create(AFileName: string; AMessageRichEdit: TRichEdit; AProgressBar: TProgressBar);
begin
  FFileName := AFileName;   //传递目标文件给aidFile私有变量
  FMessageRichEdit := AMessageRichEdit;
  FProgressBar := AProgressBar;

  FreeOnTerminate := True;  //Execute执行完毕后，线程自动销毁
  inherited Create(false);  //创建后立即执行execute函数
end;

procedure TMd5Thd.Execute;
begin
  // 更新提示
  Synchronize(procedure
    begin
      UpdateMessage('正在计算该文件的MD5码...');
      UpdateProgress(0);
    end);
//  老方法（引用md5.pas），可以实现进度条
//  aidFileMD5 := MD5Print(FileToMD5(FileName, mainFRM.ShowProgress));
//  mainFrm.cxTreeList1.Bands[0].Caption.text := BandsText+ aidFileMD5;
//  var MD5String := GetFileMD5(FileName);
//  MessageRichEdit.Lines.Add(MD5String);
//  MessageRichEdit.Lines.Add(MD5String.ToLower);

  FMD5Hash := '';
  try
    var FileStream: TFileStream;
    // 尝试以共享模式打开文件
    FileStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
    try
      var FileSize: Int64;
      FileSize := FileStream.Size;
      FProgressBar.Max := FileSize;

      var Buffer: TBytes;
      SetLength(Buffer, 4096); // 设置缓冲区大小

      var MD5: THashMD5;
      MD5 := THashMD5.Create; // 初始化 MD5 对象
      try
        var BytesRead: Integer;
        while FileStream.Position < FileSize do
        begin
          BytesRead := FileStream.Read(Buffer[0], Length(Buffer));
          if BytesRead > 0 then
          begin
            MD5.Update(Buffer, BytesRead);
            // 更新进度
            Synchronize(procedure
              begin
                UpdateProgress(FProgressBar.Position + BytesRead);
              end);
          end;
        end;

      // 获取 MD5 哈希字节
      FMD5Hash := MD5.HashAsString; // 获取哈希字符串
      // 更新提示
      Synchronize(procedure
        begin
          // 输出最终结果
          UpdateMessage(FMD5Hash);
          UpdateProgress(0);
        end);

      finally
      end;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
      // 更新提示
      Synchronize(procedure
        begin
          UpdateMessage('无法读取文件：' + E.Message);
        end);
  end;


end;


procedure TMd5Thd.UpdateProgress(Position: integer);
begin
  FProgressBar.Position := Position;
end;

procedure TMd5Thd.UpdateMessage(Msg: string);
begin
  FMessageRichEdit.Lines.Add(Msg);
end;


end.
