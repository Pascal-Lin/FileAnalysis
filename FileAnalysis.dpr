program FileAnalysis;

uses
  Vcl.Forms,
  MainFormUnit in 'MainFormUnit.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles,
  AnalyzeThd in 'AnalyzeThd.pas',
  TrIDLib in 'TrIDLib.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
