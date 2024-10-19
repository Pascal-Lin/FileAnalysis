unit MainFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.ToolWin, Vcl.Buttons, System.Hash, IdHTTP,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, SyncObjs,
  Data.Bind.EngExt, Vcl.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs,
  Vcl.Bind.Editors, Data.Bind.Components;

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
    procedure OpenFileToolButtonClick(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure UpdateTrIDDBMenuItemClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;


implementation

uses AnalyzeThd, Md5Thd, TrIDLib, UpdateTrIDDefs;

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

  Md5Thd := TMd5Thd.Create(OpenDialog1.FileName, MessageRichEdit, ProgressBar);
end;



procedure TMainForm.UpdateTrIDDBMenuItemClick(Sender: TObject);
var
  RemoteTrIDDBCount: Integer;
  UpdateTrIDDefs: TUpdateTrIDDefs;
begin
  MessageRichEdit.Lines.Add('正在获取远程数据库信息...');

  UpdateTrIDDefs := TUpdateTrIDDefs.Create;
  // 检查
  UpdateTrIDDefs.CheckTrIDDefs(
    {这是匿名函数做第一个参数}
    procedure(AWorkCount, AWorkCountMax: Int64)
    begin
      // 这里处理更新过程中的进度条显示
      ProgressBar.Max := AWorkCountMax;
      ProgressBar.Position := AWorkCount;
//      MessageRichEdit.Lines.Add(AWorkCount.ToString+' / '+AWorkCountMax.ToString);
    end,

    {这是匿名函数做第二个参数}
    procedure
    begin
      // 这里处理更新的逻辑


      // 在这里更新进度条，否则每个IF都要更新
      // 进度条还没跑满就会归零，取消smooth属性也不行
      // 临时解决方案：
      // 1·在子线程回调之前Sleep(1000)
      // 2·让进度条初始进度为100%
      ProgressBar.Position := 0;

      var RemoteTrIDDefsNum: Integer;
      if not TryStrToInt(UpdateTrIDDefs.TRIDDEFSNUM, RemoteTrIDDefsNum) then
      begin
        // TODO 给RichEdit编写通用方法，并支持高亮
        MessageRichEdit.Lines.Add('获取远程TrID数据库信息失败！此次更新中止！');
        Exit;
      end;



      // FIXME 在子线程里读取TrIDDefs
      var LocalTrIDDefsNum: Integer;
      var sOut: string;
      TrIDLib.LoadDefsPack(ExtractFilePath(Paramstr(0)));   // load the definitions package (TrIDDefs.TRD) from current path
      LocalTrIDDefsNum := TrIDLib.GetInfo(TRID_GET_DEFSNUM, 0, sOut);


      // 比对数据库
      if (RemoteTrIDDefsNum < LocalTrIDDefsNum) then
      begin
        MessageRichEdit.Lines.Add('你使用的TrID数据库可能来自于未来！作者感觉压力太大，有点害怕此次更新。');
        Exit;
      end;

      if (RemoteTrIDDefsNum = LocalTrIDDefsNum) then
      begin
        MessageRichEdit.Lines.Add('当前TrID数据库已经是最新的，不需要更新！');
        Exit;
      end;

      // 有更新
      var Msg := '找到最新的TrID数据库：发布于' + UpdateTrIDDefs.FILEDATE + '，包含' + RemoteTrIDDefsNum.ToString + '个文件类型数据。';
      MessageRichEdit.Lines.Add(Msg);
      MessageRichEdit.Lines.Add('开始下载TrID数据库...');

      // 下载数据库文件
      UpdateTrIDDefs.DownloadTrIDDefs(
        procedure(AWorkCount, AWorkCountMax: Int64)
        begin
          // 这里处理更新过程中的进度条显示

//          if ProgressBar.Max <> AWorkCountMax then
          begin
            ProgressBar.Max := AWorkCountMax;
          end;

          ProgressBar.Position := AWorkCount;
//          MessageRichEdit.Lines.Add(AWorkCount.ToString+' / '+AWorkCountMax.ToString);
        end,
        procedure
        begin
          MessageRichEdit.Lines.Add('TrID数据库更新完成！');

          // 进度条还没跑满就会归零，取消smooth属性也不行
          // 临时解决方案：
          // 1·在子线程回调之前Sleep(1000)
          // 2·让进度条初始进度为100%
          ProgressBar.Position := 0;

        end
      );
    end
  );

end;


end.


