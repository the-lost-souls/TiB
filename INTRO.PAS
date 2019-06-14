Program Topp;
{$M 20000, 0, 256000}

Uses
  DemoGrx, Crt, GoldPlay;

Const
  NumStars  = 80;
  Speed     = 0.1;
  ArraySize = 2605;

  PelAddrRgR  = $3C7;
  PelAddrRgW  = $3C8;
  PelDataReg  = $3C9;

Type
  rgb = RECORD r, g, b : BYTE; END;

  XYZType = Record
              X, Y : Integer;
              Z : Real;
            End;
  ScrType = Array(.1..1.) Of Byte;

  StarType = Array(.1..NumStars.) Of XYZType;

Label 1;

Var
  col : ARRAY[0..767] OF Rgb;
  J, I, K, L : Word;
  X, Y : Integer;
  Bar1, Bar1Temp, Bar2, Bar2Temp, Bar3, Bar3Temp, Bar4, Bar4Temp : Word;
  F : File;
  ScrP : ^ScrType;
  C : ShortInt;
  Stars : StarType;
  Ch : Char;
  sverre : Byte;
  Rgbs : RgbsType;


PROCEDURE GetCol(C : BYTE; VAR R, G, B : BYTE);
BEGIN
   Port[PelAddrRgR] := C;
   R := Port[PelDataReg];
   G := Port[PelDataReg];
   B := Port[PelDataReg];
END;

PROCEDURE SetCol(C, R, G, B : BYTE);
BEGIN
   Port[PelAddrRgW] := C;
   Port[PelDataReg] := R;
   Port[PelDataReg] := G;
   Port[PelDataReg] := B;
END;

PROCEDURE SetInten(b : BYTE);
VAR i : INTEGER; fr, fg, fb : BYTE;
BEGIN
   FOR i := 0 TO 767 DO
   BEGIN
      fr := col[i].r*b DIV 64;
      fg := col[i].g*b DIV 64;
      fb := col[i].b*b DIV 64;
      SetCol(i, fr, fg, fb);
   END;
END;

Procedure Part_I;
{The part with LOGOBARS}

Var
  ArrayCounter, FontCount : Word;
  Tab : Array(.1..ArraySize.) OF XYType;
  Dummy : XYType;
  XYF : File Of XYType;


Procedure ReadPicture;
{Reads picture into screenvariable}

Begin
  Assign(F, 'tiá4.tls');
  Reset(F, 1);
  Seek(F, 768);

  BlockRead(F, ScrP^, 64000, I);
  Close(F);
End;                                  {Procedure ReadPicture}


Procedure ReadCoordFile;
{Reads XY-coordinates from file}

Begin
  Assign(XYF, 'tiá1.tls');
  Reset(XYF);
  For I := 1 To ArraySize Do
  Begin
    Read(XYF, Dummy);
    Read(XYF, Dummy);
    Read(XYF,Tab[I]);
  End;
  Close(XYF);
END;                                  {Procedure ReadCoordFile}

Procedure GetBarValues;
{Gets values from bars}

Begin
  Bar1Temp := Bar1;                      {Save the last value!}
  If BopBar(1) Mod 2 = 0 Then Bar1 := BopBar(1) Else Bar1 := BopBar(1) + 1;
  Bar2Temp := Bar2;
  If BopBar(2) Mod 2 = 0 Then Bar2 := BopBar(2) Else Bar2 := BopBar(2) + 1;
  Bar3Temp := Bar3;
  If BopBar(3) Mod 2 = 0 Then Bar3 := BopBar(3) Else Bar3 := BopBar(3) + 1;
  Bar4Temp := Bar4;
  If BopBar(4) Mod 2 = 0 Then Bar4 := BopBar(4) Else Bar4 := BopBar(4) + 1;
End;                                  {Procedure GetBarValues}


Procedure HorLine(X1, Y1, Length : Integer);
{Draws a line with colors taken from screenvariable}

Begin
  For L := X1 To X1 + Length Do FPutPixel(L, Y1, ScrP^(.((Y1 - 1) * 320) + L.), $A000);
End;                                  {Procedure HorLine}

Procedure BlackHorLine(X1, Y1, Length : Integer);
{Draws a totally black line}

Begin
  For L := X1 To X1 + Length Do FPutPixel(L, Y1, 0, $A000);
End;                                  {Procedure BlackHorLine}


