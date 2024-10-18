program FileAnalysis;

uses
  Vcl.Forms,
  MainFormUnit in 'MainFormUnit.pas' {MainForm},
  Vcl.Themes,
  Vcl.Styles,
  AnalyzeThd in 'AnalyzeThd.pas',
  TrIDLib in 'TrIDLib.pas',
  Md5Thd in 'Md5Thd.pas',
  UpdateTrIDDefs in 'UpdateTrIDDefs.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
