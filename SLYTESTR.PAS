{$A+,B-,D-,E+,F-,G-,I-,L+,N-,O-,P-,Q-,R-,S+,T-,V-,X+,Y+}
{$M 16384,0,655360}
uses
  App, Drivers, Objects, Menus, Views, StdDlg, Dialogs, MsgBox, TestTool, SApp, QWindow, ChWindow, Pass;

var
  SlyTester: TSlyTester;

begin
  Randomize;
  if ParamCount < 1 then
    ResultFileName := 'results.afr'
  else
    ResultFileName := ParamStr(1);
  Results:=New(PResults,Init);
  Results^.LoadFromFile(ResultFileName);
  Test:=New(PTest,Init);
  SlyTester.Init;
  SlyTester.Run;
  SlyTester.Done;
  Dispose(Results,Done);
  Dispose(Test,Done);
end.