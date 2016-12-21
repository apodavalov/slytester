{$V-}
unit QWindow;

interface

uses
  App, Drivers, Objects, Menus, Views, StdDlg, Dialogs, TestTool, SApp, MsgBox, DOS;

const
  MAX_ANSWER = 8;

var
 ResultFileName: string;

type
  PQuestionScroller = ^TQuestionScroller;
  TQuestionScroller = object(TScroller)
    Text: PStrings;
    constructor Init(R: TRect; SX,SY: PScrollBar; Question: PQuestion);
    procedure Draw; virtual;
    destructor Done; virtual;
    function GetMaxLength: Byte;
  end;

  PQuestionWindow = ^TQuestionWindow;
  TQuestionWindow = object(TWindow)
    QuestionNum: Integer;
    QuestionScroller: PQuestionScroller;
    constructor Init(Bounds: TRect; Question: PQuestion; AQuestionNum: Integer; QCount: Integer);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

  PAnswersDialog = ^TAnswersDialog;
  TAnswersDialog = object(TDialog)
    ValidAnswer: Integer;
    constructor Init(var Bounds: TRect; ButtonsCount: Integer; AValidAnswer: Integer);
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

procedure GetQARects(Rect: TRect; var A,Q: TRect);

var
  QuestionWindow: PQuestionWindow;
  AnswersDialog: PAnswersDialog;

implementation

uses
  ChWindow;

function TQuestionScroller.GetMaxLength: Byte;
var
  I: Integer;
  Max: Byte;
begin
  for I:=0 to Text^.Count - 1 do
    if Length(PString(Text^.At(I))^) > Max then Max:=Length(PString(Text^.At(I))^);
  GetMaxLength:=Max;
end;

procedure TQuestionWindow.HandleEvent(var Event: TEvent);
begin
  if (Event.What = evCommand) and (Event.Command = cmClose) then ClearEvent(Event);
  inherited HandleEvent(Event);
end;

procedure GetQARects(Rect: TRect; var A,Q: TRect);
begin
  A:=Rect;
  Q:=Rect;
  Dec(Q.B.Y,6);
  A.A.Y:=Q.B.Y;
end;

procedure TAnswersDialog.HandleEvent(var Event: TEvent);
var
  Rect,A,Q: TRect;
  QNum,QN: Integer;
  filename: string;
  Result: PResult;
  tmp: Word;
  Strings: PStrings;
begin
  if Event.What = evCommand then
    case Event.Command of
      cmClose: ClearEvent(Event);
    else
      if (Event.Command >= 1000) and (Event.Command < MAX_ANSWER + 1000) then
        if MessageBoxA(#3'Ваш ответ ' + IntToStr(Event.Command - 1000 + 1) + #13#10#3' Подтверждаете?',NIL,
                       mfWarning + mfYesButton + mfNoButton) = cmYes then
          begin
            if Event.Command - 1000 = ValidAnswer then Inc(Mark)
                                                  else Inc(MistakesCount);
            QN:=QuestionWindow^.QuestionNum;
            Desktop^.Delete(QuestionWindow);
            Desktop^.Delete(AnswersDialog);
            AnswersDialog^.GetBounds(A);
            QuestionWindow^.GetBounds(Q);
            Dispose(QuestionWindow,Done);
            Dispose(AnswersDialog,Done);
            QuestionWindow:=NIL;
            AnswersDialog:=NIL;
            Inc(QN);
            if QN < Test^.AskingQuestionsCount then
              begin
                Desktop^.GetExtent(Rect);
                QNum:=Test^.GetNextAskQuestion;
                QuestionWindow:=New(PQuestionWindow,
                                 Init(Q,PQuestion(Test^.Questions^.At(QNum)),QN,Test^.AskingQuestionsCount));
                Desktop^.Insert(QuestionWindow);
                AnswersDialog:=New(PAnswersDialog,Init(A,PQuestion(Test^.Questions^.At(QNum))^.Answers^.Count,
                                   PQuestion(Test^.Questions^.At(QNum))^.ValidAnswer));
                Desktop^.Insert(AnswersDialog);
                Exit;
              end
            else
              begin
                Mark:=GetMark(Mark,Test^.AskingQuestionsCount);
                Active:=False;
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
                                   FormNum))^.Men^.At(
                                   ManNum))^.Passed:=True;
                Test^.Save;
                MessageBoxA(#3 + Result^.ManLastName + #13#10#3'Оценка: ' + IntToStr(Mark) + #13#10#3 +
                            'Допущено ошибок: ' + IntToStr(MistakesCount),NIL,mfWarning + mfOKButton);
                Strings:=Test^.Passers^.GetSchoolNames;
                Application^.GetExtent(Rect);
                Dec(Rect.B.Y,2);
                ChooseWindow:=New(PChooseWindow,Init(Rect,'Укажите школу',Strings,NIL,0));
                Desktop^.Insert(ChooseWindow);
                Dispose(Strings,Done);
                EnableCommands([cmCloseFile,cmStop,cmAbout,cmQuit]);
                Exit;
              end;
          end;
      ClearEvent(Event);
    end;
  inherited HandleEvent(Event);
