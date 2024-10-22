unit Analyze;

interface

uses
  System.Classes, System.SysUtils, Vcl.Forms, Winapi.Windows, Winapi.ShellAPI;

type
  TAnylyzeNotifyEvent = reference to procedure(Msg: string);
  TAnylyzeFetchOneEvent = reference to procedure(Match, Ext, FileType,
    Pts: string);

  TAnylyze = class
  private
    function GetFileSize(const FileName: String): LongInt;
  public
    OnNotify: TAnylyzeNotifyEvent;
    OnFetchOne: TAnylyzeFetchOneEvent;
    procedure Start(FileName: string);
  end;

implementation

uses
  TrIDLib;

function TAnylyze.GetFileSize(const FileName: String): LongInt;
var
  SearchRec: TSearchRec;
begin
  if FindFirst(ExpandFileName(FileName), faAnyFile, SearchRec) = 0 then
    Result := SearchRec.Size
  else
    Result := -1;
end;

procedure TAnylyze.Start(FileName: string);
var
  ret, ResNum: LongInt;
  sOut: string;
  AllPoint: integer;
  TrID_DB_Count: integer;
begin
  AllPoint := 0;
  if Assigned(OnNotify) then
    OnNotify('正在检测TrID数据库...');


  TThread.CreateAnonymousThread(
    procedure
    begin
      TrIDLib.LoadDefsPack(ExtractFilePath(Paramstr(0)));
      // load the definitions package (TrIDDefs.TRD) from current path
      TrID_DB_Count := TrIDLib.GetInfo(TRID_GET_DEFSNUM, 0, sOut);

      TThread.Synchronize(nil,
        procedure
        begin
          if Assigned(OnNotify) then
          begin
            OnNotify('找到共计 ' + TrID_DB_Count.ToString + ' 个文件类型。');
            OnNotify('准备分析目标文件：' + FileName + '');
          end;
        end);

      TrIDLib.SubmitFileA(FileName); // submit the file

      TThread.Synchronize(nil,
        procedure
        begin
          if Assigned(OnNotify) then
          begin
            OnNotify('正在匹配TrID数据库...');
          end;
        end);

      ret := TrIDLib.TrID_Analyze(); // perform the analysis

      if ret <> 0 then
      begin
        ResNum := TrIDLib.GetInfo(TRID_GET_RES_NUM, 0, sOut);
        // get the number of results
        if ResNum = 0 then
        begin
          // 没有匹配
          TThread.Synchronize(nil,
            procedure
            begin
              if Assigned(OnNotify) then
              begin
                OnNotify('该文件在数据库中匹配不到相关信息，可以尝试以下操作：' + #13 +
                  #9#9 + '1.用文本编辑器查看该文件。' + #13 +
                  #9#9 + '2.更新到最新的TrID数据库。'
                );

                if (GetFileSize(FileName) div 1024 > 1024) then
                begin
                  // 文件超过1M，不建议用记事本打开
                  Application.MessageBox(PChar('该文件在数据库中匹配不到相关信息，建议以下操作：' + #13
                    + '1.更新到最新的TrID数据库。'), PChar('提示'), MB_OK);
                end
                else
                begin
                  // 是否用记事本打开
                  if ID_YES = Application.MessageBox
                    (PChar('该文件在数据库中匹配不到相关信息，建议以下操作：' + #13 + '1.用文本编辑器查看该文件。' +
                    #13 + '2.更新到最新的TrID数据库。' + #13 + '是否用记事本打开这个文件进行查看？'),
                    PChar('提示'), MB_YESNO + MB_SYSTEMMODAL) then
                  begin
                    ShellExecute(0, nil, PChar('notepad.exe'), PChar(FileName),
                      nil, SW_NORMAL);
                  end;
                end;
              end;
            end);

        end
        else
        begin
          // 匹配到类型
          TThread.Synchronize(nil,
            procedure
            begin
              if Assigned(OnNotify) then
              begin
                OnNotify('匹配到 ' + ResNum.ToString +
                  ' 个类型，开始导出结果到表格...');
              end;
            end);

          // （可选）控制显示数量
          // if strtoint(ConfigFrm.Edit1.Text) < ResNum then ResNum := strtoint(ConfigFrm.Edit1.Text);

          var
            ResId: integer;
            // firt loop caculate sum of point
          for ResId := 1 to ResNum do
          begin
            AllPoint := AllPoint + TrIDLib.GetInfo(TRID_GET_RES_POINTS, ResId,
              sOut); // get filetype extension
          end;

          // second loop output caculate percent of each type
          for ResId := 1 to ResNum do // cycle trough the results
          begin
            var
            Pts := TrIDLib.GetInfo(TRID_GET_RES_POINTS, ResId, sOut);
            // Matching points
            var
            Match := format('%6s',
              [format('%.1f%%', [Pts * 100.0 / AllPoint])]);
            var
              Ext: string;
            TrIDLib.GetInfo(TRID_GET_RES_FILEEXT, ResId, Ext);
            // get filetype extension
            var
              FileType: string;
            TrIDLib.GetInfo(TRID_GET_RES_FILETYPE, ResId, FileType);
            // get filetype descriptions

            TThread.Synchronize(nil,
              procedure
              begin
                if Assigned(OnFetchOne) then
                begin
                  OnFetchOne(Match, Ext, FileType, Pts.ToString);
                end;
              end);

          end;

        end;

        TThread.Synchronize(nil,
          procedure
          begin
            if Assigned(OnNotify) then
            begin
              OnNotify('分析完成，请在下方列表中查看结果。');
            end;
          end);

      end;

    end).Start; // 启动匿名线程

end;

end.
