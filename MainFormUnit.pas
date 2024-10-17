unit MainFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.ToolWin, Vcl.Buttons, System.Hash;

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
    U1: TMenuItem;
    N2: TMenuItem;
    MessageRichEdit: TRichEdit;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    OpenDialog1: TOpenDialog;
    MD5ProgressBar: TProgressBar;
    procedure OpenFileToolButtonClick(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
    procedure StatusBar1DrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel;
      const Rect: TRect);
    procedure FormCreate(Sender: TObject);
  private
    ProgressBar: TProgressBar;
    ProgressBarRect: TRect;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;


implementation

uses AnalyzeThd, Md5Thd, TrIDLib;

var
  Md5Thd : TMd5Thd;

{$R *.dfm}




procedure TMainForm.FormCreate(Sender: TObject);
var
  TrID_DB_Count: Integer;
  sOut: string;
begin
  TrIDLib.LoadDefsPack(ExtractFilePath(Paramstr(0)));   // load the definitions package (TrIDDefs.TRD) from current path
  TrID_DB_Count := TrIDLib.GetInfo(TRID_GET_DEFSNUM, 0, sOut);
//  StatusBar1.Panels[0].Text := '当前TrID数据库含有 '+ TrID_DB_Count.ToString +' 个文件类型。'
  MessageRichEdit.Lines.Add('当前TrID数据库含有 '+ TrID_DB_Count.ToString +' 个文件类型。')
end;

procedure TMainForm.OpenFileToolButtonClick(Sender: TObject);
begin
    if OpenDialog1.execute then
    begin

      if FileGetAttr(OpenDialog1.FileName) = -1 then
      begin
        ShowMessage('找不到文件' + OpenDialog1.FileName);
        exit;
      end;

      MessageRichEdit.Clear;
      TrIDListView.Clear;

      // 创建文件分析线程
      TAnalyzeThd.Create(OpenDialog1.FileName, MessageRichEdit, TrIDListView);

//      memo1.Lines.Text := HeadInfo + #13 + LineStr + langStr4 + LineStr;
//      if configfrm.CheckBox1.Checked then button2.Click;
    end;
end;

procedure TMainForm.StatusBar1DrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel;
  const Rect: TRect);
begin

if Panel = StatusBar.Panels[1] then
  ProgressBarRect := Rect;
end;

procedure TMainForm.ToolButton2Click(Sender: TObject);
begin
  if trim(OpenDialog1.FileName) = '' then
  begin
    ShowMessage('请先打开一个文件！');
    exit;
  end;

  if FileGetAttr(OpenDialog1.FileName) = -1 then
  begin
    ShowMessage('找不到文件' + OpenDialog1.FileName);
    exit;
  end;

  if Assigned(Md5Thd) then
  begin
    if GetExitCodeThread(Md5Thd.Handle, DWORD(ExitCode)) then
    begin
      TerminateThread(Md5Thd.Handle,0);
      Md5Thd.Free;
    end;
  end;

  Md5Thd := TMd5Thd.Create(OpenDialog1.FileName, MessageRichEdit, MD5ProgressBar);
end;



end.
