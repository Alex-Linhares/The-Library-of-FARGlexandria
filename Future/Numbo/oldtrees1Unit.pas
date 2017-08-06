unit oldtrees1Unit;

interface

uses classes;

type
    TTree = class
                   ChunkStuff: TList;
                   Parent_Chunk: TTree;

                   {COMPOSITE PATTERN HERE}
                   procedure Add (C: TTree; position:integer);  virtual;
                   procedure Remove (C: TTree);  overload;
                   procedure Remove (y: integer);  overload;
                   function Num_descendants: integer; virtual;
                   function Size_of_tree: integer; virtual;
                   function Get_Item_in_Position(y:integer):TTree; virtual;
                   function Get_Random_Position: integer; virtual;
                   Function Get_Random_Insert_Position: integer; virtual;
                   Procedure InsertChunk_in_Position(Chunk: TTree; y: integer); virtual;
{                   function HasNext: boolean;
                   Function Next: TTree;}
           end;






implementation

function TTree.Num_descendants: integer;
begin
     result:=ChunkStuff.Count;
end;

Function TTree.Get_Random_Position: integer;
begin
     result:= random (Size_of_Tree-2); {MINUS THE ROOT AND THE LAST ITEM}
end;

Function TTree.Get_Random_Insert_Position: integer;
begin
     result:= random (Size_of_Tree+1);
end;

Procedure TTree.Add(C:TTree; position: integer);
begin
{     if (position<=ChunkStuff.count) then }
        ChunkStuff.insert(position, C);
     {inserts code here or somewhere to take it off working memory}
end;

procedure TTree.Remove (C: TTree);
var Iterator: TTree; count:integer;
begin
     if (Chunkstuff.IndexOf(C)>=0) then
     begin
          ChunkStuff.Delete(Chunkstuff.IndexOf(C));
     end else
     begin
          count:=0;
          while count<Num_Descendants do
          begin
               Iterator:= Chunkstuff.items[Count];
               Iterator.Remove(C);
               Count:=Count+1;
          end;
     end;
end;


function TTree.Get_Item_in_Position(y:integer):TTree;
var Iterator, res: TTree; count:integer;
begin  {BEWARE: TRICKY CODE IN HERE!!}
     res:=nil;
     IF (y=0) then
     begin
          res:=self;
     end
     else begin
               for count:= 0 to num_descendants-1 do
               begin
                    if (num_descendants>0) then
                    begin
                       Iterator:=Chunkstuff.Items[count];
                       res:=Iterator.Get_Item_in_Position(y-1);
                       if res<>nil then
                       begin
                            result:= res;
                            exit;
                       end else y:=y-(Iterator.size_of_tree+1);
                       if y=0 then
                       begin
                            result:=self;
                            exit;
                       end;
                    end;
               end;
           end;
     result:=res;
end;



Procedure TTree.Remove(y:integer);
{var Iterator: TTree;   count:integer;}
begin
(*     {ONLY SEEMS TO WORK ON FLAT HIERARCHIES}
     count:=0;
     if (y<=num_descendants) then add(Chunk, y)
     else begin
          while (y>0) and (count<Num_descendants) do
          begin
               y:=y-1;
               Iterator:=Chunkstuff.Items[count];
               Iterator.insertchunk_in_Position(Chunk, y);
               count:=count+1;
          end;
     end;*)
end;

function TTree.Size_of_tree: integer;
var Iterator: TTree; count, total:integer;
begin
     if Num_descendants=0 then result:=0
     else begin
          {RETURNS THE SIZE OF THE TREE BELOW = SIZE OF TREE-1}
          count:=0;
          Total:=chunkstuff.Count;
          while count<Num_Descendants do
          begin
               Iterator:= Chunkstuff.items[Count];
               Total:=Total+Iterator.Size_of_tree;
               Count:=Count+1;
          end;
          result:=Total;
     end;
end;


Procedure TTree.InsertChunk_in_Position(Chunk: TTree; y: integer);
{ONLY SEEMS TO WORK ON FLAT HIERARCHIES}
var Iterator: TTree;   count:integer;
begin
     count:=0;
     if (y<=num_descendants) then add(Chunk, y)
     else begin
          while (y>0) and (count<Num_descendants) do
          begin
               y:=y-1;
               Iterator:=Chunkstuff.Items[count];
               Iterator.insertchunk_in_Position(Chunk, y);
               count:=count+1;
          end;
     end;
end;



end.