unit NumboConnotations;

interface

uses ExternalMemoryClass, FARG_Framework_Chunk, classes, graphics;

type
  TMultiplication=class;
  TAddition=class;
  TSubtraction=class;
  
  TNumboChunk = Class (TChunk)
      Procedure SetAcceptableConnotationTypes; override;
  End;

  TNumberInteger = Class (TAtribute)
      Value: integer;
      Constructor Create;  virtual;
      class function GetNew(i:integer):TNumberInteger; static;



      Function GetValue: integer;   overload;
      Function ExactValueCheck(N:TNumberInteger):boolean; overload;
      Function GetMyExpectations:Tlist;  override;
      Function Desirability(Goal:TConnotation): real; override;
  End;

  TNumberReal = Class (TAtribute)
      Value: real;
      Constructor Create;  virtual;
      Function GetValue: real;   overload;
      Function ExactValueCheck(N:TAtribute):boolean; overload;
  End;

  TString = class (TAtribute)
    Value: String;
    Function GetValue: string; overload;
    Function ExactValueCheck (N:TAtribute): boolean; overload; {maybe create a class similarity type??}
  end;

  TBitmapView = Class (TAtribute)
    Bitmap: TBitmap;
    Function GetValue: TBitmap; overload;
  End;

  TBrick = Class (TNumberInteger)
    Procedure BottomUpPropose; override;
  End;

  TTarget = Class (TNumberInteger)
    Procedure BottomUpPropose; Override;
  End;

  TResult = Class (TBrick)
    Procedure BottomUpPropose; Override;
  End;

  TOperations = class (TRelation)
  public
    class function GetRandomOperation:TOperations;


    class function GetInstanceOfClass(kind: Tclass): TOperations; overload;
//    Function GetOperationInstance(T: TOperations):TOperations;

    Function GetValue: integer;
    function GetCopyOf(C:TOperations):Toperations;
    function GetAssociationsOfType(C: TClass): TList; //can't we move to TRelation?
    Function ConditionsAreSatisfied: boolean; override;
    Procedure SetAcceptableConnotationTypes; override;
    Procedure ComputeRelation;override;
    Function Compute (N1, N2: TNumberInteger):TResult; virtual; abstract;
    Function ExpectationsFoundInSTM(Expecting:TList):TList; virtual;
    Function ProposeHypothesis: TOperations;
    Function GetMyExpectations:Tlist;  override;
    Function Desirability(Goal:TConnotation): real; override;
    Function GetMyResult:integer;
  end;

  TMultiplication = class (TOperations)
    Function Compute (N1, N2: TNumberInteger):TResult; override;
  end;

  TAddition = class (TOperations)
    Function Compute (N1, N2: TNumberInteger):TResult; override;
    Function GetInstanceOfClass(kind:Tclass):TRelation; Overload;
  end;

  TSubtraction = class (TOperations)
    Function Compute (N1, N2: TNumberInteger):TResult; override;
  end;

  TStringName = class (TRelation)
  public
    Name: TString;
    Function ConditionsAreSatisfied: boolean; override;
    Procedure SetAcceptableConnotationTypes; override;
    Procedure ComputeRelation;override;
    Function Compute (C: TNumberInteger):TString; overload;
    Function Compute (C: TMultiplication):TString; overload;
    Function Compute (C: TAddition):TString; overload;
    Function Compute (C: TSubtraction):TString; overload;
    function Compute(C: TChunk): TString; overload;
    Function GetStringLength: integer;
  end;


  TBitmapCreator = class (TRelation)
  public
    Bitmap: TBitMapView;
    Function ConditionsAreSatisfied: boolean; override;
    Procedure SetAcceptableConnotationTypes; override;
    Procedure ComputeRelation;override;
    Function Compute (C: TChunk):TBitmapView; overload;
    Function Compute (C: TNumberInteger):TBitmapView; overload;
    Function Compute (C: TMultiplication):TBitmapView; overload;
  end;


implementation

Function MakeCopyOfElementsInList (Original:TList):TList;
var i:integer;
    C:TConnotation;
    R:TList;

begin
    R:=TList.create;
    for I := 0 to Original.Count - 1 do
    begin
        C:=Original[i];
        if C.InheritsFrom(TAtribute) then
        begin

        end
        else
        begin

        end;
    end;
    result:=R;
end;


