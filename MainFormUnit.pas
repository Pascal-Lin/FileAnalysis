unit MainFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.IOUtils, System.Hash,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.ToolWin, Vcl.Buttons,
  Vcl.ClipBrd, IdHTTP, Registry,
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
    CheckVersionMenuItem: TMenuItem;
    MessageRichEdit: TRichEdit;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    OpenDialog1: TOpenDialog;
    ProgressBar: TProgressBar;
    AnalyzeToolButton: TToolButton;
    RichEditPopupMenu: TPopupMenu;
    CopyTextMenuItem: TMenuItem;
    CopyMD5MenuItem: TMenuItem;
    OptionPopupMenu: TPopupMenu;
    RegRightButtonMenuItem: TMenuItem;
    ClearRichEditMenuItem: TMenuItem;
    N3: TMenuItem;
    procedure OpenFileToolButtonClick(Sender: TObject);
    procedure CalculateMD5ToolButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure UpdateTrIDDBMenuItemClick(Sender: TObject);
    procedure WMDropFiles(var Message: TWMDropFiles); message WM_DROPFILES;
    procedure AnalyzeToolButtonClick(Sender: TObject);
    procedure CheckVersionMenuItemClick(Sender: TObject);
    procedure CopyMD5MenuItemClick(Sender: TObject);
    procedure CopyTextMenuItemClick(Sender: TObject);
    procedure AboutToolButtonClick(Sender: TObject);
    procedure RegRightButtonMenuItemClick(Sender: TObject);
    procedure OptionPopupMenuPopup(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ClearRichEditMenuItemClick(Sender: TObject);
  private
    { Private declarations }
    procedure AnalyzeFile;
  public
    { Public declarations }
    procedure WndProc(var Message: TMessage); override;
  end;

var
  MainForm: TMainForm;

implementation

uses Analyze, TrIDLib, UpdateTrIDDefs, PascalLin.HTTP,
  PascalLin.Utils, CalculateMD5, Utils, Task, CheckVersion;

{$R *.dfm}

// 接收第二实例传递过来的参数
procedure TMainForm.WndProc(var Message: TMessage);
var
  FileMessage: Array [0 .. 255] of char;
begin
  case Message.Msg of
    WM_MESSAGE_FILE:
      begin
        GlobalGetAtomName(Message.LParam, FileMessage, 255); { 接受数据到p数组中 }
        if trim(FileMessage) <> '' then
        begin
          OpenDialog1.FileName := FileMessage;
          AnalyzeFile;
        end;
      end;
  end;
  inherited WndProc(Message);
end;

// 拖拽文件
// reference https://www.cnblogs.com/del/archive/2009/01/20/1379130.html
procedure TMainForm.WMDropFiles(var Message: TWMDropFiles);
var
  p: array [0 .. 255] of char;
  count: Integer;
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
begin
  // 接受拖拽
  DragAcceptFiles(Handle, True);

  Self.Caption := MainFormCapiton;

end;

procedure TMainForm.FormShow(Sender: TObject);
var
  TrID_DB_Count: Integer;
  sOut: string;
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      TrIDLib.LoadDefsPack(ExtractFilePath(Paramstr(0)));
      // load the definitions package (TrIDDefs.TRD) from current path
      TrID_DB_Count := TrIDLib.GetInfo(TRID_GET_DEFSNUM, 0, sOut);

      TThread.Synchronize(nil,
        procedure
        begin
          MessageRichEdit.Lines.Add('FileAnalysis > 当前TrID数据库含有 ' +
            TrID_DB_Count.ToString + ' 个文件类型。');
          if ParamCount > 0 then
          begin
            OpenDialog1.FileName := Paramstr(1);
            // 通过右键打开文件，好像都是有效文件，不需要过滤了
            AnalyzeFile;
          end;
        end);
    end).Start; // 启动匿名线程

end;

procedure TMainForm.CheckVersionMenuItemClick(Sender: TObject);
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

procedure TMainForm.ClearRichEditMenuItemClick(Sender: TObject);
begin
  MessageRichEdit.Clear;
end;

procedure TMainForm.RegRightButtonMenuItemClick(Sender: TObject);
var
  Reg: TRegistry;