end;

destructor TQuestionScroller.Done;
begin
  Dispose(Text,Done);
  inherited Done;
end;

constructor TQuestionScroller.Init(R: TRect; SX,SY: PScrollBar; Question: PQuestion);
var
  I,J: Integer;
  P: PString;
  tmpStr: string;
  Answer: PStrings;
begin
  inherited Init(R,SX,SY);
  Text:=New(PStrings,Init(0,1));
  GrowMode:=gfGrowHiX + gfGrowHiY;
  for I:=0 to Question^.Text^.Count - 1 do
    begin
      P:=Question^.Text^.At(I);
      Text^.Insert(NewStrA(P^));
    end;
  Text^.Insert(NewStrA(''));
  for I:=0 to Question^.Answers^.Count - 1 do
    begin
      Answer:=Question ^.Answers^.At(I);
      for J:=0 to Answer^.Count - 1 do
        begin
          if J = 0 then
            begin
              str(I + 1,tmpStr);
              tmpStr:=tmpStr + ') '
            end
          else
            tmpStr:='   ';
          P:=Answer^.At(J);
          tmpStr:=tmpStr + P^;
          Text^.Insert(NewStrA(tmpStr));
        end;
    end;
  SetLimit(GetMaxLength,Text^.Count);
end;

procedure TQuestionScroller.Draw;
var
  Y: Integer;
  B: TDrawBuffer;
  S: string;
begin
  for Y:=0 to Size.Y - 1 do
    begin
      MoveChar(B,' ',GetColor(1),Size.X);
      if (Y + Delta.Y < Text^.Count) then
        if (Text^.At(Y + Delta.Y) <> NIL) then
         begin
           s:=PString(Text^.At(Y + Delta.Y))^;
           MoveStr(B,copy(s,Delta.X + 1,Length(s) - Delta.X),GetColor(1));
         end;
      WriteLine(0,Y,Size.X,1,B)
    end;
end;

constructor TAnswersDialog.Init(var Bounds: TRect; ButtonsCount: Integer; AValidAnswer: Integer);
var
  I: Integer;
  R: TRect;
  s: string;
  Len: Integer;
begin
  inherited Init(Bounds,'Выберите номер ответа и нажмите соответствующую кнопку');
  ValidAnswer:=AValidAnswer;
  Len:=(Bounds.B.X - Bounds.A.X - 5) div ButtonsCount;
  R.Assign(2,2,2 + Len,4);
  for I:=0 to ButtonsCount - 1 do
    begin
      str(I + 1,s);
      s:='Ответ ~' + s + '~';
      Insert(New(PButton,Init(R,s,1000 + I,bfNormal)));
      Inc(R.A.X,Len);
      Inc(R.B.X,Len);
    end;
  SelectNext(False);
end;

constructor TQuestionWindow.Init(Bounds: TRect; Question: PQuestion; AQuestionNum: Integer; QCount: Integer);
var
  HS,VS: PScrollBar;
  R: TRect;
begin
  inherited Init(Bounds,'Вопрос ' + IntToStr(AQuestionNum + 1) + ' из ' + IntToStr(QCount),0);
  GetClipRect(Bounds);
  Bounds.Grow(-1,-1);
  VS:=StandardScrollBar(sbVertical + sbHandleKeyboard);
  HS:=StandardScrollBar(sbHorizontal + sbHandleKeyboard);
  QuestionScroller:=New(PQuestionScroller,Init(Bounds,HS,VS,Question));
  Insert(QuestionScroller);
  QuestionNum:=AQuestionNum;
end;

end.