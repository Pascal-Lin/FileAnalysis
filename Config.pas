{
  文件配置读写
  使用静态变量和静态方法，无需实例化，直接使用类名调用即可。
}


unit Config;

interface

uses
  System.IniFiles, System.SysUtils;

type
  TConfig = class
  public
    class var OnTop: Boolean;
    class procedure Load; // 只需要在启动时调用一次，读取配置保存在静态变量中
    class procedure Save; // 每次改写静态变量后手动执行一次Save保存到文件
  end;

implementation

// 每次改写静态变量后手动执行一次Save保存到文件
class procedure TConfig.Save;
begin
  var
  FileName := ExtractFilePath(Paramstr(0)) + 'config.ini';
  var
  IniFile := TIniFile.Create(FileName);
  try
    IniFile.WriteBool('Common', 'OnTop', OnTop);
  finally
    IniFile.Free; // 释放资源
  end;
end;

// 只需要在启动时调用一次，读取配置保存在静态变量中
class procedure TConfig.Load;
begin
  var
  FileName := ExtractFilePath(Paramstr(0)) + 'config.ini';
  var
  IniFile := TIniFile.Create(FileName);
  try
    OnTop := IniFile.ReadBool('Common', 'OnTop', True); // 如果没有找到，返回 True
  finally
    IniFile.Free; // 释放资源
  end;
end;

end.
