{
  定义一个Task基类
  计算MD5、更新数据库、检查软件版本都可派生于该类
  在调度的时候实现多态，只允许一个任务
}

unit Task;

interface

type
  TTask = class
  end;

var
  CurrentTask: TTask;

implementation

end.
