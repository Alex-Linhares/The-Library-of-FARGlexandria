unit HedonicUnit;

interface

uses RelativeProbabilityUnit, classes, StdCtrls;

Const ExtMemSize = 300;
      GreatestNumber = 999;
{      CycleSize = 1;}
      MagicNumber = 7;
      Normal_feedback = -0.001;
      HighFitnessThreshold= 0.86;{0.88;}

type
      Query = (yes, no, undefined);

      N = class
               value:integer;
          end;

      EM_Hedonic = class
                        public
                        NumberList: Tlist;
                        constructor create;
                        function get_value(x:integer):integer;
                   end;


      WM_Hedonic = class
                        public
                        E: EM_Hedonic;
                        A, B: N;
                        Q: Query;
                        ready: boolean;
                        feedback: real;


                        constructor create;
                        Procedure Get_Value_in_A;
                        Procedure Get_Value_in_B;
                        Procedure Compare;
                        Procedure Switch;
                        Procedure Exec_Yes;
                        Procedure Exec_No;
                        Procedure Do_Nothing1;
                        Procedure Do_Nothing2;
                        Function Get_Feedback: real;
                   end;

      ICommand = class
                      Wmem: WM_Hedonic;
                      S: String; {Both the memo and the string should move to WMem, but how???}
                      Memo: TMemo;
                      Probability: TRelative_Probability;
                      Promising_List: Tlist;
                      Promising_Probability_List: Tlist;
                      Feedback_List: Tlist;
                      Procedure insert(C:ICommand);
                      function GetFullCommandName:string;
                      Procedure execute; virtual; abstract;
                      Procedure send_Memo (Received_memo:TMemo);
                      Procedure Print;
                      Constructor create;
                      function HasInPromisingList(C:ICommand):boolean;
                      Procedure Copy_Promising_List(C:Icommand);
                 end;

      THedonic_Command_Get_Value_A = class (Icommand)
                              public

                              Constructor create;
                              Procedure Get_Value_in_A (WM: WM_Hedonic);
                              Procedure execute; override;
                          end;
      THedonic_Command_Get_Value_B = class (Icommand)
                              Constructor create;
                              Procedure Get_Value_in_B (WM: WM_Hedonic);
                              Procedure execute; override;
                          end;
      THedonic_Command_Compare = class (Icommand)
                              Constructor create;
                              Procedure Compare (WM: WM_Hedonic);
                              Procedure execute; override;
                          end;
      THedonic_Command_Switch = class (Icommand)
                              Constructor create;
                              Procedure Switch (WM: WM_Hedonic);
                              Procedure execute; override;
                          end;
      THedonic_Command_Yes = class (Icommand)
                              Constructor create;
                              Procedure Exec_Yes (WM: WM_Hedonic);
                              Procedure execute; override;
                          end;
      THedonic_Command_No = class (Icommand)
                              Constructor create;
                              Procedure Exec_No (WM: WM_Hedonic);
                              Procedure execute; override;
                          end;
      THedonic_Command_Nothing1 = class (Icommand)
                              Constructor create;
                              Procedure Do_Nothing1 (WM: WM_Hedonic);
                              Procedure execute; override;
                          end;
      THedonic_Command_Nothing2 = class ( Icommand)
                              Constructor create;
                              Procedure Do_Nothing2 (WM: WM_Hedonic);
                              Procedure execute; override;
                          end;

      THedonic_Macrocommand = class (Icommand)
                                  Commands: Tlist;
                                  Constructor create;
                                  Procedure LoadNewCommand (C:Icommand);
                                  Procedure execute; override;
                                  Procedure ProcessFeedback (F:real);
                                  Procedure Insert_In_Feedback_List (C1, C2: Icommand);
                                  procedure Extend (Cx, Cy: ICommand);
                                  Procedure Check_If_Feedback_exceeds_Threshold;
                                  Procedure Copy_Promising_from_Origins(COrig, CDest: Icommand);
                                  Procedure Feedback_Pomising_from_Origins(COrig, CDest: Icommand; F:real);
                              end;



