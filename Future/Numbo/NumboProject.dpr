program NumboProject;

uses
  Forms,
  NumboApp in 'NumboApp.pas' {Form1},
  Slipnet1Unit in 'Slipnet1Unit.pas',
  Node1Unit in 'Node1Unit.pas',
  Activation1Unit in 'Activation1Unit.pas',
  ObserverUnit in 'ObserverUnit.pas',
  NumboSlipnet1Unit in 'NumboSlipnet1Unit.pas',
  Chunk1Unit in 'Chunk1Unit.pas',
  WorkingMemory1Unit in 'WorkingMemory1Unit.pas',
  oldtrees1Unit in 'oldtrees1Unit.pas',
  HedonicUnit in 'HedonicUnit.pas',
  RelativeProbabilityUnit in 'RelativeProbabilityUnit.pas',
  CoderackUnit in 'CoderackUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