function TOperations.GetCopyOf(C: TOperations): TOperations;
var op:TOperations;
begin
    Op:=C.GetInstanceOfClass(C.ClassType);

    Op.Elements.Assign(C.Elements, laCopy);       //same elements in same addresses!!!!

    Op.NewElements.Assign(C.NewElements, laCopy); //see above

    Op.Active:=C.Active;
    Op.Available:=C.Available;
    Op.ExpectedConnotation:=C.ExpectedConnotation;
    Op.ExpectedConnotationFound:=C.ExpectedConnotationFound;
    result:=Op;
end;

class function TOperations.GetInstanceOfClass(kind: Tclass): TOperations;  //duplicate code
Var C:TOperations;
begin
    if kind=TAddition then C:=TAddition.Create
    else if kind=TMultiplication then C:=TMultiplication.Create
    else if kind=TSubtraction then C:=TSubtraction.Create;
    result:=C;
end;

class function TOperations.GetRandomOperation: TOperations;
var r:real; Op:TOperations;
begin
    r:= random;
    if (r<=0.33) then
        Op:=TMultiplication.create
    else if (r<=0.66) then
         Op:=TAddition.create
    else Op:=TSubtraction.create;
    result:=Op;
end;

function TOperations.GetValue: integer;
begin
    result:=GetMyResult;
end;

Function TOperations.ProposeHypothesis: TOperations;
var Expect, Foundelements: Tlist; R:Toperations;
begin
     R:=nil;
     Expect:=GetMyExpectations;
     //Then, look whether they are in STM
     FoundElements:= ExpectationsFoundInSTM(Expectations);
     //if so...
     if FoundElements.Count=Expectations.Count then
     begin
        //R:=GetOperationInstance(self);
        R:=TOperations.GetInstanceOfClass(self.ClassType);
        R.Elements.Assign (FoundElements, laCopy);
        R.ComputeRelation;
        R.CommitToSTM;
     end;
     result:=R;
end;



function TOperations.GetAssociationsOfType(C: TClass): TList;
var L, Newlist:TList;
    x:integer;
    Connotation:TConnotation;
begin
    L:=TList.Create;
    NewList:=TList.Create;
    L:=self.ListAllConnotations(L);
    for x := 0 to L.Count - 1 do
    begin
        Connotation:=L.items[x];
        if (Connotation.InheritsFrom(C)) then
           NewList.Add(Connotation);
    end;
    result:=NewList;
end;





Function TOperations.ExpectationsFoundInSTM(Expecting:TList):TList;
var FoundElements: Tlist; i, j: integer; c1, c2:TConnotation;
begin
    FoundElements:=TList.create;
    for I := 0 to Expecting.Count - 1 do
    begin
        C1:=Expecting.items[i];
        for J := 0 to STM.Count - 1 do
        begin
            C2:= STM.items[j];
            //I HATE THIS TYPECAST...
            if TNumberInteger(C1).getvalue=TNumberInteger(c2).getvalue then
               FoundElements.Add(C2);
        end;
    end;
    result:=FoundElements;
end;



{ TNumberInteger }

Constructor TNumberInteger.create;
begin
    State:=Propose;
end;

class function TNumberInteger.GetNew(i:integer):TNumberInteger;
var N:TNumberInteger;
begin
    N:=TNumberInteger.Create;
    N.Value:=i;
    result:=N;
end;

function TNumberInteger.Desirability(Goal:TConnotation): real;
begin
    if tnumberinteger(goal).getvalue=getvalue then
      result:=1 else result:=0;
end;

function TNumberInteger.ExactValueCheck(N: TNumberInteger): boolean;
begin
   {TypeCast Needed to escape abstract error}
   result:= (TNumberInteger(N).GetValue=GetValue);
end;

function TNumberInteger.GetMyExpectations: Tlist;
Var N: TNumberInteger; L:TList;
begin
    N:=TNumberInteger.Create;
    N.value:=self.Value;
    L:=Tlist.Create;
    L.add(N);
    result:=L;
end;

function TNumberInteger.GetValue: integer;
begin
    result:=Value;
end;


{ TNumberReal }

constructor TNumberReal.Create;
begin
    State:=Propose;
end;

function TNumberReal.ExactValueCheck(N: TAtribute): boolean;
begin
   result:= (TNumberReal(N).GetValue=GetValue);
end;

function TNumberReal.GetValue: real;
begin
     result:=value;
end;



{ TBrick }

procedure TBrick.BottomUpPropose;
var x: integer;
begin
     x:= random(5)+1;
     {number coming from external memory}
     if not ExtMem.taken[x] then
        begin
            Value:=extmem.bricks[x]; {FLAG: duplicate code with TTarget.SearchForInstance}
            State:= Propose;        {call TResult.create; if it is TResult...}

            ExtMem.taken[x]:=true;
            ExtMem.FreeBricks:=ExtMem.FreeBricks-1;
        end;
