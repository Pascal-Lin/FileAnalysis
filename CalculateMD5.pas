unit CalculateMD5;

interface

uses
  Task, PascalLin.MD5;

type
  TCalculateMD5 = class(TTask)
  protected
    MD5: TMD5;
  public
    OnReady: TMD5ReadyEvent;
    OnProgress: TMD5ProgressEvent;
    OnNotify: TMD5NotifyEvent;
    OnComplete: TMD5CompleteEvent;
    procedure Calculate(FileName: string);
    destructor Destroy; override;
  end;

implementation

destructor TCalculateMD5.Destroy;
begin
  MD5.OnReady := nil;
  MD5.OnProgress := nil;
  MD5.OnComplete := nil;
  MD5.OnNotify := nil;
  MD5.Destroy;
  inherited Destroy;
end;

procedure TCalculateMD5.Calculate(FileName: string);
begin

  if Assigned(MD5) then
  begin
    MD5.OnReady := nil;
    MD5.OnProgress := nil;
    // FIXME
    // 这里即使MD5.OnComplete := nil;
    // 在MD5匿名线程中仍然不为nil
    MD5.OnComplete := nil;
    MD5.OnNotify := nil;
    MD5.Free;
    MD5 := nil;
  end;

  MD5 := TMD5.Create;
  MD5.OnReady := OnReady;
  MD5.OnProgress := OnProgress;
  MD5.OnComplete := OnComplete;
  MD5.OnNotify := OnNotify;

  MD5.Calculate(FileName);
end;

end.
