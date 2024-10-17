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
    procedure UpdateShow;
    function GetFileSize(const FileName: String): LongInt;
    { Private declarations }
  protected
    procedure Execute; override;
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
  inherited Create(false);  //创建后立即执行execute函数
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
  // TODO Synchronize
//  MessageRichEdit.Lines.Add('FileAnalysis 准备就绪');
//  MessageRichEdit.Add(datetimetostr(now));
//  MessageRichEdit.Lines.Add('');
  AllPoint := 0;
  MessageRichEdit.Lines.Add('正在检测TrID数据库...');
  TrIDLib.LoadDefsPack(ExtractFilePath(Paramstr(0)));   // load the definitions package (TrIDDefs.TRD) from current path
  TrID_DB_Count := TrIDLib.GetInfo(TRID_GET_DEFSNUM, 0, sOut);
  MessageRichEdit.Lines.Add('找到共计 '+ TrID_DB_Count.ToString +' 个文件类型。');

  MessageRichEdit.Lines.Add('准备分析目标文件：' + FileName + '');
  TrIDLib.SubmitFileA(FileName); // submit the file

  MessageRichEdit.Lines.Add('正在匹配TrID数据库...');
  ret := TrIDLib.TrID_Analyze();     // perform the analysis

  if ret <> 0 then
  begin
    ResNum := TrIDLib.GetInfo(TRID_GET_RES_NUM, 0, sOut);           // get the number of results
    if ResNum = 0 then
    begin
      MessageRichEdit.Lines.Add('');
      MessageRichEdit.Lines.Add('该文件在数据库中匹配不到相关信息，建议以下操作：');
      MessageRichEdit.Lines.Add('1.用文本编辑器查看该文件。');
      MessageRichEdit.Lines.Add('2.更新到最新的TrID数据库。');

      if (GetFileSize(FileName) div 1024 > 1024) then
      begin
        // 文件超过1M，不建议用记事本打开
        Application.MessageBox(PChar('该文件在数据库中匹配不到相关信息，建议以下操作：' + #13
            + '1.更新到最新的TrID数据库。'),
            PChar('提示'),
            MB_OK);
      end else begin
        //是否用记事本打开
        if ID_YES = Application.MessageBox(PChar('该文件在数据库中匹配不到相关信息，建议以下操作：' + #13
              + '1.用文本编辑器查看该文件。' + #13
              + '2.更新到最新的TrID数据库。' + #13
              + '是否用记事本打开这个文件进行查看？'),
              PChar('提示'),
              MB_YESNO + MB_SYSTEMMODAL) then
        begin
          ShellExecute(0,nil, PChar('notepad.exe'), PChar(FileName), nil,SW_NORMAL);
        end;
      end;

    end else
    begin
      MessageRichEdit.Lines.Add('匹配到 ' + ResNum.ToString + ' 个类型，开始导出结果到表格...');

//    （可选）控制显示数量
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
    MessageRichEdit.Lines.Add('分析完成。');
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
