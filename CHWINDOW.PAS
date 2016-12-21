{$I-}
unit ChWindow;

interface

uses
  App, Drivers, Objects, Menus, Views, StdDlg, Dialogs, TestTool, SApp, MsgBox;

const
  cmStart = 202;
  cmStop = 203;
  cmAbout = 204;
  cmCloseFile = 205;
  cmOpenFile = 206;

type
  PChooseScroller = ^TChooseScroller;
  TChooseScroller = object(TScroller)
    Items: PStrings;
    Availability: PBooleans;
    Location: Integer;
    constructor Init(R: TRect; SX,SY: PScrollBar; AItems: PStrings; AAvailability: PBooleans);
    procedure Draw; virtual;
    destructor Done; virtual;
    function GetMaxLength: Byte;
  end;

  PChooseWindow = ^TChooseWindow;
  TChooseWindow = object(TWindow)
    Depth: Word;
    ChooseScroller: PChooseScroller;
    procedure HandleEvent(var Event: TEvent); virtual;
    constructor Init(Bounds: TRect; ATitle: TTitleStr; AItems: PStrings; AAvailability: PBooleans; ADepth: Word);
    destructor Done; virtual;
    procedure OnChooseLocation;
  end;

var
  ChooseWindow: PChooseWindow;

implementation

uses
  QWindow;

function TChooseScroller.GetMaxLength: Byte;
var
  I: Integer;
  Max: Byte;
begin
  Max:=0;
  for I:=0 to Items^.Count - 1 do
    if Length(PString(Items^.At(I))^) > Max then Max:=Length(PString(Items^.At(I))^);
  GetMaxLength:=Max;
end;

procedure TChooseWindow.OnChooseLocation;
var
  School: PSchool;
  Form: PForm;
  Man: PMan;
  I: Integer;
  b: PBoolean;
  Rect,A,Q: TRect;
  QNum: Integer;
begin
  if ChooseScroller^.Location = ChooseScroller^.Items^.Count - 1 then
    begin
      if Depth <> 0 then
        begin
          Dec(Depth);
          ChooseScroller^.Location:=0;
          Dispose(ChooseScroller^.Items,Done);
          case Depth of
            0: begin
                 ChooseScroller^.Items:=Test^.Passers^.GetSchoolNames;
                 DisposeStr(Title);
                 Title:=NewStr('Укажите школу');
                 ChooseScroller^.Items^.Insert(NewStrA('Завершить'));
               end;
            1: begin
                 DisposeStr(Title);
                 Title:=NewStr('Укажите класс');
                 School:=Test^.Passers^.Schools^.At(SchoolNum);
                 ChooseScroller^.Items:=School^.GetFormNames;
                 ChooseScroller^.Items^.Insert(NewStrA('Назад...'));
               end;
          end;
          ChooseScroller^.Availability^.FreeAll;
          for I:=0 to ChooseScroller^.Items^.Count - 1 do
            begin
              New(b);
              b^:=False;
              ChooseScroller^.Availability^.Insert(b);
            end;
          ChooseScroller^.SetLimit(ChooseScroller^.GetMaxLength,ChooseScroller^.Items^.Count);
          Frame^.Draw;
          Draw;
          ChooseScroller^.Draw;
        end
      else
        begin
          DisableCommands([cmStop]);
          Application^.EnableCommands([cmStart]);
          Desktop^.Delete(ChooseWindow);
          Dispose(ChooseWindow,Done);
          ChooseWindow:=NIL;
        end;
    end
  else
    begin
      Inc(Depth);
      case Depth of
        1: begin
             Dispose(ChooseScroller^.Items,Done);
             DisposeStr(Title);
             Title:=NewStr('Укажите класс');
             SchoolNum:=ChooseScroller^.Location;
             School:=Test^.Passers^.Schools^.At(SchoolNum);
             ChooseScroller^.Items:=School^.GetFormNames;
             ChooseScroller^.Items^.Insert(NewStrA('Назад...'));
             ChooseScroller^.Availability^.FreeAll;
             for I:=0 to ChooseScroller^.Items^.Count - 1 do
               begin
                 New(b);
                 b^:=False;
                 ChooseScroller^.Availability^.Insert(b);
               end;
           end;
        2: begin
             Dispose(ChooseScroller^.Items,Done);
             DisposeStr(Title);
             Title:=NewStr('Укажите фамилию');
             FormNum:=ChooseScroller^.Location;
             School:=Test^.Passers^.Schools^.At(SchoolNum);
             Form:=School^.Forms^.At(FormNum);
             ChooseScroller^.Items:=Form^.GetManLastNames;
             Dispose(ChooseScroller^.Availability,Done);
             ChooseScroller^.Availability:=Form^.GetManPasseds;
             ChooseScroller^.Items^.Insert(NewStrA('Назад...'));
             New(b);
             b^:=False;
             ChooseScroller^.Availability^.Insert(b);
           end;
        3: begin
             if not PBoolean(ChooseScroller^.Availability^.At(ChooseScroller^.Location))^ then
               if MessageBoxA(#3'Начать?',
                              NIL,mfWarning + mfYesButton + mfNoButton) = cmYes then
                 begin
                   SchoolNum:=SchoolNum;
                   FormNum:=FormNum;
                   ManNum:=ChooseScroller^.Location;
                   SecCount:=Test^.TimeCount;
                   FirstTick:=GetTickCount;
                   Active:=True;
                   Mark:=0;
                   MistakesCount:=0;
                   Desktop^.GetExtent(Rect);
                   GetQARects(Rect,A,Q);
                   Test^.FalseAskedQuestions;
                   QNum:=Test^.GetNextAskQuestion;
                   QuestionWindow:=New(PQuestionWindow,
                                    Init(Q,PQuestion(Test^.Questions^.At(QNum)),0,Test^.AskingQuestionsCount));
                   Desktop^.Insert(QuestionWindow);
                   AnswersDialog:=New(PAnswersDialog,Init(A,PQuestion(Test^.Questions^.At(QNum))^.Answers^.Count,
                                      PQuestion(Test^.Questions^.At(QNum))^.ValidAnswer));
                   Desktop^.Insert(AnswersDialog);
                   DisableCommands([cmCloseFile,cmStop,cmAbout,cmQuit]);
                   Desktop^.Delete(ChooseWindow);
                   Dispose(ChooseWindow,Done);
                   ChooseWindow:=NIL;
                   Exit;
                 end
               else
                 Dec(Depth)
             else
               Dec(Depth);
               Exit;
           end;
      end;
      ChooseScroller^.SetLimit(ChooseScroller^.GetMaxLength,ChooseScroller^.Items^.Count);
      ChooseScroller^.Location:=0;
      Frame^.Draw;
      Draw;
      ChooseScroller^.Draw;
    end;
