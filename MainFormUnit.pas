unit MainFormUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Menus, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.ImageList, Vcl.ImgList, Vcl.ToolWin, Vcl.Buttons;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    ListViewTrIDResult: TListView;
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
    RichEdit1: TRichEdit;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    OpenDialog1: TOpenDialog;
    procedure OpenFileToolButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.OpenFileToolButtonClick(Sender: TObject);
begin
    if OpenDialog1.execute then
    begin

//      edit1.Text:=OpenDialog1.Filename;
      TrIDResultListView.Clear;
//      memo1.Lines.Text := HeadInfo + #13 + LineStr + langStr4 + LineStr;
//      if configfrm.CheckBox1.Checked then button2.Click;
    end;
end;

end.
