uses
  TestTool;

var
  Test: PTest;
  I,J,K: Integer;

begin
  Test:=New(PTest,Init);
  if ParamCount > 0 then
    begin
      if Test^.LoadFromFile(ParamStr(1)) <> -1 then
        begin
          for I:=0 to Test^.Passers^.Schools^.Count - 1 do
            for J:=0 to PSchool(Test^.Passers^.Schools^.At(I))^.Forms^.Count - 1 do
              for K:=0 to PForm(PSchool(Test^.Passers^.Schools^.At(I))^.Forms^.At(J))^.Men^.Count - 1 do
                PMan(PForm(PSchool(Test^.Passers^.Schools^.At(I))^.Forms^.At(J))^.Men^.At(K))^.Passed:=False;
          if Test^.SaveToFile(ParamStr(1)) <> -1 then
            WriteLn('Файл ' + ParamStr(1) + 'обновлен')
          else
            WriteLn('Не могу обновить файл ' + ParamStr(1));
        end
      else
        WriteLn('Не могу обновить файл ' + ParamStr(1));
    end
  else
    WriteLn('Использование: refresh <обновляемый файл>');
  Dispose(Test);
end.