var  Repertoire: THedonic_MacroCommand;

implementation

function Icommand.GetFullCommandName:string;
var y:integer; Cy:Icommand; S1:string;
begin
     if self.ClassType = THedonic_MacroCommand then
     begin
          S1:='(';
          for y:= 0 to THedonic_Macrocommand(self).Commands.count-1 do
          begin
               Cy:=THedonic_Macrocommand(self).Commands.items[y];
               S1:=S1+Cy.GetFullCommandName;
               if y<THedonic_Macrocommand(self).Commands.count-1 then s1:=s1+',';
          end;
          S1:=S1+')';
     end
     else S1:=self.ClassName;
     Result:=S1;
end;

Procedure THedonic_Macrocommand.Check_If_Feedback_exceeds_Threshold;
var x, y: integer;   Cx: Icommand; P_Aux: TRelative_Probability;
begin
     for x:= 0 to repertoire.Commands.Count-1 do
     begin
          Cx:=repertoire.Commands.items[x];
          for y:= 0 to Cx.Promising_Probability_List.Count-1 do
          begin
               P_aux:= Cx.Promising_Probability_List.items[y];
               if P_aux.get_Fitness>= HighFitnessThreshold then
               begin
                    P_aux.decayFitness;
                    Extend (Cx, Cx.Promising_list.Items[y]);
               end;
          end;
     end;
end;

Procedure Icommand.Copy_Promising_List(C:Icommand);
var x: integer; C1: ICommand; P1: Trelative_Probability; Pnew: ^Trelative_Probability;
begin
     for x:=0 to Promising_List.Count-1 do
     begin
          P1:= Promising_Probability_List.items[x];  {these two lists are ALWAYS parallel... MUST encapsulate this one day}
          C1:= Promising_list.items[x];

          New (Pnew);
          Pnew^:= TRelative_Probability.create;
          Pnew^.feedback({P1.get_fitness/2}0.5); {NEW CONSTANT HERE??? SHIT...}

          C.Promising_List.Add(C1);
          C.Promising_Probability_List.Add(Pnew^)
     end;
end;