begin
  // 如果没有权限则提示并执行重启
  if not IsRunAsAdmin then
  begin
    if ID_YES = Application.MessageBox
      (PChar('修改此选项需要管理员权限！' + #13 + '是否以管理员身份重启FileAnalysis？'), PChar('提示'),
      MB_YESNO + MB_SYSTEMMODAL) then
    begin
      RestartAsAdmin;
      Application.Terminate;
    end;
    Exit;
  end;

  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CLASSES_ROOT;
  try
    if TMenuItem(Sender).Checked then
    begin
      Reg.DeleteKey('*\shell\FileAnalyze');
      MessageRichEdit.Lines.Add('FileAnalysis > 文件右键菜单已取消关联。');
      // Checked会在Popup弹出的时候自动检测注册表来赋值
      // TMenuItem(Sender).Checked := not TMenuItem(Sender).Checked;
    end
    else
    begin
      if Reg.OpenKey('*\shell\FileAnalyze', True) then
      begin
        Reg.WriteString('MUIVerb', '使用FileAnalysis打开');
        if Reg.OpenKey('command', True) then
        begin
          Reg.WriteString('', '"' + Paramstr(0) + '" "%1"');
          Reg.CloseKey;
          MessageRichEdit.Lines.Add('FileAnalysis > 文件右键菜单已关联。');
        end;
        Reg.CloseKey;
      end;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TMainForm.AboutToolButtonClick(Sender: TObject);
begin
  MessageRichEdit.SelAttributes.Color := clBlue;
  MessageRichEdit.Lines.Add('FileAnalysis >');
  MessageRichEdit.SelAttributes.Color := clBlue;
  MessageRichEdit.Lines.Add(#9 + 'FileAnalysis是一个基于TrID项目的GUI开源程序。');
  MessageRichEdit.SelAttributes.Color := clBlue;
  MessageRichEdit.Lines.Add(#9 + 'FileAnalysis Github：' + #13#9#9 + GithubURL);
  MessageRichEdit.SelAttributes.Color := clBlue;
  MessageRichEdit.Lines.Add(#9 + 'FTrID是一个识别文件类型的公益项目，如果你有兴趣可以加入TrID社区。');
  MessageRichEdit.SelAttributes.Color := clBlue;
  MessageRichEdit.Lines.Add(#9 + 'FTrID官网：' + #13#9#9 + TrIDWebSite);
end;

procedure TMainForm.AnalyzeFile;
// 这里不应将文件名作为参数，而是直接调用OpenDialog的FileName
// 如果以参数传入，在拖动文件的代码中可能忘记给OpenDialog赋值，使得按下MD5计算按钮的时候文件不一致。
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

procedure TMainForm.OptionPopupMenuPopup(Sender: TObject);
var
  Reg: TRegistry;
begin
  RegRightButtonMenuItem.Checked := False;

  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CLASSES_ROOT;
    // 使用OpenKeyReadOnly不需要管理员权限
    if Reg.OpenKeyReadOnly('*\shell\FileAnalyze') then
    begin
      // *\shell\FileAnalyze下至少有个默认项，是可以生效的，所以不用判断Reg.ValueExists('MUIVerb')
      // if Reg.ValueExists('MUIVerb') then
      if Reg.OpenKeyReadOnly('command') then
      begin
        var
        value := Reg.ReadString('');
        if (value = '"' + Paramstr(0) + '" "%1"') then
        begin
          // 检测到已注册了右键，打上勾
          RegRightButtonMenuItem.Checked := True;
        end;
        Reg.CloseKey;
      end;
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
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

procedure TMainForm.CopyTextMenuItemClick(Sender: TObject);
begin
  Clipboard.AsText := MessageRichEdit.SelText;
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

          CopyMD5MenuItem.Caption := '复制 ' + MD5Str;
          CopyMD5MenuItem.Hint := MD5Str;
          CopyMD5MenuItem.Visible := True;
        end);

    end;

  CalculateMD5.Calculate(OpenDialog1.FileName);

end;

procedure TMainForm.CopyMD5MenuItemClick(Sender: TObject);
begin
  Clipboard.AsText := TMenuItem(Sender).Hint;
end;

end.
