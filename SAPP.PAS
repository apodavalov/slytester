{$V-}
unit SApp;

interface

uses
  App, Drivers, Objects, Menus, Views, StdDlg, Dialogs, TestTool, MsgBox, Pass, DOS;

type
  TSlyTester = object(TApplication)
    procedure InitStatusLine; virtual;
    procedure InitMenuBar; virtual;
    procedure HandleEvent(var Event: TEvent); virtual;
    procedure Idle; virtual;
    constructor Init;
  end;

function IsTimeOut: Boolean;

var
  Test: PTest;
  Results: PResults;
  FirstTick: LongInt;
  Active: Boolean;
  StaticText: PStaticText;
  SecCount: Word;
  FileDialog: PFileDialog;
  PassDialog: PPassDialog;
  SchoolNum,FormNum,ManNum: Integer;
  Mark: Word;
  MistakesCount: Word;

implementation

uses
  ChWindow, QWindow;

function IsTimeOut: Boolean;
begin
  IsTimeOut:=(Round(SecCount - (GetTickCount - FirstTick) / 18.2) <= 0);
end;

procedure TSlyTester.Idle;
var
  Timer: string;
  I: Integer;
  Result: PResult;
  tmp: Word;
  Strings: PStrings;
  Rect: TRect;
begin
  inherited Idle;
  str(Round(SecCount - (GetTickCount - FirstTick) / 18.2):5,Timer);
  for I:=1 to Length(Timer) do
    if Timer[I] = ' ' then Timer[I]:='0'
                      else Break;
  if not Active then Timer:='00000';
  if StaticText^.Text^ <> Timer then
    begin
      StaticText^.Text^:=Timer;
      StaticText^.Draw;
    end;
  if Active and IsTimeOut then
    begin
      if Dialog <> NIL then
        Dialog^.EndState:=cmNo
      else
        begin
          Active:=False;
          Inc(MistakesCount,Test^.AskingQuestionsCount - QuestionWindow^.QuestionNum);
          if QuestionWindow <> NIL then
            begin
              Desktop^.Delete(QuestionWindow);
              Dispose(QuestionWindow,Done);
              QuestionWindow:=NIL;
            end;
          if AnswersDialog <> NIL then
            begin
              Desktop^.Delete(AnswersDialog);
              Dispose(AnswersDialog,Done);
              AnswersDialog:=NIL;
            end;
          Mark:=GetMark(Mark,Test^.AskingQuestionsCount);
          Result:=New(PResult,Init);
          Result^.ManLastName:=PMan(PForm(PSchool(Test^.Passers^.Schools^.At(
                                    SchoolNum))^.Forms^.At(
                                    FormNum))^.Men^.At(
                                    ManNum))^.ManLastName;
          Result^.FormName:=PForm(PSchool(Test^.Passers^.Schools^.At(
                                  SchoolNum))^.Forms^.At(
                                  FormNum))^.FormName;
          Result^.SchoolName:=PSchool(Test^.Passers^.Schools^.At(
                                      SchoolNum))^.SchoolName;
          Result^.TestNum:=Test^.TestNum;
          Result^.TestName:=Test^.TestName;
          Result^.Mark:=Mark;
          GetDate(Result^.DateTime.Year,Result^.DateTime.Month,Result^.DateTime.Day,tmp);
          GetTime(Result^.DateTime.Hour,Result^.DateTime.Minute,Result^.DateTime.Second,tmp);
          Results^.Results^.Insert(Result);
          Results^.SaveToFile(ResultFileName);
          PMan(PForm(PSchool(Test^.Passers^.Schools^.At(
                             SchoolNum))^.Forms^.At(
                             FormNum))^.Men^.At(ManNum))^.Passed:=True;
          Test^.Save;
          MessageBoxA(#3'Время истекло!'#13#10#3 + Result^.ManLastName + #13#10#3'Оценка: ' + IntToStr(Mark) + #13#10#3 +
                        'Допущено ошибок: ' + IntToStr(MistakesCount),NIL,mfWarning + mfOKButton);
          Strings:=Test^.Passers^.GetSchoolNames;
          Application^.GetExtent(Rect);
          Dec(Rect.B.Y,2);
          ChooseWindow:=New(PChooseWindow,Init(Rect,'Укажите школу',Strings,NIL,0));
          Desktop^.Insert(ChooseWindow);
          Dispose(Strings,Done);
          EnableCommands([cmCloseFile,cmStop,cmAbout,cmQuit]);
        end;
    end;
