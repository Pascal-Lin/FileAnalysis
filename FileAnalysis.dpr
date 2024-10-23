program FileAnalysis;

uses
  Winapi.Windows,
  Winapi.Messages,
  Vcl.Dialogs,
  Vcl.Forms,
  MainFormUnit in 'MainFormUnit.pas' {MainForm} ,
  TrIDLib in 'TrIDLib.pas',
  PascalLin.HTTP in 'PascalLin\PascalLin.HTTP.pas',
  PascalLin.Utils in 'PascalLin\PascalLin.Utils.pas',
  Utils in 'Utils.pas',
  Task in 'Task.pas',
  CalculateMD5 in 'CalculateMD5.pas',
  PascalLin.MD5 in 'PascalLin\PascalLin.MD5.pas',
  Analyze in 'Analyze.pas',
  UpdateTrIDDefs in 'UpdateTrIDDefs.pas',
  CheckVersion in 'CheckVersion.pas';

{$R *.res}

var
  H: Hwnd;
  L: word;

const
  iAtom = 'FileAnalysis'; // 全局原子，防止多开关键字

begin

  // Application.Initialize;
  // Application.MainFormOnTaskbar := True;
  // Application.CreateForm(TMainForm, MainForm);
  // Application.Run;

  if GlobalFindAtom(iAtom) = 0 then
  begin
    GlobalAddAtom(iAtom);
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TMainForm, MainForm);
    Application.Run;
    GlobalDeleteAtom(GlobalFindAtom(iAtom));
  end
  else
  begin
    // 传递二次启动时的参数到第一个实例
    H := FindWindow(PChar('TMainForm'), MainFormCapiton);
    if ParamCount > 0 then
    begin
      L := GlobalAddAtom(PChar(ParamStr(1)));
      if H <> 0 then
      begin
        { 传递原子句柄 }
        SendMessage(H, WM_MESSAGE_FILE, 0, L);
      end;
      GlobalDeleteAtom(L); { 使用后释放 }
    end;
    Application.Terminate;
  end;

end.