Procedure THedonic_MacroCommand.Feedback_Pomising_from_Origins(COrig, CDest: Icommand; F:real);
var x, y, z: integer; C1: ICommand; P1, p2: Trelative_Probability;
begin
     {for each command in repertoire, feedback from those pointing to the beggining of this
     new extended command}

     for x:=0 to repertoire.Commands.Count-1 do
     begin
          c1:=repertoire.Commands.items[x];

          {is this needed? shouldn't be...}
          if (not C1.HasInPromisingList(CDest)) then
             C1.Insert(CDest);

          y:= c1.promising_list.indexof(cOrig);
          z:= c1.promising_list.indexof(cDest);
          if (y>=0) and (z>=0) then
          begin
               P1:=c1.Promising_Probability_List.items[y]; {this is the value we want to copy}
               P2:=c1.promising_probability_list.items[z];

               P2.feedback(P1.get_Fitness);
          end;
     end;
end;

Procedure THedonic_MacroCommand.Copy_Promising_from_Origins(COrig, CDest: Icommand);
var x, y, z: integer; C1: ICommand; P1, p2: Trelative_Probability;
begin
     {for each command in repertoire, see if they point to the beggining of this
     new extended command, and if so, copy the transition probability}

     for x:=0 to repertoire.Commands.Count-1 do
     begin
          c1:=repertoire.Commands.items[x];

          if (not C1.HasInPromisingList(CDest)) then
             C1.Insert(CDest);

          y:= c1.promising_list.indexof(cOrig);
          z:= c1.promising_list.indexof(cDest);
          if (y>=0) and (z>=0) then
          begin
               P1:=c1.Promising_Probability_List.items[y]; {this is the value we want to copy}
               P2:=c1.promising_probability_list.items[z];

               P2.My_initial_Run:=P1.My_initial_run; {AGAIN, breaking encapsulation & DUPLICATE CODE!}
               P2.sum_activation:=P1.sum_activation;
          end;
     end;
end;


Procedure THedonic_Macrocommand.Extend(Cx, Cy: ICommand); {BELONGS ONLY TO THE REPERTOIRE???}
var x, y, z: integer;  C: ^THedonic_Macrocommand; C1: ICommand; P1, P2: TRelative_Probability; Pnew:^TRelative_Probability;
begin
     New (C);
     C^:=THedonic_Macrocommand.create;
     C^.commands.add(Cx);
     C^.Commands.Add(Cy);
     {CHECK IF THIS IS INITIALIZED--> C^.Probability:=...;}

     {Checks to see if there's a command like this on the repertoire already}
     for X:= 0 to repertoire.Commands.Count-1 do
     begin
          c1:=repertoire.Commands.items[x];
          if (C^.GetFullCommandName=C1.GetFullCommandName) then {if it exists, increase!, if it doesn't, create!}
          begin
               {THedonic_Macrocommand(C1).Feedback_Promising_from_Origins(C1, );}
               exit;
          end;
     end;
     {Copies the Promising list to that promising list of Command Cy, preserving
     acquired knowledge concerning what should happen after Cy}

     Cy.Copy_Promising_List(C^);
     Repertoire.LoadNewCommand(C^);

     {for each command in repertoire, see if they point to the beggining of this
      new extended command, and if so, copy the transition probability}
      Repertoire.Copy_Promising_from_Origins(Cx, C^);
end;



Procedure THedonic_Macrocommand.ProcessFeedback (F:real); {SHOULD ONLY BE AVAILABLE FOR THE MACROCOMMAND "ACT"? Refactor to subclass?}
var x, y: integer;   Cx, Cy: Icommand; P_Aux: TRelative_Probability;
begin
     Cx:= commands.items[0];
     P_Aux:= Cx.Probability;
     P_aux.Add_Feedback(F);
     Feedback_List:=Tlist.create;

     for x:= 0 to Commands.Count-2 do
     begin
          Cx:= commands.items[x];
          for y:= x+1 to Commands.Count-1 do
          begin
               Cy:= commands.items[y];
               Insert_in_feedback_list(Cx,Cy);
          end;
     end;
     for x:= 0 to Feedback_List.count-1 do
     begin
          P_aux:=Feedback_list.items[x];
          P_aux.feedback(F);
     end;
     Check_If_Feedback_exceeds_Threshold;
end;


Procedure Icommand.insert(C:ICommand);
Var P: ^TRelative_Probability;
begin
     New (P);
     P^:=TRelative_Probability.create;

     promising_List.add(C);
     Promising_Probability_List.add (P^);
end;

Procedure THedonic_Macrocommand.Insert_In_Feedback_List (C1, C2: Icommand); {THIS METHOD ONLY APPLY TO ACTS? MUST REFACTOR!}
var positionC2: integer;  P2: TRelative_Probability;
begin
     if (not C1.HasInPromisingList(C2)) then
     begin
          C1.Insert(C2);
     end;

     {gets index of C2 in C1's promising list}
     positionC2:= C1.promising_List.indexof(c2);
     P2:= C1.Promising_Probability_List.items[PositionC2];

     if Feedback_List.indexof(P2)<0 then   {???? this feedback list does not belong to either c1 or c2! ONLY APPLY TO ACTS!}
        Feedback_list.Add(P2);
end;

Constructor THedonic_Command_Nothing2.create;
begin
     inherited create;
end;


Constructor  THedonic_Command_Nothing1.create;
begin
     inherited create;
end;


Constructor  THedonic_Command_Yes.create;
begin
     inherited create;
end;


Constructor THedonic_Command_No.create;
begin
     inherited create;
end;

Constructor THedonic_Command_Switch.create;
begin
     inherited create;
end;


Constructor THedonic_Command_Get_Value_B.create;
begin
     inherited create;
end;

Constructor THedonic_Command_Compare.create;
begin
     inherited create;
end;


function ICommand.HasInPromisingList(C:ICommand):boolean;
begin
     {returns true if it does not find the command C there}
     if Promising_list.IndexOf(C)>=0 then result:= true else result:=false;
end;


Constructor ICommand.create;
begin
     Promising_List:= tlist.Create;
     Promising_Probability_list:= tlist.Create; {these lists are parallel, whatever operation goes into one, must go into the other}
     Probability:=TRelative_Probability.create; {it's either this design, or you create a new command object, copying the old one, and changing the probability; but then, how will you find it in the repertoire if it's a different one?  Screw hash tables or other indexes!!!  :) }

     Wmem:=WM_hedonic.create;
end;

Procedure ICommand.send_Memo (Received_memo:TMemo);
begin
     Memo:=Received_Memo;
end;

Procedure ICommand.Print;
begin
     Memo.lines.add('--');
     Memo.lines.add(S);
end;

Constructor THedonic_Macrocommand.create;
begin
     inherited create;
     Commands:=Tlist.create;
end;

Procedure THedonic_Macrocommand.LoadNewCommand (C:ICommand);
begin
     Commands.Add(C);  {This adds C at the end of the list; the last added is the last to run!}
end;

Procedure THedonic_Macrocommand.execute;
var t:integer; C:ICommand;
begin
     for t:= 0 to Commands.Count-1 do
     begin
          C:=Commands.items[t];
          C.execute;
     end;
end;


Constructor THedonic_Command_Get_Value_A.create;
begin
     inherited create;
     Wmem:=WM_hedonic.create;
end;

Procedure THedonic_Command_Get_Value_A.Get_Value_in_A(WM: WM_Hedonic);
begin
     WMem:=WM;
end;

Procedure THedonic_Command_Get_Value_A.execute;
Var N1: N; s1:string;
begin
     WMem.Get_Value_in_A;
     N1:=Wmem.A;
     str (Wmem.E.NumberList.indexof(N1), s1);
     str(N1.value, S); S:='Value in position '+s1+' is '+S; Print;
end;

Procedure THedonic_Command_Get_Value_B.Get_Value_in_B(WM: WM_Hedonic);
begin
     WMem:=WM;
end;

Procedure THedonic_Command_Get_Value_B.execute;
Var N1: N; s1:string;
begin
     WMem.Get_Value_in_B;
     N1:=Wmem.B;
     str (Wmem.E.NumberList.indexof(N1), s1);
     str(N1.value, S); S:='Value in position '+s1+' is '+S; Print;
end;


Procedure THedonic_Command_Compare.Compare(WM: WM_Hedonic);
begin
     WMem:=WM;
end;

Procedure THedonic_Command_Compare.execute;
begin
     Wmem.Compare;
     if Wmem.q=yes then S:='...................................................................................................................Yes' else S:='No';
     print;
end;

Procedure THedonic_Command_Switch.Switch(WM: WM_Hedonic);
begin
     WMem:=WM;
end;

Procedure THedonic_Command_Switch.execute;
var s1, s2, s3, s4:string;
    Na, Nb: N;
begin
     Na:=Wmem.A; Nb:=Wmem.B;
     str(Wmem.E.NumberList.IndexOf(Na), S1);     str(Wmem.E.NumberList.IndexOf(Nb), S2); str (Na.value, S3); Str (Nb.value, S4);
     S:='Value of position ' + S1 + ' is ' +s3+' and value of position ' + S2 + ' is ' +s4; print;
     Wmem.Switch;
     str(Wmem.E.NumberList.IndexOf(Na), S1);     str(Wmem.E.NumberList.IndexOf(Nb), S2); str (Na.value, S3); Str (Nb.value, S4);
     S:='Value of position ' + S1 + ' is ' +s3+' and value of position ' + S2 + ' is ' +s4; print;

end;

Procedure THedonic_Command_Yes.Exec_Yes(WM: WM_Hedonic);
begin
     WMem:=WM;
end;

Procedure THedonic_Command_Yes.execute;
begin
     WMem.Exec_Yes;
     S:='Ready now.'; print;
end;

Procedure THedonic_Command_No.Exec_No(WM: WM_Hedonic);
begin
     WMem:=WM;
end;

Procedure THedonic_Command_No.execute;
begin
     Wmem.Exec_No;
     S:='No'; print;
end;

Procedure THedonic_Command_Nothing1.Do_Nothing1(WM: WM_Hedonic);
begin
     WMem:=WM;
end;

Procedure THedonic_Command_Nothing1.execute;
begin
     Wmem.Do_Nothing1;
     S:='Nothing 1.'; print;
end;

Procedure THedonic_Command_Nothing2.Do_Nothing2(WM: WM_Hedonic);
begin
     WMem:=WM;
end;

Procedure THedonic_Command_Nothing2.execute;
begin
     Wmem.Do_Nothing2;
     S:='Nothing 2.'; print;
end;

{~~~~~~~~~~~~~~~~~~~~~~~~~~~~}

constructor WM_Hedonic.create;
begin
     E:=EM_Hedonic.create;
     A:=N.Create; B:=N.Create;
     ready:=false;
     Q:=undefined;
     A.value:=0; B.value:=0;
     feedback:=Normal_feedback;
end;


Procedure WM_Hedonic.Get_Value_in_A;
var a_pos:integer;
begin
     A_Pos:=random (ExtMemSize-1);
     A:= E.Numberlist.items[A_pos];
     Q:=undefined;
     ready:=false;

     feedback:=Normal_feedback;

end;


Procedure WM_Hedonic.Get_Value_in_B;
var b_pos:integer;
begin
     B_Pos:=random (ExtMemSize-1);
     B:= E.Numberlist.items[B_pos];
     Q:=undefined;
     ready:=false;

     feedback:=Normal_feedback;

end;


Procedure WM_Hedonic.Compare;
begin
     if (  (a.value-b.value)*(E.NumberList.IndexOf(a)-E.NumberList.IndexOf(b)) < 0  ) then
     begin
          Q:=yes;
          {ready:=true;}
     end;

     feedback:=Normal_feedback;
end;

Procedure WM_Hedonic.Switch;
begin
     feedback:=Normal_feedback;
     if ready then
     begin
          E.NumberList.Exchange(E.NumberList.indexof(A),E.NumberList.indexof(B));
          feedback:=1;
     end;
     Q:=undefined;
     ready:=false;

end;

Function WM_Hedonic.Get_Feedback: real;
begin
     result:=feedback;
end;


Procedure WM_Hedonic.Exec_Yes;
begin
     if ready = false then
     begin
          if Q=yes then ready:=true;
     end;
     Q:=undefined;
     feedback:=Normal_feedback;
end;


Procedure WM_Hedonic.Exec_No;
begin
     if Q=no then ready:=true;
     Q:=undefined;

     feedback:=Normal_feedback;

end;


Procedure WM_Hedonic.Do_Nothing1;
begin
     Q:=undefined;
     ready:=false;

     feedback:=Normal_feedback;

end;


Procedure WM_Hedonic.Do_Nothing2;
begin
     Q:=undefined;
     ready:=false;

     feedback:=Normal_feedback;

end;


{~~~~~~~~~~~~~~~~~~~~~~~~~~~~}
constructor EM_Hedonic.create;
var x:integer; N1:N;
begin
     NumberList:=Tlist.Create;
     for x:= 1 to ExtMemSize do
     begin
          N1:= N.Create;
          N1.value:= random (GreatestNumber);
          NumberList.Add(N1);
     end;
end;


function EM_Hedonic.get_value(x:integer):integer;
var N1: N;
begin
     N1:=  NumberList.Items[x];
     result:= N1.value;
end;

end.