end;

constructor TSlyTester.Init;
var
  R: TRect;
begin
  inherited Init;
  FirstTick:=GetTickCount;
  Active:=False;
  SecCount:=9999;
  GetClipRect(R);
  R.A.X:=R.B.X - 5;
  R.B.Y:=R.A.Y + 1;
  StaticText:=New(PStaticText,Init(R,'00000'));
  Insert(StaticText);
end;

procedure TSlyTester.HandleEvent(var Event: TEvent);
var
  R: TRect;
  Strings: PStrings;
  Filename,s: string;
  Flag: Boolean;
  Middle: TPoint;
  Sizes: TPoint;
begin
  if Event.What = evCommand then
    case Event.Command of
      cmNext: begin
                Desktop^.SelectNext(False);
                ClearEvent(Event);
              end;
      cmStop: begin
                Desktop^.Delete(ChooseWindow);
                Dispose(ChooseWindow,Done);
                ChooseWindow:=NIL;
                EnableCommands([cmStart]);
                DisableCommands([cmStop]);
                ClearEvent(Event);
              end;
      cmCloseFile: begin
                     PassDialog:=New(PPassDialog,Init);
                     if Desktop^.ExecView(PassDialog) = cmOK then
                       begin
                         PassDialog^.InputLine^.GetData(s);
                         if s = Test^.Password then
                           begin
                             if ChooseWindow <> NIL then
                               begin
                                 Desktop^.Delete(ChooseWindow);
                                 Dispose(ChooseWindow,Done);
                                 ChooseWindow:=NIL;
                               end;
                             Test^.Clear;
                             EnableCommands([cmOpenFile]);
                             DisableCommands([cmStart,cmCloseFile,cmStop]);
                           end
                         else
                           MessageBoxA(#3'Пароль указан неверно!',NIL,mfError + mfOKButton);
                       end;
                     Dispose(PassDialog,Done);
                     ClearEvent(Event);
                   end;
      cmOpenFile: begin
                    Flag:=False;
                    FileDialog:=New(PFileDialog,Init('*.aft','Выберите файл теста','Имя файла',fdOpenButton,0));
                    while not Flag do
                      begin
                        Flag:=True;
                        if Desktop^.ExecView(FileDialog) = cmFileOpen then
                          begin
                            FileDialog^.GetFileName(Filename);
                            Flag:=Test^.LoadFromFile(Filename) = 0;
                            PassDialog:=New(PPassDialog,Init);
                            if Flag then
                              begin
                                if Desktop^.ExecView(PassDialog) = cmOK then
                                  begin
                                    PassDialog^.InputLine^.GetData(s);
                                    if s = Test^.Password then
                                      begin
                                        SecCount:=Test^.TimeCount;
                                        Strings:=Test^.Passers^.GetSchoolNames;
                                        GetClipRect(R);
                                        Dec(R.B.Y,2);
                                        ChooseWindow:=New(PChooseWindow,Init(R,'Укажите школу',Strings,NIL,0));
                                        Desktop^.Insert(ChooseWindow);
                                        Dispose(Strings,Done);
                                        EnableCommands([cmCloseFile,cmStop]);
                                        DisableCommands([cmStart,cmOpenFile]);
                                      end
                                    else
                                      begin
                                        Test^.Clear;
                                        MessageBoxA(#3'Пароль указан неверно!',NIL,mfError + mfOKButton);
                                      end;
                                  end
                              end
                            else
                              MessageBoxA(#3'Данный файл не является файлом зачета!',NIL,mfError + mfOKButton);
                            Dispose(PassDialog,Done);
                          end;
                      end;
                    Dispose(FileDialog,Done);
                    ClearEvent(Event);
                  end;
      cmStart: begin
                 Strings:=Test^.Passers^.GetSchoolNames;
                 GetClipRect(R);
                 Dec(R.B.Y,2);
                 ChooseWindow:=New(PChooseWindow,Init(R,'Укажите школу',Strings,NIL,0));
                 Desktop^.Insert(ChooseWindow);
                 Dispose(Strings,Done);
                 EnableCommands([cmStop]);
                 DisableCommands([cmStart]);
                 ClearEvent(Event);
               end;
      cmAbout: begin
                 GetExtent(R);
                 Middle.X:=(R.B.X - R.A.X) div 2;
                 Middle.Y:=(R.B.Y - R.A.Y) div 2;
                 R.Assign(Middle.X - 23,Middle.Y - 7,Middle.X + 23,Middle.Y + 7);
                 MessageBoxRectB(R,'О программе SlyTester',
                    #3'SlyTester v1.2'#13#10#13#10#3'Anthony Fox (C) 2003-2005'#13#10#13#10 +
                    #3'E-mail: foxsite@fromru.com'#13#10#13#10#3'http://foxsite.hut1.ru'#13#10#3'Freeware',
                    NIL,mfWarning + mfOKButton);
                 ClearEvent(Event);
               end;
      cmQuit: if CommandEnabled(cmCloseFile) then
                begin
                  PassDialog:=New(PPassDialog,Init);
                  if Desktop^.ExecView(PassDialog) = cmOK then
                    begin
                      PassDialog^.InputLine^.GetData(s);
                      if s = Test^.Password then
                        begin
                          if ChooseWindow <> NIL then
                            begin
                              Desktop^.Delete(ChooseWindow);
                              Dispose(ChooseWindow,Done);
                              ChooseWindow:=NIL;
                            end;
                          Test^.Clear;
                          EnableCommands([cmOpenFile]);
                          DisableCommands([cmStart,cmCloseFile,cmStop]);
                        end
                      else
                        begin
                          MessageBoxA(#3'Пароль указан неверно!',NIL,mfError + mfOKButton);
                          ClearEvent(Event);
                        end;
                     end
                   else
                     ClearEvent(Event);
                   Dispose(PassDialog,Done);
                end;
    else
    end;
  inherited HandleEvent(Event);
end;

procedure TSlyTester.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y:=pred(R.B.Y);
  StatusLine:=New(PStatusLine,Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~Alt-X~ Выход',kbAltX,cmQuit,
      NewStatusKey('~F3~ Открыть',kbF3,cmOpenFile,
      NewStatusKey('~Alt+F3~ Закрыть',kbAltF3,cmCloseFile,
      NewStatusKey('~F6~ Следующее окно',kbF6,cmNext,
      NewStatusKey('~F7~ Начать',kbF7,cmStart,
      NewStatusKey('~F10~ Меню',kbF10,cmMenu,NIL)))))),NIL)));
  DisableCommands([cmStart,cmStop,cmCloseFile,cmNext]);
  EnableCommands([cmOpenFile,cmQuit,cmMenu])
end;

procedure TSlyTester.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y:=succ(R.A.Y);
  MenuBar:=New(PMenuBar,Init(R,
    NewMenu(
      NewSubMenu('Ф~a~йл',hcNoContext,
        NewMenu(
          NewItem('~O~ткрыть...','F3',kbF3,cmOpenFile,hcNoContext,
          NewItem('З~a~крыть','Alt+F3',kbAltF3,cmCloseFile,hcNoContext,
          NewLine(
          NewItem('Вы~x~од','Alt+X',kbAltX,cmQuit,hcNoContext,NIL))))),
      NewSubMenu('~T~ест',hcNoContext,
        NewMenu(
          NewItem('Н~a~чать','F7',kbF7,cmStart,hcNoContext,
          NewItem('Зав~e~ршить','F8',kbF8,cmStop,hcNoContext,NIL))),
{          NewItem('Удалить результаты','F9',kbF9,cmClear,hcNoContext,NIL)))),}
      NewItem('О п~p~ограмме...','',0,cmAbout,hcNoContext,NIL))))));
end;

end.