end;


{ TTarget }
procedure TTarget.BottomUpPropose;
begin
     Value:=extmem.target;   {FLAG: duplicate code with TBrick.SearchForInstance}
     //Relevance:=1;
     State:=Propose;
end;

{ TResult }

procedure TResult.BottomUpPropose;
begin
end;

{ TOperation }

Function TOperations.ConditionsAreSatisfied: boolean;  //not doing what the name says!
Var Res:boolean; C:TConnotation;
begin
    res:=false;
    while (Elements.count<2) do
    begin
        C:=STM.items[Random(STM.Count)];
        if (ConnotationIsAcceptable(C)) and  (Elements.IndexOf(C)<0)then
            Elements.Add(C);
    end;
    res:=true;  //wtf??? always returns true?
    Result:=res;
end;

function TOperations.Desirability(Goal:TConnotation): real;
begin
    if TNumberInteger(Goal).GetValue=GetMyResult then
      result:=1 else result:=0;
end;

function TOperations.GetMyExpectations: Tlist;
begin
    result:=elements;
end;


function TOperations.GetMyResult: integer;
begin
    result:=TResult(NewElements.Items[0]).GetValue;
end;

procedure TOperations.SetAcceptableConnotationTypes;
begin
    //clean this up will'ya?
    AcceptableConnotations:=Tlist.Create;
    AcceptableConnotations.add(TBrick);
    AcceptableConnotations.add(TResult);
    AcceptableConnotations.add(TMultiplication);
    AcceptableConnotations.add(TAddition);
    AcceptableConnotations.add(Tsubtraction);
    AcceptableConnotations.Add(TChunk);
    AcceptableConnotations.add(TNumboChunk);
end;