end;

procedure TChooseWindow.HandleEvent(var Event: TEvent);
var
  Point: TPoint;
begin
  if (Event.What and evMouseDown = evMouseDown) and (Event.Buttons and mbLeftButton = mbLeftButton) and
     not Event.Double then
      begin
        MakeLocal(Event.Where,Point);
        if (Point.X > 0) and (Point.Y > 0) and (Point.X < Size.X - 1) and (Point.Y < Size.Y - 1) then
          begin
            if ChooseScroller^.Delta.Y + Point.Y - 1 < ChooseScroller^.Items^.Count then
              begin
                ChooseScroller^.Location:=ChooseScroller^.Delta.Y + Point.Y - 1;
                ChooseScroller^.Draw;
              end;
            ClearEvent(Event);
          end
        else
          begin
            inherited HandleEvent(Event);
            if (ChooseScroller^.Location < ChooseScroller^.Delta.Y) or
               (ChooseScroller^.Location > ChooseScroller^.Delta.Y + Size.Y - 3) then
            ChooseScroller^.Location:=ChooseScroller^.Delta.Y;
            ChooseScroller^.Draw;
            Exit;
          end;
      end;
  if (Event.What and evMouseDown = evMouseDown) and (Event.Buttons and mbLeftButton = mbLeftButton) and
     Event.Double then
    begin
      MakeLocal(Event.Where,Point);
      if (Point.X > 0) and (Point.Y > 0) and (Point.X < Size.X - 1) and (Point.Y < Size.Y - 1) then
        begin
          if ChooseScroller^.Delta.Y + Point.Y - 1 < ChooseScroller^.Items^.Count then
            begin
              ChooseScroller^.Location:=ChooseScroller^.Delta.Y + Point.Y - 1;
              ChooseScroller^.Draw;
              OnChooseLocation;
            end;
          ClearEvent(Event);
        end
      else
        begin
          inherited HandleEvent(Event);
          if (ChooseScroller^.Location < ChooseScroller^.Delta.Y) or
             (ChooseScroller^.Location > ChooseScroller^.Delta.Y + Size.Y - 3) then
          ChooseScroller^.Location:=ChooseScroller^.Delta.Y;
          ChooseScroller^.Draw;
          Exit;
        end;
    end;
  if (Event.What and evKeyDown = evKeyDown) and (Event.KeyCode = kbEnter) then OnChooseLocation;
  if (Event.What and evKeyDown = evKeyDown) and (Event.KeyCode = kbUp) then
    if ChooseScroller^.Location <> 0 then
      begin
        Dec(ChooseScroller^.Location);
        ChooseScroller^.Draw;
        if ChooseScroller^.Location >= ChooseScroller^.Delta.Y then ClearEvent(Event);
      end;
  if (Event.What and evKeyDown = evKeyDown) and (Event.KeyCode = kbDown) then
    if ChooseScroller^.Location < ChooseScroller^.Items^.Count - 1 then
      begin
        Inc(ChooseScroller^.Location);
        if ChooseScroller^.Location >= ChooseScroller^.Delta.Y + Size.Y - 2 then
          ChooseScroller^.ScrollTo(ChooseScroller^.Delta.X,ChooseScroller^.Delta.Y + 1);
        ClearEvent(Event);
        ChooseScroller^.Draw;
      end;
  if (Event.What and evKeyDown = evKeyDown) and (Event.KeyCode = kbPgUp) then
    begin
      inherited HandleEvent(Event);
      if (ChooseScroller^.Location < ChooseScroller^.Delta.Y) or
         (ChooseScroller^.Location > ChooseScroller^.Delta.Y + Size.Y - 3) then
        ChooseScroller^.Location:=ChooseScroller^.Delta.Y + Size.Y - 3;
      ChooseScroller^.Draw;
      Exit;
    end;
  if (Event.What and evKeyDown = evKeyDown) and (Event.KeyCode = kbPgDn) then
    begin
      inherited HandleEvent(Event);
      if (ChooseScroller^.Location < ChooseScroller^.Delta.Y) or
         (ChooseScroller^.Location > ChooseScroller^.Delta.Y + Size.Y - 3) then
        ChooseScroller^.Location:=ChooseScroller^.Delta.Y;
      ChooseScroller^.Draw;
      Exit;
    end;
  if Event.What = evCommand then
    if Event.Command = cmClose then
      begin
        ChooseWindow:=NIL;
        EnableCommands([cmStart]);
        DisableCommands([cmStop]);
      end;
  inherited HandleEvent(Event);
