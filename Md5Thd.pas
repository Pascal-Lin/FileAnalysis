unit Md5Thd;

interface

uses
  System.Classes, System.SysUtils, System.Hash, Vcl.ComCtrls;

type
  TMd5Thd = class(TThread)
  private
    FMD5Hash: string; // �����ļ����յ�md5ֵ
    FFileName: string;
    FMessageRichEdit: TRichEdit;
    FProgressBar: TProgressBar;
    procedure UpdateProgress(BytesRead: Int64; TotalBytes: Int64);
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
  FFileName := AFileName;   //����Ŀ���ļ���aidFile˽�б���
  FMessageRichEdit := AMessageRichEdit;
  FProgressBar := AProgressBar;

  FreeOnTerminate := false;
  inherited Create(false);  //����������ִ��execute����
end;

procedure TMd5Thd.Execute;
begin
  // ������ʾ
  Synchronize(procedure
    begin
      UpdateMessage('���ڼ�����ļ���MD5��...');
    end);
//  �Ϸ���������md5.pas��������ʵ�ֽ�����
//  aidFileMD5 := MD5Print(FileToMD5(FileName, mainFRM.ShowProgress));
//  mainFrm.cxTreeList1.Bands[0].Caption.text := BandsText+ aidFileMD5;
//  var MD5String := GetFileMD5(FileName);
//  MessageRichEdit.Lines.Add(MD5String);
//  MessageRichEdit.Lines.Add(MD5String.ToLower);

  FMD5Hash := '';
  try
    var FileStream: TFileStream;
    // �����Թ���ģʽ���ļ�
    FileStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyWrite);
    try
      var FileSize: Int64;
      FileSize := FileStream.Size;
      FProgressBar.Max := FileSize;

      var Buffer: TBytes;
      SetLength(Buffer, 4096); // ���û�������С

      var MD5: THashMD5;
      MD5 := THashMD5.Create; // ��ʼ�� MD5 ����
      try
        var BytesRead: Integer;
        while FileStream.Position < FileSize do
        begin
          BytesRead := FileStream.Read(Buffer[0], Length(Buffer));
          if BytesRead > 0 then
          begin
            MD5.Update(Buffer, BytesRead);
            // ���½���
            Synchronize(procedure
              begin
                UpdateProgress(BytesRead, FileSize);
              end);
          end;
        end;

      // ��ȡ MD5 ��ϣ�ֽ�
      FMD5Hash := MD5.HashAsString; // ��ȡ��ϣ�ַ���
      // ������ʾ
      Synchronize(procedure
        begin
          // ������ս��
          UpdateMessage(FMD5Hash);
        end);

      finally
      end;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
      // ������ʾ
      Synchronize(procedure
        begin
          UpdateMessage('�޷���ȡ�ļ���' + E.Message);
        end);
  end;


end;


procedure TMd5Thd.UpdateProgress(BytesRead: Int64; TotalBytes: Int64);
begin
  FProgressBar.Position := FProgressBar.Position + BytesRead;
end;

procedure TMd5Thd.UpdateMessage(Msg: string);
begin
  FMessageRichEdit.Lines.Add(Msg);
end;


end.