Procedure TOperations.ComputeRelation;
var R: TResult; O1,O2: TConnotation; N1, N2: TNumberInteger;
begin
    {ComputeValue makes a downcast to typenumber--multiplication methods know
    that they are working with numbers, after all, so no problem in coding to
    an implementation here}
    O1:=Elements[0];  {Change to a Get method, obviously}
    O2:=Elements[1];  {Don't code to implementation!}

    if O1.InheritsFrom(TChunk) then
      N1:=TResult(TChunk(O1).GetFirstConnotationOfType(TResult))
    else if O1.InheritsFrom(TRelation) then
      N1:=TResult(TRelation(O1).GetFirstConnotationOfType(TResult))
    else N1:=TNumberInteger (O1);

    if O2.inheritsFrom(TChunk) then
      N2:=TResult(TChunk(O2).GetFirstConnotationOfType(TResult))
    else if O2.inheritsFrom(TRelation) then
      N2:=TResult(TRelation(O2).GetFirstConnotationOfType(TResult))
    else N2:=TNumberInteger(O2);

    R:=Compute(N1,N2);
    NewElements.Add(R);
end;                          


{ TMultiplication }

Function TMultiplication.Compute(N1,N2:TNumberInteger):TResult;
var N3: TResult;
    x, res:integer;
    C:TConnotation;
begin
  N3:=TResult.Create;
  res:=1;
  for x := 0 to Elements.Count - 1 do
  begin
       C:=elements[x];
     if C.inheritsFrom(TNumberInteger) then
        res:=res*TNumberInteger(elements[x]).GetValue
     else if C.inheritsFrom(TOperations) then
        res:=res*TOperations(elements[x]).GetValue;
  end;
  //N3.Value:= (N1.GetValue) * (N2.GetValue);
  N3.Value:=res;
  NewElements.Clear; NewElements.Add(N3);
  result:= N3;

end;

{ TAddition }

function TAddition.Compute(N1, N2: TNumberInteger): TResult;
var N3: TResult;
    x, res:integer;
    C:TConnotation;
begin
  res:=0;
  for x := 0 to Elements.Count - 1 do
  begin
       C:=elements[x];
     if C.inheritsFrom(TNumberInteger) then
        res:=res+TNumberInteger(elements[x]).GetValue
     else if C.inheritsFrom(TOperations) then
        res:=res+TOperations(elements[x]).GetValue;
  end;
  N3:=TResult.Create;
  //N3.Value:= (N1.GetValue) + (N2.GetValue);
  N3.Value:=res;
  NewElements.Clear;  NewElements.Add(N3);
  result:= N3;

end;


function TAddition.GetInstanceOfClass(kind: Tclass): TRelation;
var C:TAddition;
begin
    C:=TAddition.create;
    result:=C;
end;

{ TSubtraction }

function TSubtraction.Compute(N1, N2: TNumberInteger): TResult;
var N3: TResult;
    x, res:integer;
    C:TConnotation;
begin
  C:=elements[0];
  if C.inheritsFrom(TNumberInteger) then
     res:=TNumberInteger(C).GetValue
  else if C.inheritsFrom(TOperations) then
     res:=TOperations(C).GetValue;
  for x := 1 to Elements.Count - 1 do
  begin
     C:=elements[x];
     if C.inheritsFrom(TNumberInteger) then
        res:=res-TNumberInteger(elements[x]).GetValue
     else if C.inheritsFrom(TOperations) then
        res:=res-TOperations(elements[x]).GetValue;
  end;
  N3:=TResult.Create;
  //N3.Value:= (N1.GetValue) + (N2.GetValue);
  N3.Value:=res;
  NewElements.Clear;  NewElements.Add(N3);
  result:= N3;
end;
{begin
  N3:=TResult.Create;
  N3.Value:= (N1.GetValue) - (N2.GetValue);
  result:= N3;
end;}

{ TString }

function TString.ExactValueCheck(N: TAtribute): boolean;
begin
   {TypeCast Needed to escape abstract error}
   result:= (TString(N).GetValue=GetValue);
end;

function TString.GetValue: string;
begin
     result:=Value;
end;


{ TStringName }
function TStringName.Compute(C: TNumberInteger): TString;
Var R: TString; S:String;
begin
    Str(C.Value, S);
    R:=TString.Create;
    R.Value:=S;
    Result:=R;
end;


function TStringName.Compute(C: TChunk): TString;
Var R: TString; S:String; O:TConnotation; I:integer;
begin
    R:=TString.Create;
    S:='(';
    for I := 0 to C.Elements.Count - 1 do
    begin
      O:=C.Elements.items[i];
      if (O.ClassType=TMultiplication) then
      begin
          R:=Compute(TMultiplication(O));
          S:=S+R.Value;
      end;
    end;
    S:=S+')';
    R.Value:=S;
    result:=R;
end;

function TStringName.Compute(C: TAddition): TString;
Var R: TString; S:String; O:TConnotation; I:integer;
begin
    R:=TString.Create;
    for I := 0 to C.Elements.Count - 1 do
    begin
      O:=C.Elements.items[i];
      if (O.inheritsfrom(TNumberInteger)) and (O.ClassType<>TResult) then
      begin
          R:=Compute(TNumberInteger(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TAddition)) then
      begin
          R:=Compute(TAddition(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TSubtraction)) then
      begin
          R:=Compute(TSubtraction(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TMultiplication)) then
      begin
          R:=Compute(TMultiplication(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TChunk)) then
      begin
          R:=Compute(TChunk(O));
          S:=S+R.Value;
      end;
      if i<C.Elements.Count - 1 then
         S:=S+'+';
    end;
    R.Value:=S;
    result:=R;
end;

function TStringName.Compute(C: TMultiplication): TString;
Var R: TString; S:String; O:TConnotation; I:integer;
begin
    R:=TString.Create;
    for I := 0 to C.Elements.Count - 1 do
    begin
      O:=C.Elements.items[i];
      if (O.inheritsfrom(TNumberInteger)) and (O.ClassType<>TResult) then
      begin
          R:=Compute(TNumberInteger(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TAddition)) then
      begin
          R:=Compute(TAddition(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TSubtraction)) then
      begin
          R:=Compute(TSubtraction(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TMultiplication)) then
      begin
          R:=Compute(TMultiplication(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TChunk)) then
      begin
          R:=Compute(TChunk(O));
          S:=S+R.Value;
      end;
      if i<C.Elements.Count - 1 then
         S:=S+'x';
    end;
    R.Value:=S;
    result:=R;
end;


function TStringName.Compute(C: TSubtraction): TString;
Var R: TString; S:String; O:TConnotation; I:integer;
begin
    R:=TString.Create;
    for I := 0 to C.Elements.Count - 1 do
    begin
      O:=C.Elements.items[i];
      if (O.inheritsfrom(TNumberInteger)) and (O.ClassType<>TResult) then
      begin
          R:=Compute(TNumberInteger(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TAddition)) then
      begin
          R:=Compute(TAddition(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TSubtraction)) then
      begin
          R:=Compute(TSubtraction(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TMultiplication)) then
      begin
          R:=Compute(TMultiplication(O));
          S:=S+R.Value;
      end else
      if (O.inheritsfrom(TChunk)) then
      begin
          R:=Compute(TChunk(O));
          S:=S+R.Value;
      end;
      if i<C.Elements.Count - 1 then
         S:=S+'-';
    end;
    R.Value:=S;
    result:=R;
end;

Procedure TStringName.ComputeRelation;
var R: TString; O: TObject;
begin
    O:=elements[0];
    {downcast}
    if (O.inheritsFrom(TNumboChunk)) then R:=Compute(TChunk(O))
    else if (O.InheritsFrom(TNumberInteger)) then R:=Compute(TNumberInteger(O))
    else if (O.ClassType=TMultiplication) then R:=Compute(TMultiplication(O))
    else if (O.ClassType=TSubtraction) then R:=Compute(TSubtraction(O))
    else if (O.ClassType=TAddition) then R:=Compute(TAddition(O));

    NewElements.Add(R);
    Name:=R;
end;

function TStringName.ConditionsAreSatisfied: boolean;
begin
    result:= (Elements.Count=1);
end;

procedure TStringName.SetAcceptableConnotationTypes;
begin
  AcceptableConnotations:=Tlist.Create;
  AcceptableConnotations.add(TNumberInteger);
  AcceptableConnotations.add(TOperations);

  AcceptableConnotations.add(TNumboChunk);
end;

function TStringName.GetStringLength: integer;
begin
    Result:=length(Name.GetValue);
end;




{ TBitmapView }

function TBitmapView.GetValue: TBitmap;
begin
  result:=Bitmap;
end;



{ TBitmapViewer }

function TBitmapCreator.Compute(C: TChunk): TBitmapView;
begin

end;


function TBitmapCreator.Compute(C: TMultiplication): TBitmapView;
begin

end;


function TBitmapCreator.Compute(C: TNumberInteger): TBitmapView;
begin

end;


Procedure TBitmapCreator.ComputeRelation;
var R: TBitmapView; O: TObject;
begin
    O:=Elements[0];
    {downcast}
    if (O.ClassType=TNumboChunk) then R:=Compute(TChunk(O));
    if (O.InheritsFrom(TNumberInteger)) then R:=Compute(TNumberInteger(O));
    if (O.ClassType=TMultiplication) then R:=Compute(TMultiplication(O));

    NewElements.Add(R);
    Bitmap:=R;
end;


function TBitmapCreator.ConditionsAreSatisfied: boolean;
begin
    result:= (Elements.Count=1);
end;


procedure TBitmapCreator.SetAcceptableConnotationTypes;
begin
  inherited;
  AcceptableConnotations:=Tlist.Create;
  AcceptableConnotations.add(TNumberInteger);
  AcceptableConnotations.add(TOperations);
  AcceptableConnotations.add(TNumboChunk);
end;


{ TNumboChunk }

procedure TNumboChunk.SetAcceptableConnotationTypes;
begin
    AcceptableConnotations.Add(TMultiplication);
end;

{
Here's an idea: perhaps we could have even TIncognita from TNumber, which might strugle between
top-down desires and bottom-up information.  Moreover, perhaps, instead of incognita
we should have a class named "Template", and a subclass named "CuriousTemplate",
which should apply the IDEA behind incognita to any type of abstraction--a simple
number, a simple operation, a letter string, a chunk in chess, etc.


The drawback?  More work now than simply doing NUMBO...
}

(*  TChunkTopology = class (TRelation)
    Width, Depth: TNumber;
    ConnotationsInLevel: TList {of TNumber};
    Level:integer;

    Function ConditionsAreSatisfied: boolean; override;
    Procedure GetAcceptableConnotationsTypes; override;
    Function ComputeRelation (RelatedItems: TList):TList;override;
    Function GetNumConnotationsInLevel(C:TChunk): integer;
    Function GetStringLength: integer;

  end;*)

{ TChunkTopology }
(*
Put Depth and Width in the chunk object itself, then (maybe) move it to an
independent TRelation

function TChunkTopology.ComputeRelation(RelatedItems: TList): TList;
begin
  Level:=0;


end;

function TChunkTopology.ConditionsAreSatisfied: boolean;
var C:TConnotation;
begin
   C:=Elements.items[0];
   Result:= (C.classtype=Tchunk) and (Elements.Count=1);
end;

procedure TChunkTopology.GetAcceptableConnotationsTypes;
begin
  inherited;
  AcceptableConnotations:=Tlist.Create;
  AcceptableConnotations.add(TChunk);
end;

function TChunkTopology.GetNumConnotationsInLevel(C: TChunk): integer;


begin
   Connotations[Level]:=self.ConnotationsAtThisLevel.Count;


end;

function TChunkTopology.GetStringLength: integer;
begin

end;
*)

end.
