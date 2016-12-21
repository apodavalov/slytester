unit Pass;

interface

uses
  App, Drivers, Objects, Menus, Views, StdDlg, Dialogs, MsgBox;

type
  PPasswordInput = ^TPasswordInput;
  TPasswordInput = object(TInputLine)
    procedure Draw; virtual;
  end;

  PPassDialog = ^TPassDialog;
  TPassDialog = object(TDialog)
    InputLine: PPasswordInput;
    constructor Init;
    procedure HandleEvent(var Event: TEvent); virtual;
  end;

implementation

procedure TPasswordInput.Draw;
var
  s: PString;
  i: Integer;
begin
  s:=Data;
  Data:=New(PString);
  Data^[0]:=s^[0];
  FillChar(Data^[1],Length(Data^),'*');
  inherited Draw;
  Dispose(Data);
  Data:=s;
end;

procedure TPassDialog.HandleEvent(var Event: TEvent);
begin
  if Event.What = evCommand then
    case Event.Command of
      cmOK: begin
              EndModal(cmOK);
              ClearEvent(Event);
            end;
      cmCancel: begin
                  EndModal(cmCancel);
                  ClearEvent(Event);
                end;
    end;
  inherited HandleEvent(Event);
end;

constructor TPassDialog.Init;
var
  R,Bounds: TRect;
begin
  Application^.GetExtent(R);
  Bounds.Assign(R.A.X + (R.B.X - R.A.X) div 2 - 38,
                R.A.Y + (R.B.Y - R.A.Y) div 2 - 3,
                R.A.X + (R.B.X - R.A.X) div 2 + 38,
                R.A.Y + (R.B.Y - R.A.Y) div 2 + 3);
  inherited Init(Bounds,'Введите пароль');
  R.Assign(2,1,Bounds.B.X - Bounds.A.X - 2,2);
  InputLine:=New(PPasswordInput,Init(R,255));
  R.Assign((Bounds.B.X - Bounds.A.X) div 2 - 11,3,(Bounds.B.X - Bounds.A.X) div 2 - 1,5);
  Insert(New(PButton,Init(R,'O~K~',cmOK,bfDefault)));
  R.Assign((Bounds.B.X - Bounds.A.X) div 2 + 1,3,(Bounds.B.X - Bounds.A.X) div 2 + 11,5);
  Insert(New(PButton,Init(R,'~O~тмена',cmCancel,bfNormal)));
  Insert(InputLine);
end;

end.