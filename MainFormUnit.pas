unit MainFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.ToolWin, Vcl.Buttons, System.Hash;

type
  TForm1 = class(TForm)
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
    ProgressBar1: TProgressBar;
    procedure OpenFileToolButtonClick(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
  private
    { Private declarations }
    procedure AnalyzeFile(FileName: string);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


implementation

uses AnalyzeThd, Md5Thd;

var
  Md5Thd : TMd5Thd;

{$R *.dfm}

procedure TForm1.AnalyzeFile(FileName: string);
var
  Attr:integer;
  ExitCode : cardinal;
//  AnalyzeThread : TAnalyzeThd;
begin

  if trim(FileName) = '' then
  begin
    ShowMessage('ָ���ļ�����Ϊ�գ�');
    exit;
  end;

  if FileGetAttr(FileName) = -1 then
  begin
    ShowMessage('�Ҳ����ļ�'+FileName.QuotedString+'��');
    exit;
  end;

//  cxTreeList1.Clear;
//  Memo1.Lines.Clear;
//  CopyMD5MenuItem.Enabled := false;
//  mainFrm.cxTreeList1.Bands[0].Caption.text := BandsText+LangStr0;
//  TAnalyzeThd.Create(FileName);

//  if Assigned(Md5Thd) then
//  begin
//    if GetExitCodeThread(Md5Thd.Handle, ExitCode) then
//    begin
//      TerminateThread(Md5Thd.Handle,0);
//      Md5Thd.Free;
//    end;
//  end;
//  if ConfigFrm.CheckBox4.Checked then Md5Thd := TMd5Thd.Create(GetShortName(edit1.Text));
end;

procedure TForm1.OpenFileToolButtonClick(Sender: TObject);
begin
    if OpenDialog1.execute then
    begin

      if FileGetAttr(OpenDialog1.FileName) = -1 then
      begin
        ShowMessage('�Ҳ����ļ�' + OpenDialog1.FileName);
        exit;
      end;

      MessageRichEdit.Clear;
      TrIDListView.Clear;

      // �����ļ������߳�
      TAnalyzeThd.Create(OpenDialog1.FileName, MessageRichEdit, TrIDListView);

//      memo1.Lines.Text := HeadInfo + #13 + LineStr + langStr4 + LineStr;
//      if configfrm.CheckBox1.Checked then button2.Click;
    end;
end;

procedure TForm1.ToolButton2Click(Sender: TObject);
begin
  if trim(OpenDialog1.FileName) = '' then
  begin
    ShowMessage('���ȴ�һ���ļ���');
    exit;
  end;

  if FileGetAttr(OpenDialog1.FileName) = -1 then
  begin
    ShowMessage('�Ҳ����ļ�' + OpenDialog1.FileName);
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
  Md5Thd := TMd5Thd.Create(OpenDialog1.FileName, MessageRichEdit, ProgressBar1);
end;



end.
