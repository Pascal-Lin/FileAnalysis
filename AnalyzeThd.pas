unit AnalyzeThd;

interface

uses
  Classes,SysUtils,Math,Dialogs,Windows,Forms,Shellapi, Vcl.ComCtrls;

type
  TAnalyzeThd = class(TThread)
  private
    FileName: string;
    MessageRichEdit: TRichEdit;
    TrIDListView: TListView;
//    procedure WriteLog;
    procedure UpdateShow;
    function GetFileSize(const FileName: String): LongInt;
    { Private declarations }
  protected
    procedure Execute; override;
//    procedure LogClear;
  public
    constructor Create(FileName: string; MessageRichEdit: TRichEdit; TrIDListView: TListView);
  end;


implementation

uses TrIDLib;

constructor TAnalyzeThd.Create(FileName: string; MessageRichEdit: TRichEdit; TrIDListView: TListView);
begin
  Self.FileName := FileName;
  Self.MessageRichEdit := MessageRichEdit;
  Self.TrIDListView := TrIDListView;

  FreeOnTerminate := True;
  inherited Create(false);  //����������ִ��execute����
end;

procedure TAnalyzeThd.Execute;
begin
  Synchronize(UpdateShow);
end;

procedure TAnalyzeThd.UpdateShow;
var
  ret, ResNum, resId: longint;
  sOut: string;
  AllPoint:integer;
  TrID_DB_Count: Integer;
begin

//  MessageRichEdit.Lines.Add('FileAnalysis ׼������');
//  MessageRichEdit.Add(datetimetostr(now));
//  MessageRichEdit.Lines.Add('');
  AllPoint := 0;
  MessageRichEdit.Lines.Add('�������ݿ�...');
  TrIDLib.LoadDefsPack(ExtractFilePath(Paramstr(0)));   // load the definitions package (TrIDDefs.TRD) from current path
  TrID_DB_Count := TrIDLib.GetInfo(TRID_GET_DEFSNUM, 0, sOut);
  MessageRichEdit.Lines.Add('�ҵ��ļ������ܼƣ�' + IntToStr(TrID_DB_Count));

  MessageRichEdit.Lines.Add('׼������Ŀ���ļ���' + FileName + '');
  TrIDLib.SubmitFileA(FileName); // submit the file

  MessageRichEdit.Lines.Add('����ƥ��TrID���ݿ�...');
  ret := TrIDLib.TrID_Analyze();     // perform the analysis

  if ret <> 0 then
  begin
    ResNum := TrIDLib.GetInfo(TRID_GET_RES_NUM, 0, sOut);           // get the number of results
    if ResNum = 0 then
    begin
      MessageRichEdit.Lines.Add('');
      MessageRichEdit.Lines.Add('���ļ������ݿ���ƥ�䲻�������Ϣ���������²�����');
      MessageRichEdit.Lines.Add('1.���ı��༭���鿴���ļ���');
      MessageRichEdit.Lines.Add('2.���µ����µ�TrID���ݿ⡣');

      if (GetFileSize(FileName) div 1024 > 1024) then
      begin
        // �ļ�����1M���������ü��±���
        Application.MessageBox(PChar('���ļ������ݿ���ƥ�䲻�������Ϣ���������²�����' + #13
            + '1.���µ����µ�TrID���ݿ⡣'),
            PChar('��ʾ'),
            MB_OK);
      end else begin
        //�Ƿ��ü��±���
        if ID_YES = Application.MessageBox(PChar('���ļ������ݿ���ƥ�䲻�������Ϣ���������²�����' + #13
              + '1.���ı��༭���鿴���ļ���' + #13
              + '2.���µ����µ�TrID���ݿ⡣' + #13
              + '�Ƿ��ü��±�������ļ����в鿴��'),
              PChar('��ʾ'),
              MB_YESNO + MB_SYSTEMMODAL) then
        begin
          ShellExecute(0,nil, PChar('notepad.exe'), PChar(FileName), nil,SW_NORMAL);
        end;
      end;

    end else
    begin
      MessageRichEdit.Lines.Add('ƥ�䵽 ' + ResNum.ToString + ' �����ͣ���ʼ������������...');

//    ����ѡ��������ʾ����
//      if strtoint(ConfigFrm.Edit1.Text) < ResNum then ResNum := strtoint(ConfigFrm.Edit1.Text);


      // firt loop caculate sum of point
      for ResId := 1 to ResNum do
      begin
        AllPoint := AllPoint + TrIDLib.GetInfo(TRID_GET_RES_POINTS, ResId, sOut);   // get filetype extension
      end;

      // second loop output caculate percent of each type
      for ResId := 1 to ResNum do  // cycle trough the results
      begin
        with TrIDListView.Items.add do
        begin
        ret := TrIDLib.GetInfo(TRID_GET_RES_POINTS, ResId, sOut);   // Matching points
        Caption := format('%6s',[format('%.1f%%',[ret*100.0/AllPoint])]);
        TrIDLib.GetInfo(TRID_GET_RES_FILEEXT, ResId, sOut);  // get filetype extension
        SubItems.Add(sOut);
        TrIDLib.GetInfo(TRID_GET_RES_FILETYPE, ResId, sOut); // get filetype descriptions
        SubItems.Add(sOut);
        SubItems.Add(IntToStr(ret));
//        MessageRichEdit.Lines.Add(Caption +' (.'+SubItems[0]+') '+SubItems[1]+' ['+SubItems[2]+']');
        end;

      end;

    end;
    MessageRichEdit.Lines.Add('������ɡ�');
//    if ConfigFrm.Checkbox2.Checked then WriteLog;
  end;


end;

function TAnalyzeThd.GetFileSize(const FileName: String): LongInt;
var
  SearchRec: TSearchRec;
begin
  if FindFirst(ExpandFileName(FileName), faAnyFile, SearchRec) = 0 then
    Result := SearchRec.Size
  else
    Result := -1;
end;

end.