end;

constructor TChooseWindow.Init(Bounds: TRect; ATitle: TTitleStr; AItems: PStrings; AAvailability: PBooleans; ADepth: Word);
var
  HS,VS: PScrollBar;
begin
  inherited Init(Bounds,ATitle,0);
  Depth:=ADepth;
  SchoolNum:=-1;
  FormNum:=-1;
  GetClipRect(Bounds);
  Bounds.Grow(-1,-1);
  VS:=StandardScrollBar(sbVertical + sbHandleKeyboard);
  HS:=StandardScrollBar(sbHorizontal + sbHandleKeyboard);
  ChooseScroller:=New(PChooseScroller,Init(Bounds,HS,VS,AItems,AAvailability));
  Insert(ChooseScroller);
end;

destructor TChooseWindow.Done;
begin
  Dispose(ChooseScroller,Done);
  inherited Done;
end;

procedure TChooseScroller.Draw;
var
  n,k: Integer;
  B: TDrawBuffer;
  Color: Byte;
  p: PString;
begin
  if Location > ChooseWindow^.Size.Y - 3 + Delta.Y then
    Location:=ChooseWindow^.Size.Y - 3 + Delta.Y;
  inherited Draw;
  for n := 0 to Size.Y - 1 do
    begin
      k := Delta.Y + n;
      if k = Location then Color := GetColor(2)
                      else Color := GetColor(1);
      if Availability^.Count > k then
        if PBoolean(Availability^.At(k))^ and (k <> Location) then
          Color:=23;
      MoveChar(B,' ',Color,Size.X);
      if k < Items^.Count then
        begin
          p := Items^.At(k);
          MoveStr(B, Copy(p^,Delta.X + 1,Size.X),Color);
        end;
      WriteLine(0,N,Size.X,1,B)
    end
end;

constructor TChooseScroller.Init(R: TRect; SX,SY: PScrollBar; AItems: PStrings; AAvailability: PBooleans);
var
  I: Integer;
  s: PString;
  b: PBoolean;
begin
  inherited Init(R, SX, SY);
  Items:=New(PStrings,Init(0,1));
  if AItems <> NIL then
    for I:=0 to AItems^.Count - 1 do
      begin
        s:=AItems^.At(I);
        Items^.Insert(NewStrA(s^));
      end;
  Availability:=New(PBooleans,Init(0,1));
  if AAvailability <> NIL then
    for I:=0 to AAvailability^.Count - 1 do
      begin
        New(b);
        b^:=PBoolean(AAvailability^.At(I))^;
        Availability^.Insert(b);
      end;
  Items^.Insert(NewStrA('Завершить'));
  New(b);
  b^:=False;
  Availability^.Insert(b);
  Location:=0;
  GrowMode:=gfGrowHiX + gfGrowHiY;
  SetLimit(GetMaxLength,Items^.Count);
end;

destructor TChooseScroller.Done;
begin
  Dispose(Availability,Done);
  Dispose(Items,Done);
  inherited Done;
end;

end.