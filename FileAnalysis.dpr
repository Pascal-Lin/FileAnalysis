program FileAnalysis;

uses
  Vcl.Forms,
  MainFormUnit in 'MainFormUnit.pas' {MainForm},
  TrIDLib in 'TrIDLib.pas',
  PascalLin.HTTP in 'PascalLin\PascalLin.HTTP.pas',
  PascalLin.Utils in 'PascalLin\PascalLin.Utils.pas',
  Utils in 'Utils.pas',
  Task in 'Task.pas',
  CalculateMD5 in 'CalculateMD5.pas',
  PascalLin.MD5 in 'PascalLin\PascalLin.MD5.pas',
  Analyze in 'Analyze.pas',
  UpdateTrIDDefs in 'UpdateTrIDDefs.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
