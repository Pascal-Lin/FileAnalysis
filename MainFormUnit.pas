unit MainFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.IOUtils,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.ToolWin, Vcl.Buttons,
  System.Hash, IdHTTP,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, SyncObjs,
  Data.Bind.EngExt, Vcl.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs,
  Vcl.Bind.Editors, Data.Bind.Components, IdAuthentication,
  Winapi.ActiveX, Winapi.ShellAPI;

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
    CalculateMD5ToolButton: TToolButton;
    OptionToolButton: TToolButton;
    UpdateToolButton: TToolButton;
    AboutToolButton: TToolButton;
    UpdatePopupMenu: TPopupMenu;
    UpdateTrIDDBMenuItem: TMenuItem;
    N2: TMenuItem;
    MessageRichEdit: TRichEdit;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    OpenDialog1: TOpenDialog;
    ProgressBar: TProgressBar;
    AnalyzeToolButton: TToolButton;
    procedure OpenFileToolButtonClick(Sender: TObject);
    procedure CalculateMD5ToolButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure UpdateTrIDDBMenuItemClick(Sender: TObject);
    procedure WMDropFiles(var Message: TWMDropFiles); message WM_DROPFILES;
    procedure AnalyzeToolButtonClick(Sender: TObject);
    procedure N2Click(Sender: TObject);
  private
    { Private declarations }
    procedure AnalyzeFile;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses Analyze, TrIDLib, UpdateTrIDDefs, PascalLin.HTTP,
  PascalLin.Utils, CalculateMD5, Utils, Task, CheckVersion;

{$R *.dfm}

// 拖拽文件
// reference https://www.cnblogs.com/del/archive/2009/01/20/1379130.html
procedure TMainForm.WMDropFiles(var Message: TWMDropFiles);
var
  p: array [0 .. 255] of Char;
  i, count: Integer;
begin
  OpenDialog1.FileName := '';

  { 先获取拖拽的文件总数 }
  count := DragQueryFile(message.Drop, $FFFFFFFF, nil, 0);
  if count > 1 then
  begin
    MessageRichEdit.Lines.Add('Analyze > 不支持批量文件分析，请拖拽一个文件！');
  end
  else if count = 1 then
  begin
    DragQueryFile(message.Drop, 0, p, SizeOf(p));
    var
    FileName := GetLnkTarget(p);

    if TDirectory.Exists(FileName) then
    begin
      MessageRichEdit.Lines.Add('Analyze > 不能对文件夹进行分析！');
      Exit;
    end;

    if not TFile.Exists(FileName) then
    begin
      MessageRichEdit.Lines.Add('Analyze > 找不到文件 -> ' + FileName);
      Exit;
    end;


    // if FileGetAttr(FileName) = -1 then
    // begin
    // MessageRichEdit.Lines.Add('Analyze > 这不是一个有效的文件 -> ' + FileName);
    // Exit;
    // end;

    if MatchExt(FileName, '.url') then
    begin
      MessageRichEdit.Lines.Add('Analyze > 这不是一个有效的文件 -> ' + FileName);
      Exit;
    end;

    OpenDialog1.FileName := FileName;
    AnalyzeFile;

  end;

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
  MessageRichEdit.Lines.Add('TrID > 正在获取TrID数据库信息...');

  UpdateTrIDDefs.OnNotify := procedure(Msg: string)
    begin
      MessageRichEdit.Lines.Add('TrID > ' + Msg);
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
  // 接受拖拽
  DragAcceptFiles(Handle, True);

  Self.Caption := Self.Caption + ' ' + Utils.CurrentVersion;

  Wait(0,
    procedure
    begin
      TrIDLib.LoadDefsPack(ExtractFilePath(Paramstr(0)));
      // load the definitions package (TrIDDefs.TRD) from current path
      TrID_DB_Count := TrIDLib.GetInfo(TRID_GET_DEFSNUM, 0, sOut);
      // StatusBar1.Panels[0].Text := '当前TrID数据库含有 '+ TrID_DB_Count.ToString +' 个文件类型。'
      MessageRichEdit.Lines.Add('TrID > 当前TrID数据库含有 ' +
        TrID_DB_Count.ToString + ' 个文件类型。');
    end);

end;

procedure TMainForm.N2Click(Sender: TObject);
begin
  var
  CheckVersion := TCheckVersion.Create;
  CheckVersion.OnNotify := procedure(Msg: string)
    begin
      MessageRichEdit.Lines.Add('Version > ' + Msg);
    end;
  CheckVersion.Start;
  // CheckVersion.OnComplete
end;

// 这里不应将文件名作为参数，而是直接调用OpenDialog的FileName
// 如果以参数传入，在拖动文件的代码中可能忘记给OpenDialog赋值，使得按下MD5计算按钮的时候文件不一致。
procedure TMainForm.AnalyzeFile;
begin
  TrIDListView.Clear;
  var
  Analyze := TAnylyze.Create;
  Analyze.OnNotify := procedure(Msg: string)
    begin
      MessageRichEdit.Lines.Add('Analyze > ' + Msg);
    end;
  Analyze.OnFetchOne := procedure(Match, Ext, FileType, Pts: string)
    begin
      with TrIDListView.Items.Add do
      begin
        Caption := Match;
        SubItems.Add(Ext);
        SubItems.Add(FileType);
        SubItems.Add(Pts);
      end;
    end;
  Analyze.Start(OpenDialog1.FileName);

end;

procedure TMainForm.OpenFileToolButtonClick(Sender: TObject);
begin
  if OpenDialog1.execute then
  begin

    // if FileGetAttr(OpenDialog1.FileName) = -1 then
    // begin
    // MessageRichEdit.Lines.Add('Analyze > 找不到文件' + OpenDialog1.FileName);
    // exit;
    // end;

    if not TFile.Exists(OpenDialog1.FileName) then
    begin
      MessageRichEdit.Lines.Add('Analyze > 找不到文件' + OpenDialog1.FileName);
      OpenDialog1.FileName := '';
      Exit;
    end;

    // Analyze
    AnalyzeFile;
  end;
end;

procedure TMainForm.AnalyzeToolButtonClick(Sender: TObject);
begin
  if trim(OpenDialog1.FileName) = '' then
  begin
    MessageRichEdit.Lines.Add('Analyze > 请先打开或拖拽一个文件。');
    Exit;
  end;

  if not TFile.Exists(OpenDialog1.FileName) then
  begin
    MessageRichEdit.Lines.Add('Analyze > 找不到文件 -> ' + OpenDialog1.FileName);
    Exit;
  end;

  AnalyzeFile;
end;

procedure TMainForm.CalculateMD5ToolButtonClick(Sender: TObject);
begin
  if trim(OpenDialog1.FileName) = '' then
  begin
    MessageRichEdit.Lines.Add('MD5 > 请先打开或拖拽一个文件。');
    Exit;
  end;

  // if FileGetAttr(OpenDialog1.FileName) = -1 then
  // begin
  // MessageRichEdit.Lines.Add('MD5 > 找不到文件' + OpenDialog1.FileName);
  // exit;
  // end;

  if not TFile.Exists(OpenDialog1.FileName) then
  begin
    MessageRichEdit.Lines.Add('Analyze > 找不到文件 -> ' + OpenDialog1.FileName);
    Exit;
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

end;

end.
