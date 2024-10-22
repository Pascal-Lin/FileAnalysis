unit MainFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.ToolWin, Vcl.Buttons,
  System.Hash, IdHTTP,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, SyncObjs,
  Data.Bind.EngExt, Vcl.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs,
  Vcl.Bind.Editors, Data.Bind.Components, IdAuthentication;

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    TrIDListView: TListView;
    Icon40ImageList: TImageList;
    MainMenu1: TMainMenu;
    F1: TMenuItem;
    O1: TMenuItem;
    N1: TMenuItem;
    X1: TMenuItem;
    Icon32ImageList: TImageList;
    ToolBar1: TToolBar;
    OpenFileToolButton: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    UpdatePopupMenu: TPopupMenu;
    UpdateTrIDDBMenuItem: TMenuItem;
    N2: TMenuItem;
    MessageRichEdit: TRichEdit;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    OpenDialog1: TOpenDialog;
    ProgressBar: TProgressBar;
    Button1: TButton;
    procedure OpenFileToolButtonClick(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure UpdateTrIDDBMenuItemClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses AnalyzeThd, TrIDLib, UpdateTrIDDefs, PascalLin.HTTP,
  PascalLin.Utils, CalculateMD5, Utils, Task;

// var
// Md5Thd: TMd5Thd;

{$R *.dfm}

procedure TMainForm.Button1Click(Sender: TObject);
begin
  ProgressBar.Position := 0;
  MessageRichEdit.Lines.Add('开始下载');

  if not Assigned(HTTP) then
  begin
    HTTP := THTTP.Create;
  end;

  HTTP.OnNotify := procedure(Msg: string)
    begin
      MessageRichEdit.Lines.Add(Msg);
    end;
  HTTP.OnWorkBegin := procedure(AWorkCountMax: Int64)
    begin
      ProgressBar.Position := 0;
      ProgressBar.Max := AWorkCountMax;
    end;
  HTTP.OnWork := procedure(AWorkCount: Int64)
    begin
      // MessageRichEdit.Lines.Add('AWorkCount    '+AWorkCount.ToString);
      ProgressBar.Position := AWorkCount;
    end;
  HTTP.OnComplete := procedure
    begin
      // 在子线程等待1秒钟，让进度条走满
      PascalLin.Utils.Wait(1000,
        procedure
        begin
          ProgressBar.Position := 0;
          MessageRichEdit.Lines.Add('下载完成');
        end);
    end;
  // HTTP.Get('https://mark0.net/soft-trid-e.html', html);

  var
  FileName := ExtractFilePath(Paramstr(0)) + 'triddefs.exe';
  HTTP.GetFile
    ('https://dldir1.qq.com/qqfile/qq/QQNT/Windows/QQ_9.9.15_241009_x64_01.exe',
    FileName);

  // HTTP.Get('https://mark0.net/download/triddefs.zip');

end;

procedure TMainForm.UpdateTrIDDBMenuItemClick(Sender: TObject);
begin
  if not(CurrentTask is TUpdateTrIDDefs) then
  begin
    // try
    CurrentTask.Free;
    // except
    // end;
    CurrentTask := TUpdateTrIDDefs.Create;
  end;

  var
  UpdateTrIDDefs := CurrentTask as TUpdateTrIDDefs;

  ProgressBar.Position := 0;
  MessageRichEdit.Lines.Add('Update TrID > 正在获取TrID数据库信息...');

  UpdateTrIDDefs.OnNotify := procedure(Msg: string)
    begin
      MessageRichEdit.Lines.Add('Update TrID > ' + Msg);
    end;
  UpdateTrIDDefs.OnWorkBegin := procedure(AWorkCountMax: Int64)
    begin
      ProgressBar.Position := 0;
      ProgressBar.Max := AWorkCountMax;
    end;
  UpdateTrIDDefs.OnWork := procedure(AWorkCount: Int64)
    begin
      ProgressBar.Position := AWorkCount;
    end;
  UpdateTrIDDefs.OnComplete := procedure
    begin
      // 在子线程等待进度条走满
      PascalLin.Utils.Wait(1000,
        procedure
        begin
          ProgressBar.Position := 0;
        end);
    end;
  UpdateTrIDDefs.Start;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  TrID_DB_Count: Integer;
  sOut: string;
begin
  TrIDLib.LoadDefsPack(ExtractFilePath(Paramstr(0)));
  // load the definitions package (TrIDDefs.TRD) from current path
  TrID_DB_Count := TrIDLib.GetInfo(TRID_GET_DEFSNUM, 0, sOut);
  // StatusBar1.Panels[0].Text := '当前TrID数据库含有 '+ TrID_DB_Count.ToString +' 个文件类型。'
  MessageRichEdit.Lines.Add('当前TrID数据库含有 ' + TrID_DB_Count.ToString + ' 个文件类型。')
end;

procedure TMainForm.OpenFileToolButtonClick(Sender: TObject);
begin
  if OpenDialog1.execute then
  begin

    if FileGetAttr(OpenDialog1.FileName) = -1 then
    begin
      ShowMessage('Open > 找不到文件' + OpenDialog1.FileName);
      exit;
    end;

    MessageRichEdit.Clear;
    TrIDListView.Clear;

    // 创建文件分析线程
    TAnalyzeThd.Create(OpenDialog1.FileName, MessageRichEdit, TrIDListView);

    // memo1.Lines.Text := HeadInfo + #13 + LineStr + langStr4 + LineStr;
    // if configfrm.CheckBox1.Checked then button2.Click;
  end;
end;

procedure TMainForm.ToolButton2Click(Sender: TObject);
begin
  if trim(OpenDialog1.FileName) = '' then
  begin
//    ShowMessage('请先打开一个文件！');
    MessageRichEdit.Lines.Add('MD5 > 需要先打开一个文件再进行MD5计算。');
    exit;
  end;

  if FileGetAttr(OpenDialog1.FileName) = -1 then
  begin
//    ShowMessage('找不到文件' + OpenDialog1.FileName);
    MessageRichEdit.Lines.Add('MD5 > 找不到文件' + OpenDialog1.FileName);
    exit;
  end;

  if not(CurrentTask is TCalculateMD5) then
  begin
    // try
    CurrentTask.Free;
    // except
    // end;
    CurrentTask := TCalculateMD5.Create;
  end;

  var
  CalculateMD5 := CurrentTask as TCalculateMD5;

  CalculateMD5.OnReady := procedure(AWorkCountMax: Int64)
    begin
      MessageRichEdit.Lines.Add('MD5 > 正在计算MD5码...');
      ProgressBar.Position := 0;
      ProgressBar.Max := AWorkCountMax;
    end;

  CalculateMD5.OnProgress := procedure(AWorkCount: Int64)
    begin
      // MessageRichEdit.Lines.Add(AWorkCount.ToString);
      ProgressBar.Position := AWorkCount;
    end;

  CalculateMD5.OnNotify := procedure(Msg: string)
    begin
      MessageRichEdit.Lines.Add('MD5 > ' + Msg);
    end;

  CalculateMD5.OnComplete := procedure(MD5Str: string)
    begin

      Wait(1000,
        procedure
        begin
          ProgressBar.Position := 0;
          MessageRichEdit.Lines.Add('MD5 > ' + MD5Str);
        end);

    end;

  CalculateMD5.Calculate(OpenDialog1.FileName);

  // if Assigned(Md5Thd) then
  // begin
  // if GetExitCodeThread(Md5Thd.Handle, DWORD(ExitCode)) then
  // begin
  // TerminateThread(Md5Thd.Handle, 0);
  // Md5Thd.Free;
  // end;
  // end;
  //
  // Md5Thd := TMd5Thd.Create(OpenDialog1.FileName, MessageRichEdit, ProgressBar);
  end;

  end.