Begin                                 {Procedure Part_I}
  LoadModule('tiá6.tls');
  ReadCoordFile;                      {Read coordinates}
  ReadPicture;                        {Read picture into screenvariable}

  GetPicturePalette('tiá4.tls', Rgbs);{Get the palette from picture}

  For I := 1 To NumStars DO
  Begin
    Stars(.I.).X := Random(520) - 100;  {Random positions}
    Stars(.I.).Y := Random(400) - 100;  {Random positions}
    Stars(.I.).Z := (Random(63) + 1) / 10;
  End;

  Bar1 := 0;                          {Put values to zero}
  Bar2 := 0;
  Bar3 := 0;
  Bar4 := 0;
  ArrayCounter := 1;
  FontCount := 0;
  C := 0;
  J := 2;

  Set256PAlette(Rgbs);                {Sets palette}
  For I := 0 To 64 Do SetRGBColor(64 - I, 64 - I, 64 - I, I);

  FOR i := 0 TO 767 DO GetCol(i, col[i].r, col[i].g, col[i].b); {Reads Colors}

  MasterVolume(64);
  StartPlaying;

  Repeat
    For I := 1 To NumStars Do         {The stars}
    Begin
      If ArrayCounter = 1 Then        {Test if coordarray is at it's end}
      XYZ(Stars(.I.).X, Stars(.I.).Y, Tab(.ArraySize.).X, Tab(.ArraySize.).Y, Stars(.I.).Z, X, Y)
      Else
        XYZ(Stars(.I.).X, Stars(.I.).Y, Tab(.ArrayCounter - 1.).X, Tab(.ArrayCounter - 1.).Y, Stars(.I.).Z, X, Y);

      If FGetPixel(X, Y, $A000) < 64 Then FPutPixel(X, Y, 0, $A000);
        {Do not overwrite!}
      Stars(.I.).Z := Stars(.I.).Z - Speed;
        {Move stars}
      If Stars(.I.).Z < 0.1 Then Stars(.I.).Z := 6.3;
        {Test Z-coordinate}
      XYZ(Stars(.I.).X, Stars(.I.).Y, Tab(.ArrayCounter.).X, Tab(.ArrayCounter.).Y, Stars(.I.).Z, X, Y);
        {Calculate new XY-values}
      If FGetPixel(X, Y, $A000) < 64 Then FPutPixel(X, Y, Round(Stars(.I.).Z * 10), $A000);
        {Plot stars}
    End;

    GetBarValues;                     {Gets values to bar}
    If Bar1 < Bar1Temp Then           {Draws bars}
    Begin
      K := Bar1Temp;
      Repeat
        BlackHorLine(76, 200 - K, 41);
        K := K - 2;
      Until K <= Bar1;
    End
    Else
    Begin
      K := Bar1Temp;
      Repeat
        HorLine(76, 200 - K, 41);
        K := K + 2;
      Until K >= Bar1;
    End;

    If Bar2 < Bar2Temp Then
    Begin
      K := Bar2Temp;
      Repeat
        BlackHorLine(118, 200 - K, 41);
        K := K - 2;
      Until K <= Bar2;
    End
    Else
    Begin
      K := Bar2Temp;
      Repeat
        HorLine(118, 200 - K, 41);
        K := K + 2;
      Until K >= Bar2;
    End;

    If Bar3 < Bar3Temp Then
    Begin
      K := Bar3Temp;
      Repeat
        BlackHorLine(160, 200 - K, 41);
        K := K - 2;
      Until K <= Bar3;
    End
    Else
    Begin
      K := Bar3Temp;
      Repeat
        HorLine(160, 200 - K, 41);
        K := K + 2;
      Until K >= Bar3;
    End;

    If Bar4 < Bar4Temp Then
    Begin
      K := Bar4Temp;
      Repeat
        BlackHorLine(202, 200 - K, 41);
        K := K - 2;
      Until K <= Bar4;
    End
    Else
    Begin
      K := Bar4Temp;
      Repeat
        HorLine(202, 200 - K, 41);
        K := K + 2;
      Until K >= Bar4;
    End;

    If ArrayCounter < ArraySize Then Inc(ArrayCounter) Else ArrayCounter := 1;

  Until KeyPressed;                   {Hmmm???}



  FOR sverre := 64 DOWNTO 1 DO
  BEGIN
    For I := 1 To NumStars Do         {The stars}
    Begin
      If ArrayCounter = 1 Then        {Test if coordarray is at it's end}
      XYZ(Stars(.I.).X, Stars(.I.).Y, Tab(.ArraySize.).X, Tab(.ArraySize.).Y, Stars(.I.).Z, X, Y)
      Else
        XYZ(Stars(.I.).X, Stars(.I.).Y, Tab(.ArrayCounter - 1.).X, Tab(.ArrayCounter - 1.).Y, Stars(.I.).Z, X, Y);

      If FGetPixel(X, Y, $A000) < 64 Then FPutPixel(X, Y, 0, $A000);
        {Do not overwrite!}
      Stars(.I.).Z := Stars(.I.).Z - Speed;
        {Move stars}
      If Stars(.I.).Z < 0.1 Then Stars(.I.).Z := 6.3;
        {Test Z-coordinate}
      XYZ(Stars(.I.).X, Stars(.I.).Y, Tab(.ArrayCounter.).X, Tab(.ArrayCounter.).Y, Stars(.I.).Z, X, Y);
        {Calculate new XY-values}
      If FGetPixel(X, Y, $A000) < 64 Then FPutPixel(X, Y, Round(Stars(.I.).Z * 10), $A000);
        {Plot stars}
    End;

    GetBarValues;                     {Gets values to bar}
    If Bar1 < Bar1Temp Then           {Draws bars}
    Begin
      K := Bar1Temp;
      Repeat
        BlackHorLine(76, 200 - K, 41);
        K := K - 2;
      Until K <= Bar1;
    End
    Else
    Begin
      K := Bar1Temp;
      Repeat
        HorLine(76, 200 - K, 41);
        K := K + 2;
      Until K >= Bar1;
    End;

    If Bar2 < Bar2Temp Then
    Begin
      K := Bar2Temp;
      Repeat
        BlackHorLine(118, 200 - K, 41);
        K := K - 2;
      Until K <= Bar2;
    End
    Else
    Begin
      K := Bar2Temp;
      Repeat
        HorLine(118, 200 - K, 41);
        K := K + 2;
      Until K >= Bar2;
    End;

    If Bar3 < Bar3Temp Then
    Begin
      K := Bar3Temp;
      Repeat
        BlackHorLine(160, 200 - K, 41);
        K := K - 2;
      Until K <= Bar3;
    End
    Else
    Begin
      K := Bar3Temp;
      Repeat
        HorLine(160, 200 - K, 41);
        K := K + 2;
      Until K >= Bar3;
    End;

    If Bar4 < Bar4Temp Then
    Begin
      K := Bar4Temp;
      Repeat
        BlackHorLine(202, 200 - K, 41);
        K := K - 2;
      Until K <= Bar4;
    End
    Else
    Begin
      K := Bar4Temp;
      Repeat
        HorLine(202, 200 - K, 41);
        K := K + 2;
      Until K >= Bar4;
    End;

    If ArrayCounter < ArraySize Then Inc(ArrayCounter) Else ArrayCounter := 1;

    SetInten(sverre);
    MasterVolume(sverre);



  END;

  {FADES OUT}
  FOR i := 0 TO 767 DO GetCol(i, col[i].r, col[i].g, col[i].b); {Reads Colors}

  StopPlaying;                        {Stop the module}
  DeAlloc;                            {Remove the module}

End;                                  {Procedure Part_I}


Procedure Part_II;
{The part with the 3D-bars}

Var
  FontCount, X2, Y2, CX, CY : Integer;
  M, MessageCounter : ShortInt;
{  Rgbs : RgbsType;}

Procedure Text;
{Puts the text into the screenvariable}

Procedure Calculate(S : String);

Begin
  FontString(((320 - (Length(S) * FontSizeX)) Div 2) - 9, 162, S, Seg(ScrP^))
End;


Begin
  Case MessageCounter Of
     1 : Calculate('Hi');
     2 : Calculate('Life Sucks');
     3 : Calculate('And');
     4 : Calculate('so do we');
     5 : Calculate('This is');
     6 : Calculate('just a');
     7 : Calculate('little');
     8 : Calculate('piece for');
     9 : Calculate('the');
     10 : Calculate('melhus');
     11 : Calculate('party');
     12 : Calculate(' ');
     13 : Calculate('It will');
     14 : Calculate('not be');
     15 : Calculate('released');
     16 : Calculate('for the');
     17 : Calculate('public');
     18 : Calculate('Sorry');
     19 : Calculate('Coke');
     20 : Calculate('bugg');
     21 : Calculate('and');
     22 : Calculate('the');
     23 : Calculate('lost');
     24 : Calculate('souls');
     25 : Calculate('vilvi');
     26 : Calculate('thi hi');
     27 : Calculate('amiga');
     28 : Calculate('stinkar');
     29 : Calculate(' ');
     30 : Calculate(' ');
     31 : Calculate(' ');
     32 : Calculate(' ');
     33 : Calculate('Press key');
  End;
End;                                  {Procedure Text}

Procedure GetValues;
{Gets values from bar}

Begin
  Bar1Temp := Bar1;
  Bar1 := BopBar(1);
  Bar2Temp := Bar2;
  Bar2 := BopBar(2);
  Bar3Temp := Bar3;
  Bar3 := BopBar(3);
  Bar4Temp := Bar4;
  Bar4 := BopBar(4);
End;                    {Procedure GetValues}

Procedure BackHorLine(X1, Y1, Length : Integer);
{Draws a line with colors taken from screenvariable}

Begin
  For L := X1 To X1 + Length Do FPutPixel(L, Y1, ScrP^(.((Y1 - 1) * 320) + L.), $A000);
End;                                  {Procedure HorLine}

Procedure HorLine(X1, Y1, Length : Integer; Color : Byte);
{Draws a line in the specified color}

Begin
  For L := X1 To X1 + Length Do FPutPixel(L, Y1, Color, $A000);
End;      {Procedure HorLine}

Procedure BlackHorLine(X1, Y1, Length : Integer);
{Draws a totally black line}

Begin
  For L := X1 To X1 + Length Do FPutPixel(L, Y1, 0, $A000);
End;      {Procedure BlackHorLine}

Begin
  LoadModule('tiá5.tls');         {Load the module}
  LoadFont('TIá2.tls');
  GetPicturePalette('tiá7.tls', Rgbs); {Loads picturepalette}

  Set256Palette(Rgbs);                {Sets palette}

  For I := 1 To NumStars DO
  Begin
    Stars(.I.).X := Random(520) - 100;  {Random positions}
    Stars(.I.).Y := Random(240) - 100;  {Random positions}
    Stars(.I.).Z := (Random(63) + 1) / 10;
  End;

  Bar1 := 0;                          {Bar startvalues}
  Bar2 := 0;
  Bar3 := 0;
  Bar4 := 0;
  M := -1;                            {Centercounter startvalue}
  C := 1;
  CX := 160;                          {CenterX and Y startvalues}
  CY := 100;
  MessageCounter := 0;
  FontCount := 0;

  ViewPicture('tiá7.tls');
  FOR i := 0 TO 767 DO GetCol(i, col[i].r, col[i].g, col[i].b); {Reads Colors}

  StartPlaying;

  Repeat                              {Intro}
    For I := 1 To NumStars Do
    Begin
      XYZ(Stars(.I.).X, Stars(.I.).Y, CX - M, CY, Stars(.I.).Z, X, Y);
        {Calculate old star position}
      If FGetPixel(X, Y, $A000) < 64 Then FPutPixel(X, Y, 0, $A000);  {Delete star}
      Stars(.I.).Z := Stars(.I.).Z - Speed;             {Increase Z}
      If (Stars(.I.).Z < 0.1) Or (Y >= 140) Then Stars(.I.).Z := 6.3;   {Check starpos}
      XYZ(Stars(.I.).X, Stars(.I.).Y, CX, CY, Stars(.I.).Z, X, Y);
        {Calculate new star pos}
      If FGetPixel(X, Y, $A000) < 64 Then FPutPixel(X, Y, Round(Stars(.I.).Z * 10), $A000);
        {Plot new star}
    End;

      {Calculates and removes old bars}
    XYZ(60, 200, CX - M, CY, ((64 - Bar1Temp) / 20) + 2, X, Y);
    XYZ(100, 200, CX - M, CY, ((64 - Bar1Temp) / 20) + 2, X2, Y2);
    BlackHorLine(X, Y, X2 - X);

    XYZ(110, 200, CX - M, CY, ((64 - Bar2Temp) / 20) + 2, X, Y);
    XYZ(150, 200, CX - M, CY, ((64 - Bar2Temp) / 20) + 2, X2, Y2);
    BlackHorLine(X, Y, X2 - X);

    XYZ(160, 200, CX - M, CY, ((64 - Bar3Temp) / 20) + 2, X, Y);
    XYZ(200, 200, CX - M, CY, ((64 - Bar3Temp) / 20) + 2, X2, Y2);
    BlackHorLine(X, Y, X2 - X);

    XYZ(210, 200, CX - M, CY, ((64 - Bar4Temp) / 20) + 2, X, Y);
    XYZ(250, 200, CX - M, CY, ((64 - Bar4Temp) / 20) + 2, X2, Y2);
    BlackHorLine(X, Y, X2 - X);

      {Calculates and draws new bars}
    XYZ(60, 200, CX, CY, ((64 - Bar1) / 20) + 2, X, Y);
    XYZ(100, 200, CX, CY, ((64 - Bar1) / 20) + 2, X2, Y2);
    HorLine(X, Y, X2 - X, 64 - Bar1 + 64);

    XYZ(110, 200, CX, CY, ((64 - Bar2) / 20) + 2, X, Y);
    XYZ(150, 200, CX, CY, ((64 - Bar2) / 20) + 2, X2, Y2);
    HorLine(X, Y, X2 - X, 64 - Bar2 + 64);

    XYZ(160, 200, CX, CY, ((64 - Bar3) / 20) + 2, X, Y);
    XYZ(200, 200, CX, CY, ((64 - Bar3) / 20) + 2, X2, Y2);
    HorLine(X, Y, X2 - X, 64 - Bar3 + 64);

    XYZ(210, 200, CX, CY, ((64 - Bar4) / 20) + 2, X, Y);
    XYZ(250, 200, CX, CY, ((64 - Bar4) / 20) + 2, X2, Y2);
    HorLine(X, Y, X2 - X, 64 - Bar4 + 64);

    If (CX > 320) Or (CX < 0) Then M := -(M);
      {Check centerpos}
    CX := CX + M;

    GetValues;                        {Get new barvalues}

    If (FontCount Mod 100) = 0 Then   {We want some TEXT!}
    Begin
      C := 2;
      J := 161;
      FontCount := 0;
      Inc(MessageCounter);
      FillChar(Mem(.Seg(ScrP^) : 51200.), 12800, 0);
      Text;
    End;

    If C <> 0 Then                    {Displays the text}
    Begin
      BackHorLine(1, J, 319);
      J := J + C;
      If J >= 200 Then
      Begin
        C := -(C);
        J := J - 1;
      End;
      If J <= 161 Then
      Begin
        C := 0;
        J := 2;
      End;
    End;

    Inc(FontCount);

  Until KeyPressed;                   {Tja??}


  FOR sverre := 64 DOWNTO 1 DO
  BEGIN                              {Intro}
    For I := 1 To NumStars Do
    Begin
      XYZ(Stars(.I.).X, Stars(.I.).Y, CX - M, CY, Stars(.I.).Z, X, Y);
        {Calculate old star position}
      If FGetPixel(X, Y, $A000) < 64 Then FPutPixel(X, Y, 0, $A000);  {Delete star}
      Stars(.I.).Z := Stars(.I.).Z - Speed;             {Increase Z}
      If (Stars(.I.).Z < 0.1) Or (Y > 150) Then Stars(.I.).Z := 6.3;   {Check starpos}
      XYZ(Stars(.I.).X, Stars(.I.).Y, CX, CY, Stars(.I.).Z, X, Y);
        {Calculate new star pos}
      If FGetPixel(X, Y, $A000) < 64 Then FPutPixel(X, Y, Round(Stars(.I.).Z * 10), $A000);
        {Plot new star}
    End;

      {Calculates and removes old bars}
    XYZ(60, 200, CX - M, CY, ((64 - Bar1Temp) / 20) + 2, X, Y);
    XYZ(100, 200, CX - M, CY, ((64 - Bar1Temp) / 20) + 2, X2, Y2);
    BlackHorLine(X, Y, X2 - X);

    XYZ(110, 200, CX - M, CY, ((64 - Bar2Temp) / 20) + 2, X, Y);
    XYZ(150, 200, CX - M, CY, ((64 - Bar2Temp) / 20) + 2, X2, Y2);
    BlackHorLine(X, Y, X2 - X);

    XYZ(160, 200, CX - M, CY, ((64 - Bar3Temp) / 20) + 2, X, Y);
    XYZ(200, 200, CX - M, CY, ((64 - Bar3Temp) / 20) + 2, X2, Y2);
    BlackHorLine(X, Y, X2 - X);

    XYZ(210, 200, CX - M, CY, ((64 - Bar4Temp) / 20) + 2, X, Y);
    XYZ(250, 200, CX - M, CY, ((64 - Bar4Temp) / 20) + 2, X2, Y2);
    BlackHorLine(X, Y, X2 - X);

      {Calculates and draws new bars}
    XYZ(60, 200, CX, CY, ((64 - Bar1) / 20) + 2, X, Y);
    XYZ(100, 200, CX, CY, ((64 - Bar1) / 20) + 2, X2, Y2);
    HorLine(X, Y, X2 - X, 64 - Bar1 + 64);

    XYZ(110, 200, CX, CY, ((64 - Bar2) / 20) + 2, X, Y);
    XYZ(150, 200, CX, CY, ((64 - Bar2) / 20) + 2, X2, Y2);
    HorLine(X, Y, X2 - X, 64 - Bar2 + 64);

    XYZ(160, 200, CX, CY, ((64 - Bar3) / 20) + 2, X, Y);
    XYZ(200, 200, CX, CY, ((64 - Bar3) / 20) + 2, X2, Y2);
    HorLine(X, Y, X2 - X, 64 - Bar3 + 64);

    XYZ(210, 200, CX, CY, ((64 - Bar4) / 20) + 2, X, Y);
    XYZ(250, 200, CX, CY, ((64 - Bar4) / 20) + 2, X2, Y2);
    HorLine(X, Y, X2 - X, 64 - Bar4 + 64);

    If (CX > 320) Or (CX < 0) Then M := -(M);
      {Check centerpos}
    CX := CX + M;

    GetValues;                        {Get new barvalues}

    If (FontCount Mod 100) = 0 Then   {We want some TEXT!}
    Begin
      C := 2;
      J := 161;
      FontCount := 0;
      Inc(MessageCounter);
      FillChar(Mem(.Seg(ScrP^) : 38400.), 25600, 0);
      Text;
    End;

    If C <> 0 Then                    {Displays the text}
    Begin
      BackHorLine(1, J, 319);
      J := J + C;
      If J >= 200 Then
      Begin
        C := -(C);
        J := J - 1;
      End;
      If J <= 161 Then
      Begin
        C := 0;
        J := 2;
      End;
    End;

    Inc(FontCount);

    SetInten(sverre);
    MasterVolume(sverre);


  END;                      {Tja??}
  
  StopPlaying;                        {Stop the module}
  DeAlloc;                            {Remove the module}
  RemoveFont;                         {Removes font from memory}
End;                                  {Procedure Part_II}


Begin                                 {Main program}
  Randomize;                          {Totally random}
  GetMem(ScrP, SizeOf(ScrP^) * 64000);

  LoadOvl('tiá3.tls');            {Load the moduleplayer}
  AskInit;			      {Ask user about sounddevice}
  Initialize;                         {Initialize the player}

    FOR i := 0 TO 767 DO GetCol(i, col[i].r, col[i].g, col[i].b); {Reads Colors}

    FOR i := 64 DOWNTO 1 DO
    BEGIN
      Setinten(i);
      Delay(10);
    END;
  InitScreen($13);                    {Fixes graphics screen}

  Part_II;                            {Starts INTRODEMO!!!}
  Ch := ReadKey;

  If Ch = Chr(27) Then Goto 1;

  FillChar(Mem(.$A000 : 0000.), 64000, 0); {Clear screen}

  Part_I;
  Ch := ReadKey;
  Goto 1;

  1 :

{  GetPicturePalette('tiá4.tls', Rgbs);{Get the palette from picture}
{  Set256Palette(Rgbs);}

  RemoveOvl;	                      {Remove the moduleplayer}
  FreeMem(Scrp, SizeOf(ScrP^) * 64000);{Frees dynamic screenvariable}

  InitScreen($2);           {Init old DOS-screen}

  TextColor(White);
  Writeln('The first piece of coding from TLS has now reached its end.');
  Writeln('Hope you all enjoyed it even though its not something extraordinary');
  Writeln('Bye For Now');

  FOR i := 1 TO 63 DO
  BEGIN
    SetRGBColor(I, I, I, White);
    delay(20);
  END;

End.