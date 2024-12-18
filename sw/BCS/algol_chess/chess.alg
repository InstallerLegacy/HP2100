HPAL,L,B,"CHESS"
BEGIN 
COMMENT MINI-TECH - WRITTEN BY JIM GILLOGLY, JUNE 1971, 
MODIFIED, ANNOTATED AND ADAPTED FOR CLASS USE BY RON OHLANDER,
OCT 1971.  MODIFIED AND REANNOTATED BY JIM GILLOGLY, FEB L972.
TRANSLATED TO SAIL BY PAUL DANTZIG, MAY 1973. 
CHESS POSITIONAL ANALYSIS ADDED BY KEN POCEK, JUNE 1973.
ADAPTED TO HP ALGOL BY ED DOUST AND KEN POCEK, SEPT, 1973 
& 
& 
     THIS PROGRAM WILL PLAY CHESS BY GENERATING A "BEST MOVE" 
FROM A MINIMAX GAME TREE.  THE METHOD USED IS BRUTE FORCE.
ALTHOUGH ALPHA-BETA PRUNING IS UTILIZED, NO HEURISTICS ARE
EMBEDDED IN THE PROGRAM.
& 
     EVERY MOVE IS REPRESENTED BY A 32-BIT COMPUTER WORD. CERTAIN 
BITS OF THE WORD DENOTE GAME SITUATIONS AND WILL REMAIN CONSTANT
CASTLING RIGHTS. IN GENERAL THE FIELDS OF A MOVE WORD HAVE THE
FOR EACH MOVE UNLESS CHANGED.  FOR EXAMPLE, BITS 20-23 DENOTE 
SIGNIGICANCE SPECIFIED BELOW. 
& 
& 
          <0,7> - BOARD POSITION MOVED TO,
          <7,7> - BOARD POSITION MOVED FROM,
          <14,2> - PROMOTION PIECE VALUE, 
          <16,1> - EN PASSANT CAPTURE,
          <17,1> - NORMAL PIECE CAPTURE,
          <18,1> - OCCURRENCE OF A PROMOTION, 
          <19,1> - OCCURRENCE OF CASTLING,
          <20,2> - BLACK CASTLING RIGHTS, 
          <22,2> - WHITE CASTLING RIGHTS, 
          <24,3> - PIECE CAPTURED,
          <27,1> - DENOTES PLAYER WHO MADE THE MOVE, (1=W,0=B)
          <28,1> - THIS IS THE FIRST MOVE OF A GROUP
                   (TRUE OF FALSE), 
          <31,1> - SUCCESSORS OF THIS MOVE HAVE BEEN CONSIDERED.
& 
& 
     THE BOARD REPRESENTATION IS STORED IN A 120-WORD ARRAY. WORDS
21 - 28, 31 - 38, ..., 91 - 98 REPRESENT THE 64 SQUARES OF THE
CHESS BOARD.  THE REMAINDER OF THE ARRAY FORMS A BUFFER AROUND
THE BOARD THAT INDICATES THAT  A MOVE HAS TAKEN A PIECE OFF THE 
GAME BOARD. THE WORDS OF THE ARRAY WILL HOLD AN INTEGER FROM
-6 TO 7. THE NUMBERS HAVE THE FOLLOWING SIGNIFICANCE. 
& 
& 
          0 - MEANS THE SQUARE IS EMPTY,
    -1 OR 1 - MEANS THE SQUARE IS OCCUPIED BY A PAWN, 
    -2 OR 2 - MEANS THE SQUARE IS OCCUPIED BY A KNIGHT, 
    -3 OR 3 - MEANS THE SQUARE IS OCCUPIED BY A BISHOP, 
    -4 OR 4 - MEANS THE SQUARE IS OCCUPIED BY A ROOK, 
    -5 OR 5 - MEANS THE SQUARE IS OCCUPIED BY A QUEEN,
    -6 OR 6 - MEANS THE SQUARE IS OCCUPIED BY A KING, 
          7 - MEANS THE SQUARE IS OFF THE BOARD.
& 
& 
& 
& 
     IF A PIECE IS INDICATED, POSITIVE DENOTES WHITE, 
NEGATIVE BLACK. THE VECTOR SHOULD BE VISUALIZED AS SHOWN. 
& 
& 
     110  7   7   7   7   7   7   7   7   7   7 
& 
     100  7   7   7   7   7   7   7   7   7   7 
            --------------------------------- 
      90  7 !-4 !-2 !-3 !-5 !-6 !-3 !-2 !-4 ! 7 
            --------------------------------- 
      80  7 !-1 !-1 !-1 !-1 !-1 !-1 !-1 !-1 ! 7 
            --------------------------------- 
      70  7 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 7 
            --------------------------------- 
      60  7 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 7 
            --------------------------------- 
      50  7 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 7 
            --------------------------------- 
      40  7 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 0 ! 7 
            --------------------------------- 
      30  7 ! 1 ! 1 ! 1 ! 1 ! 1 ! 1 ! 1 ! 1 ! 7 
            --------------------------------- 
      20  7 ! 4 ! 2 ! 3 ! 5 ! 6 ! 3 ! 2 ! 4 ! 7 
            --------------------------------- 
      10  7   7   7   7   7   7   7   7   7   7 
& 
       0  7   7   7   7   7   7   7   7   7   7 
& 
          0   1   2   3   4   5   6   7   8   9   ; 
& 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
&    TO ALTER THE PROGRAM CONFIGURATION FOR VARIOUS ENVIRONMENTS
&    SUCH AS BCS, DOS-M ETC, CHANGE THE NEXT RECORD.
   EQUATE TTY:=1, KBD:=1, LISTU:=6; 
   EQUATE TREESIZE:=250;  &MAXIMUM SIZE OF TREE ARRAY 
  EQUATE MDEPTH:=3; & MAXIMUM NUMBER OF SEARCH LEVELS 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  INTEGER WHITEPOINTS, BLACKPOINTS, I, J, BW, T, F, S, DEPTH, 
    MATERIAL, TREEPTR, TRACPOS, MOVE, TOMOD10, FROMOD10, AT,
    WILL, PIECE, SQUARE, HERE, THERE; 
  INTEGER YOUCHECK, MYCHECK;
  INTEGER ARRAY PIECEVAL[1:6], AB[-1:9], OUTS[1:20], A[1:10], 
    POSITIONVAL[0:100], TREE[0:TREESIZE,1:2]; 
  INTEGER ARRAY B[0:119]:=
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 
    7, 4, 2, 3, 5, 6, 3, 2, 4, 7, 7, 1, 1, 1, 1, 1, 1, 1, 1, 7, 
    7, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 7, 
    7, 0, 0, 0, 0, 0, 0, 0, 0, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 7, 
    7,-1,-1,-1,-1,-1,-1,-1,-1, 7, 7,-4,-2,-3,-5,-6,-3,-2,-4, 7, 
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7; 
  INTEGER ARRAY CC[0:98]:=
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    0, 0, 1, 2, 3, 3, 2, 1, 0, 0, 0, 1, 3, 4, 5, 5, 4, 3, 1, 0, 
    0, 2, 4, 6, 7, 7, 6, 4, 2, 0, 0, 3, 5, 7, 8, 8, 7, 5, 3, 0, 
    0, 3, 5, 7, 8, 8, 7, 5, 3, 0, 0, 2, 4, 6, 7, 7, 6, 4, 2, 0, 
    0, 1, 3, 4, 5, 5, 4, 3, 1, 0, 0, 0, 1, 2, 3, 3, 2, 1, 0;
  INTEGER ARRAY PCVAL[0:12]:= 
    -15000,-900,-500,-330,-330,-100,0,100,330,330,500,900,15000;
  INTEGER ARRAY LM, MV, LMASK, PVAR, NEXT[1:2]; 
  INTEGER ARRAY PCS[0:6]:="  ","P ","N ","B ","R ","Q ","K "; 
  LABEL NMOVE, DONE;
  PROCEDURE BLANK(A); INTEGER ARRAY A; CODE;
  PROCEDURE IZERO(A); INTEGER ARRAY A; CODE;
  PROCEDURE CBITF(A,B,C); VALUE B,C; INTEGER A, B, C; CODE; 
  PROCEDURE SBITF(A,B,C,D); VALUE B, C, D;
    INTEGER A, B, C, D; CODE; 
  PROCEDURE SAVE(A,B,C,D); INTEGER A, B, C, D; CODE;
  PROCEDURE RETRO(A,B,C,D,E); INTEGER A, B, C, D, E; CODE;
  PROCEDURE ECUTE(A,B,C,D,E,F,G,H); INTEGER E, F, G, H; 
    INTEGER ARRAY A, B, C, D; CODE; 
  FORMAT
    SORTM(" SORT MOVES"/" MOVE"6X"FROM"8X"TO"5X"VALUE"/), 
    FSEEK(XI4,3(6XI4)), 
    CHECKMATE(" **CHECKMATE**"),
  DASH(6X,"---------------------------------"), 
    CHEK(" CHECK"), 
    CONCEDE(" DO YOU CONCEDE? _"),
  MIDFORM(/" MIDGAME"//31X"CENTER"3X"MOBI"3X"KING"4X"MID"/
   " MOVE"2X"PIECE"4X"FROM"4X"TO"2X"CONT'L"3X"LITY"2X"CHASE"
      3X"BONUS"3X"TOTAL"//),
    SERCH(A2,3I4,2(2XK6)),
    LIN2(XI3,5A2,2(2XI4)5(3XI5)), 
    OPENA(" OPENING ANAL."/" MOVE"2X"PIECE"4X"FROM"4X"TO"2X 
      "CONT'L"3X"BONUS"//), 
    SLECT("CHOICE: (B=1, W=-1) _"), 
    HEADER(/"HP CHESS VERSION A  10/26/73"//"DUMPS AVAILABLE:"/ 
          5X,"SW0 - MOVE LIST"/5X,"SW1 - BOTTOM NODE DUMP"/ 
          5X,"SW2 - FULL DUMP"///), 
    YTURN("YOUR TURN: FROM SQUARE? _"), 
    SEEIT(5(2XI5)6(2XK6)),
    ILL("ILLEGAL! TRY AGAIN"),
    F1(/"PIECE VALUES:"/"1=P, 2=N, 3=B, 4=R, 5=Q, 6=K"/ 
      "POSITIVE=WHITE, NEGATIVE=BLACK"/"TYPE SQUARE=0 TO END"), 
    SQ("SQUARE=? _"), PC("PIECE=? _"),
    YTURN2("TO SQUARE? _"); 
  OUTPUT BOARD(FOR J:=1 TO 20 DO[OUTS[J]]); 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE TRY;
  BEGIN FORMAT F1(4I5,XI6,6(2XK6)); 
    OUTPUT L1(F,BW,DEPTH,TREEPTR,MATERIAL,TREE[TREEPTR,2],
      TREE[TREEPTR,1],NEXT[2],NEXT[1],LM[2],LM[1]); 
    WRITE(LISTU,F1,L1)
  END OF TRY; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE BUMP; 
  BEGIN TREEPTR:=TREEPTR+1; IF TREEPTR>TREESIZE THEN
    BEGIN WRITE(TTY,FSEEK,TREEPTR); GO DONE 
  END END OF BUMP;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE TYPEB;
  BEGIN FOR I:=90 STEP -10 UNTIL 20 DO
    BEGIN WRITE(LISTU,DASH); BLANK(OUTS); 
      OUTS[2]:=ROTATE((I\10) OR @60) OR @60;
      OUTS[20]:="! "; 
      FOR J:=1 TO 8 DO
      BEGIN OUTS[2*(J+1)]:=IF B[I+J]<0 THEN "!*" ELSE "! "; 
        OUTS[2*(J+1)+1]:=PCS[ABS(B[I+J])] 
      END; WRITE(LISTU,#(20A2),BOARD) 
    END; WRITE(LISTU,DASH); 
    WRITE(LISTU,#("0"4X,8(3XI1)//),FOR J:=1 TO 8 DO[J]) 
  END OF TYPEB; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE PUSHM;
  BEGIN LABEL ENTR, RTRUN; INTEGER FGTRO, FR, FLG;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  BOOLEAN PROCEDURE CHECK(I); INTEGER I;
  BEGIN LABEL EXITFOR; INTEGER TMP,TBACK; 
    INTEGER ARRAY TLMASK[1:2];
    TMP:=CBITF(LM[1],20,4); SBITF(LM[1],20,4,15); 
    TLMASK[1]:=LMASK[1]; TLMASK[2]:=LMASK[2]; 
    TBACK:=TREEPTR; F:=-F; FLG:=TRUE; GO ENTR;
RTRUN: FLG:=CHECK:=FALSE; 
    FOR J:=TBACK+1 TO TREEPTR DO
    IF CBITF(TREE[J,1],0,7)=I THEN
    BEGIN CHECK:=TRUE; GO EXITFOR END;
EXITFOR: F:=-F; TREEPTR:=TBACK; LMASK[1]:=TLMASK[1];
    LMASK[2]:=TLMASK[2]; SBITF(LM[1],20,4,TMP)
  END OF CHECK; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE CAS(A1,A2,A3,A4,A5,A6); 
  VALUE A1, A2, A3, A4, A5, A6; 
  INTEGER A1, A2, A3, A4, A5, A6; 
  BEGIN INTEGER I; LABEL EXITCAS; 
    FOR I:=A3 TO A4 DO IF B[I]#0 THEN GO EXITCAS; 
    FOR I:=A1 TO A2 DO IF CHECK(I) THEN GO EXITCAS; BUMP; 
    TREE[TREEPTR,1]:=LMASK[1] OR A5*2^7 OR A6;
    TREE[TREEPTR,2]:=LMASK[2] OR @10; 
EXITCAS: END OF CAS;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE CASTL(A1,B1,A2,B2,A3,B3,A4);
  VALUE A1, B1, A2, B2, A3, B3, A4; 
  INTEGER A1, B1, A2, B2, A3, B3, A4; 
  BEGIN IF CBITF(LM[1],A1,B1)<3 THEN
    BEGIN IF CBITF(LM[1],A2,B2)=0 THEN
      CAS(A4,A4+2,A4+1,A4+2,A4,A4+2); 
      IF CBITF(LM[1],A3,B3)=0 THEN
      CAS(A4-2,A4,A4-3,A4-1,A4,A4-2)
  END END OF CASTL; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  COMMENT IF POSSIBLE MAKE KING OR KNIGHT MOVE; 
  &* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  & 
    PROCEDURE KINGN(A1,A2,A3,A4,A5,A6,A7,A8); 
    VALUE A1, A2, A3, A4, A5, A6, A7, A8; 
    INTEGER A1,A2,A3,A4,A5,A6,A7,A8;
    FOR I:=8 STEP -1 UNTIL 1 DO 
    BEGIN LABEL EXITKN; INTEGER DST;
      CASE I BEGIN
        DST:=FR+A1;  DST:=FR+A2;  DST:=FR+A3;  DST:=FR+A4;
        DST:=FR+A5;  DST:=FR+A6;  DST:=FR+A7;  DST:=FR+A8 
      END; T:=B[DST]; IF T=7 THEN GO EXITKN;
      T:=IF FGTRO=1 THEN -T ELSE T; 
      IF T<0 THEN GO EXITKN; BUMP;
& 
&  IF T=0 THEN REGULAR MOVE ELSE A CAPTURE
& 
      TREE[TREEPTR,1]:=LMASK[1] OR DST; 
      TREE[TREEPTR,2]:=LMASK[2] OR
      (IF T=0 THEN 0 ELSE (2 OR T*2^8));
EXITKN: END OF KINGN; 
  & 
  &* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
&  IF POSSIBLE MAKE THE BISHOP, ROOK OR QUEEN MOVE; 
& 
    PROCEDURE BPRKQN(NUM,A1,A2,A3,A4,A5,A6,A7,A8);
    VALUE NUM, A1, A2, A3, A4, A5, A6, A7, A8;
    INTEGER NUM, A1, A2, A3, A4, A5, A6, A7, A8;
    FOR I:=NUM STEP -1 UNTIL 0 DO 
    BEGIN INTEGER DST; LABEL EXITBRQ; 
      CASE I+1 BEGIN
        S:=A1;  S:=A2;  S:=A3;  S:=A4;
        S:=A5;  S:=A6;  S:=A7;  S:=A8 
      END; DST:=FR; 
      WHILE TRUE DO BEGIN 
        DST:=DST+S; T:=B[DST]; IF T=7 THEN GO EXITBRQ;
        T:=IF FGTRO=1 THEN -T ELSE T; 
        IF T<0 THEN GO EXITBRQ; 
        BUMP; TREE[TREEPTR,2]:=LMASK[2];
        TREE[TREEPTR,1]:=LMASK[1] OR DST; 
        IF T#0 THEN BEGIN TREE[TREEPTR,2]:= 
          LMASK[2] OR @2 OR T*2^8;
          GO EXITBRQ
      END END;
EXITBRQ: END OF BPRKQN; 
  & 
  &* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  & 
    PROCEDURE PAWNC(D); VALUE D; INTEGER D; 
    BEGIN INTEGER T2; LABEL EXITPAWN; 
      T2:=B[D]; IF T2=7 THEN GO EXITPAWN; 
      T2:=IF FGTRO=1 THEN -T2 ELSE T2;
      IF T2>0 THEN
      BEGIN BUMP; TREE[TREEPTR,1]:=LMASK[1] OR D; 
        TREE[TREEPTR,2]:=LMASK[2] OR @2 OR T2*2^8 
      END ELSE
      IF (B[D-T]=-F) AND (D-T=CBITF(LM[1],0,7)) AND (D+T= 
        CBITF(LM[1],7,7)) THEN
      BEGIN BUMP; TREE[TREEPTR,1]:=LMASK[1] OR D; 
        TREE[TREEPTR,2]:=LMASK[2] OR @403 
      END;
EXITPAWN: END OF PAWNC; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE PROMO(TB,PTR); INTEGER TB,PTR;
  BEGIN INTEGER I,J;
  FOR I:=TB+1 TO PTR DO 
  BEGIN TREE[I,2]:=TREE[I,2] OR 4;
    FOR J:=1 TO 3 DO
    BEGIN PTR:=PTR+1; TREE[PTR,2]:=TREE[I,2]; 
      CASE J BEGIN
        TREE[PTR,1]:=TREE[I,1] OR @40000; 
        TREE[PTR,1]:=TREE[I,1] OR @100000;
        TREE[PTR,1]:=TREE[I,1] OR @140000 
    END END END 
  END OF PROMO; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
&  ACTUAL BEGINNING OF PUSHMOVE 
& 
    FLG:=FALSE; 
ENTR: FGTRO:=IF F>0 THEN 1 ELSE 0;
    LMASK[2]:=LM[2] AND @360; LMASK[1]:=0;
    SBITF(LMASK[1],27,1,FGTRO); 
& 
&  CONSIDER ALL POSSIBLE SQUARES; 
& 
    FOR SQUARE:=21 TO 98 DO 
    BEGIN INTEGER PC; LABEL NEXTSQUARE; 
      FR:=SQUARE; PC:=B[SQUARE];
      IF PC=0 OR PC=7 THEN GO NEXTSQUARE; 
      PC:=IF FGTRO>0 THEN PC ELSE -PC;
      IF PC<0 THEN GO NEXTSQUARE; 
      LMASK[1]:=(LMASK[1] AND @140177) OR FR*2^7; 
& 
&    CONSIDER POSSIBLE MOVES; 
& 
      CASE PC BEGIN 
        BEGIN & PAWN TO MOVE; 
          INTEGER UP1,TB; 
          T:=IF FGTRO>0 THEN 10 ELSE -10; 
          UP1:=FR+T; TB:=TREEPTR; 
&    CONSIDER PAWN CAPTURES;
          PAWNC(UP1-1); PAWNC(UP1+1); IF B[UP1]=0 THEN
          BEGIN BUMP; TREE[TREEPTR,1]:=LMASK[1] OR UP1; 
            TREE[TREEPTR,2]:=LMASK[2];
            IF FGTRO>0 THEN 
            BEGIN 
              IF (FR<39) AND (B[FR+20]=0) THEN
              BEGIN BUMP; 
                TREE[TREEPTR,1]:=(LMASK[1] OR (FR+20)); 
                TREE[TREEPTR,2]:=LMASK[2] 
              END END ELSE
              IF FR>80 AND B[FR-20]=0 THEN
              BEGIN BUMP; 
                TREE[TREEPTR,1]:=LMASK[1] OR FR-20; 
                TREE[TREEPTR,2]:=LMASK[2] 
            END END;
& 
&    PROMOTE A PAWN 
& 
          IF UP1>90 OR UP1<30 THEN PROMO(TB,TREEPTR)
          END OF PAWN SECTION;
          KINGN(-12,-21,-19,-8,12,21,19,8); & KNIGHT MOVES
          BPRKQN(3,-11,-9,11,9,0,0,0,0); & BISHOP MOVES 
          BPRKQN(3,-10,-1,10,1,0,0,0,0); & ROOK MOVES 
          BPRKQN(7,-10,-1,10,1,-11,-9,11,9); & QUEEN MOVES
          KINGN(-10,-1,10,1,-11,-9,11,9); & KING MOVES
        END;
NEXTSQUARE: END;
    IF FLG THEN GO RTRUN; 
    LMASK[1]:=LMASK[1] AND @140177; 
    IF FGTRO>0 THEN CASTL(22,2,22,1,23,1,25) ELSE 
    CASTL(20,2,20,1,21,1,95); 
    TREE[TREEPTR,2]:=TREE[TREEPTR,2] OR @10000
  END OF PUSHM; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE READM;
  BEGIN LABEL EXITWHILE, JUMPOUT, MOVERR; 
    INTEGER ORG, DST, C5; 
    TREEPTR:=DEPTH:=0; PUSHM; 
MOVERR: 
    MV[1]:=MV[2]:=0; TYPEB; 
  C5:=0;
    WRITE(TTY,YTURN); READ(KBD,*,ORG); IF ORG=0 THEN GO DONE; 
    WRITE(TTY,YTURN2); READ(KBD,*,DST); 
    IF (ABS(B[ORG])=1) AND ((DST>90) OR (DST<29)) THEN
    BEGIN 
      WRITE(TTY,#("PAWN =? _")); READ(KBD,*,C5);
      C5:=C5-2; 
    END; SBITF(MV[1],0,7,DST); SBITF(MV[1],7,7,ORG);
    SBITF(MV[1],14,2,C5); 
    FOR I:=0 TO TREEPTR DO IF MV[1]=TREE[I,1] THEN
    BEGIN MV[1]:=TREE[I,1]; MV[2]:=TREE[I,2]; GO EXITWHILE
    END; WRITE(TTY,ILL); GO MOVERR; 
EXITWHILE: TREEPTR:=0; SAVE(LM[1],B[21],MATERIAL,DEPTH);
    ECUTE(MV,LM,B,PCVAL,DEPTH,F,BW,MATERIAL); PUSHM;
    WRITE(LISTU,#( " YOU MOVED FROM ",I2," TO ",I2/),ORG,DST);
    FOR I:=0 TO TREEPTR DO
    IF B[CBITF(TREE[I,1],0,7)]=-6*BW THEN 
    BEGIN WRITE(TTY,CHEK); WRITE(TTY,CONCEDE);
      READ(KBD,#(A1),HERE); IF HERE=" Y" THEN GO DONE;
    END; FOR I:=0 TO TREEPTR DO 
    IF B[CBITF(TREE[I,1],0,7)]=-6*BW THEN 
    BEGIN WRITE(LISTU,CHEK); WRITE(TTY,CONCEDE);
      READ(KBD,*,HERE); IF HERE=1 THEN GO DONE; 
      GO JUMPOUT
    END; YOUCHECK:=0; 
JUMPOUT: IF YOUCHECK=1 THEN 
    BEGIN TREEPTR:=0; RETRO(LM[1],B[21],F,MATERIAL,DEPTH);
      GO MOVERR 
    END; MYCHECK:=TREEPTR:=0; F:=-F; PUSHM; 
    FOR I:=0 TO TREEPTR DO IF ABS(B[CBITF(TREE[I,1],0,7)])=6
    THEN BEGIN WRITE(LISTU,CHEK); MYCHECK:=1 END; 
    F:=-F 
  END OF READM; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
COMMENT 
& 
    THE POSITIONAL ANALYSIS ROUTINES THAT FOLLOW CONTAIN
ALL OF THE CHESS SPECIFIC HEURISTICS USED IN THIS ALGOL VERSION 
OF GILLOGLY'S MINI-TECH PROGRAM. THE NEED FOR THESE HEURISTICS
IS TWO-FOLD. FIRST IT REDUCES THE TIME NECESSARY FOR THE BRUTE
FORCE GAME TREE SEARCH PORTION OF THE PROGRAM (THE TACTICAL 
ANALYSIS PHASE) TO FIND A MOVE. IT DOES THIS BY PRE-SORTING 
THE MOVES AT THE TOP LEVEL (DEPTH=1) SO THAT THE MOVE WHICH HAS 
THE BEST SUPERFICIAL POSITIONAL SCORE IS CONSIDERED FIRST.
SECONDLY, IT ALLOWS MINI-TECH TO GET THROUGH THE OPENING AND
MIDGAMES WITHOUT HAVING A HOPELESS POSITIONAL DISADVANTAGE DUE
TO ITS LIMITED TREE SEARCH CAPABILITY (ONLY 3 PLIES DEEP).
& 
& 
                  ********    THE OPENING    *****
& 
& 
  THE OPENING IS DEFINED TO BE THE FIRST EIGHT MOVES. THE MOST
IMPORTANT HEURISTIC IN THE OPENING EVALUATION IS OCCUPATION OF
THE CENTER (SEE PROCEDURE CENCON). EACH SQUARE ON THE BOARD IS
WEIGHTED WITH A DESIRABILITY VALUE RANGING FROM 0 POINTS FOR THE
CORNERS TO 8 POINTS FOR THE CENTER (SEE ARRAY CC). EACH MOVE
REPRESENTS A NET GAIN OR LOSS OF CENTRALITY. FOR EXAMPLE, N-KB3 
WOULD YIELD A GAIN OF 5 POINTS IN CENTRALITY. THIS IS MULTIPLIED
BY THE PRIORITY FACTOR FOR THE PIECE TO MOVE: P=1, N=4, B=3, R=2, 
Q=1 AND K=-1. THUS N-KB3 WOULD HAVE A FINAL SCORE OF 20 POINTS
FOR CENTRALITY. NOTICE THAT THE KING IS ENCOURAGED TO MOVE AWAY 
FROM THE CENTER IN THE OPENING, SINCE ITS CENTER-TROPISM FACTOR 
IS NEGATIVE. THIS HEURISTIC ALONE DICTATES A VERY REASONABLE
OPENING WITH RAPID DEVELOPMENT. 
& 
  EACH MOVE IS GIVEN A FINAL POSITIONAL SCORE OF THE CENTRALITY 
TERM PLUS THE VALUE OF EACH OF THE FOLLOWING HEURISTICS WHICH 
APPLIES TO IT. SEE PROCEDURE OPENB. 
& 
     PAWN FROM K2 TO K4:       30 POINTS
     PAWN FROM K3 TO K4:        2 POINTS
     PAWN FROM Q2 TO Q4:       20 POINTS
     PAWN FROM Q3 TO Q4:        2 POINTS
     O - O                     30 POINTS
     O - O - O                 10 POINTS
     N - R3                   -15 POINTS
     PIECE TO K3 OR Q3 BLOCKING A PAWN       -50
     PIECE MOVING FROM KING SIDE               2 POINTS 
     PLAYING PETROFF DEFENCE                 -50 POINTS 
     CAPTURE WITH PAWN TOWARD CENTER           5 POINTS 
     CAPTURE WITH PAWN AWAY FROM CENTER       -5 POINTS 
     PAWN CAPTURE LEADING TO MULTIPLE 
          ISOLATED PAWNS                     -10 POINTS 
     WING PAWN ADVANCE                       -10 POINTS 
     CAPTURE UNSUPPORTED CENTER PAWN          50 POINTS 
     CAPTURE SUPPORTED CENTER PAWN           -15 POINTS 
& 
& 
                  ********    MIDDLE GAME    ******** 
& 
  THE MIDDLE GAME BEGINS WITH THE NINTH MOVE AND CONTINUES
UNTIL ONE SIDE HAS LESS THAN 1950 POINTS WORTH OF MATERIAL. 
EXCLUDING THE KING (EACH SIDE HAS 4020 IN THE INITIAL POSITION),
(SEE PROCEDURE MDGAME). THE CENTER CONTROL HEURISTIC IS STILL 
USED, BUT THE PRIORITY FACTORS ARE SLIGHTLY ALTERED: P=3, N=4,
B=3, R=2, Q=1, AND K=1. SINCE MOST PIECES HAVE FOUND THEIR BEST 
SQUARES BY THE MIDDLE GAME, THIS FACTOR HAS LESS INGLUENCE THAN 
IN THE OPENING. EACH MOVE IS CREDITED WITH A MOBILITY TERM (SEE 
PROCEDURE MOBILE), WHICH IS THE NUMBER OF POTENTIALLY LEGAL MOVES 
AVAILABLE AFTER THE MOVE IS MADE. MOVEMENT OF A PIECE INTO THE
OPPONENT'S KING FIELD IS REWARDED IN THE SAME WAY AS THE CENTER 
CONTROL HEURISTIC, AND THE NET GAIN IS AGAIN MULTIPLIED BY THE
PRIORITY FOR THAT PIECE (SEE PROCEDURE KINCH). THIS HEURISTIC 
OCCASIONALLY RESULTS IN A KING-SIDE ATTACK. 
& 
  THE PAWN HEURISTICS ARE THE SAME AS IN THE OPENING, EXCEPT
THAT ADVANCES OF WING PAWNS GET -5 INSTEAD OF -10. CASTLING 
VALUES ARE THE SAME AS IN THE OPENING. IF TECH IS AHEAD IN
MATERIAL,PIECE CAPTURES GET 10 POINTS MORE. MOVING A PIECE
WHICH BLOCKS THE KBP OR QBP IS REWARDED WITH 5 POINTS.          ; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  INTEGER PROCEDURE CENCON(I); INTEGER I; 
  BEGIN INTEGER CNTRCOEFF, AT, WILLBE;
    AT:=CBITF(TREE[I,1],0,7); WILLBE:=CBITF(TREE[I,1],7,7); 
    CNTRCOEFF:=CC[AT]-CC[WILLBE]; 
    CENCON:=CNTRCOEFF*PIECEVAL[ABS(B[WILLBE])]
  END OF CENCON;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE SORT; 
  BEGIN INTEGER I, TEMP, FLAG; LABEL LOOP;
  OUTPUT SEEK(I,CBITF(TREE[I,1],7,7),CBITF(TREE[I,1],0,7)); 
LOOP: FLAG:=FALSE; FOR I:=1 TO TREEPTR-1 DO 
    BEGIN IF POSITIONVAL[I]>POSITIONVAL[I+1] THEN 
      BEGIN TEMP:=TREE[I,1]; TREE[I,1]:=TREE[I+1,1];
        TREE[I+1,1]:=TEMP; TEMP:=TREE[I,2]; 
        TREE[I,2]:=TREE[I+1,2]; TREE[I+1,2]:=TEMP;
        TEMP:=POSITIONVAL[I]; POSITIONVAL[I]:=POSITIONVAL[I+1]; 
        POSITIONVAL[I+1]:=TEMP; FLAG:=TRUE
    END END;
   IF FLAG THEN GO LOOP;  IF (KEYS AND 1)=1 THEN
    BEGIN WRITE(LISTU,SORTM); FOR I:=1 TO TREEPTR DO
      WRITE(LISTU,FSEEK,SEEK,POSITIONVAL[I])
  END END OF SORT;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  BOOLEAN PROCEDURE MDGAME; 
  BEGIN INTEGER I, J, PV; 
    WHITEPOINTS:=BLACKPOINTS:=0; MDGAME:=FALSE; 
    FOR I:=1 TO 8 DO FOR J:=20 STEP 10 UNTIL 90 DO
    BEGIN PV:=B[I+J]; 
      IF PV>0 THEN WHITEPOINTS:=WHITEPOINTS+PCVAL[PV+6];
      IF PV<0 THEN BLACKPOINTS:=BLACKPOINTS-PCVAL[PV+6] 
    END; WHITEPOINTS:=WHITEPOINTS-15000;
    BLACKPOINTS:=BLACKPOINTS-15000; 
    IF WHITEPOINTS OR BLACKPOINTS THEN
    BEGIN WRITE(TTY,CHECKMATE); GO DONE END;
    IF (WHITEPOINTS>1950) OR (BLACKPOINTS>1950) THEN
  MDGAME:=TRUE;  IF (KEYS AND 1)=1 THEN 
    WRITE(LISTU,#(XI5" WHITEPOINTS VS"I5" BLACKPOINTS"),
      WHITEPOINTS,BLACKPOINTS)
  END OF MDGAME;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  INTEGER PROCEDURE MOBILE(I); INTEGER I; 
  BEGIN INTEGER TEMP; INTEGER ARRAY MV[1:2];
    MV[1]:=TREE[I,1]; MV[2]:=TREE[I,2]; TEMP:=TREEPTR;
    SAVE(LM[1],B[21],MATERIAL,DEPTH); 
    ECUTE(MV,LM,B,PCVAL,DEPTH,F,BW,MATERIAL); PUSHM;
    MOBILE:=TREEPTR-TEMP; TREEPTR:=TEMP;
    RETRO(LM[1],B[21],F,MATERIAL,DEPTH) 
  END OF MOBILE;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  INTEGER PROCEDURE KINGCH(I); INTEGER I; 
  BEGIN INTEGER ROW, COLUMN, TOROW, TOCOLUMN, OPPKING, J; 
    LABEL EXITLOOP; FOR J:=21 TO 98 DO
    IF B[J]=-F*6 THEN OPPKING:=J; 
    ROW:=OPPKING\10; COLUMN:=OPPKING MOD 10;
    KINGCH:=0; TOCOLUMN:=CBITF(TREE[I,1],0,7) MOD 10; 
    TOROW:=CBITF(TREE[I,1],0,7)\10; 
  & 
  &    IF MOVE BRINGS PIECE 1 SQUARE AWAY, BONUS=10,
  &    2 AWAY, BONUS=8 AND 3 AWAY, BONUS=2
  & 
    FOR J:=1 TO 3 DO
    BEGIN IF TOROW<ROW+J AND TOROW>ROW-J
      AND((TOCOLUMN=COLUMN+J) OR (TOCOLUMN=COLUMN-J)) 
      THEN KINGCH:=(IF J=1 THEN 10 ELSE IF J=2 THEN 8 ELSE 2);
      IF ((TOROW=ROW+J) OR (TOROW=ROW-J)) AND 
      ((TOCOLUMN<COLUMN+J+1) AND (TOCOLUMN>COLUMN-J-1)) 
      THEN KINGCH:=(IF J=1 THEN 10 ELSE IF J=2 THEN 8 ELSE 2);
      IF KINGCH>0 THEN GO EXITLOOP
    END; KINGCH:=0; 
EXITLOOP: KINGCH:=KINGCH*PIECEVAL[ABS(B[CBITF(TREE[I,1],7,7)])] 
  END OF KINGCH;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  INTEGER PROCEDURE OPENB(I); INTEGER I;
  BEGIN LABEL JUMPOUT, RETN; INTEGER J, TBTREEPTR;
    OPENB:=0; AT:=CBITF(TREE[I,1],0,7); 
    WILL:=CBITF(TREE[I,1],7,7); 
    TOMOD10:=AT MOD 10; FROMOD10:=WILL MOD 10;
    IF F=1 THEN 
    BEGIN A[1]:=35; A[2]:=45; A[3]:=55; A[4]:=34; A[5]:=44; 
      A[6]:=54; A[7]:=27; A[8]:=23; A[9]:=41; A[10]:=48 
    END ELSE
    BEGIN A[1]:=85; A[2]:=75; A[3]:=65; A[4]:=84; A[5]:=74; 
      A[6]:=64; A[7]:=97; A[8]:=93; A[9]:=71; A[10]:=78 
    END; IF B[WILL]=F THEN
    BEGIN 
      IF (WILL=A[1]) AND (AT=A[3]) THEN OPENB:=30;
      IF (WILL=A[2]) AND (AT=A[3]) THEN OPENB:=2; 
      IF (WILL=A[4]) AND (AT=A[6]) THEN OPENB:=20;
      IF (WILL=A[5]) AND (AT=A[6]) THEN OPENB:=2; 
      IF OPENB>0 THEN GO RETN 
    END; IF CBITF(TREE[I,1],19,1)=1 THEN
    BEGIN IF AT=A[7] THEN OPENB:=30;
      IF AT=A[8] THEN OPENB:=10; GO RETN
    END; IF (B[WILL]=2*F) AND ((AT=A[9]) OR (AT=A[10])) THEN
    BEGIN OPENB:=-15; GO RETN END;
    IF ((B[A[4]]=F) AND (AT=A[5])) OR 
    ((B[A[1]]=F) AND (AT=A[2])) THEN
    IF (NOT(B[WILL]=F)) THEN
    BEGIN OPENB:=-50; GO RETN END;
    IF TOMOD10>4 THEN OPENB:=OPENB+2; 
    IF CBITF(TREE[I,1],16,2)>0 AND (B[AT]=-F) THEN
    BEGIN OPENB:=OPENB-5; 
      IF ((FROMOD10<5) AND (TOMOD10>FROMOD10)) THEN 
      OPENB:=OPENB+10;
      IF (FROMOD10>4) AND (TOMOD10<FROMOD10) THEN 
      OPENB:=OPENB+10 
    END;
    IF (CBITF(TREE[I,1],16,2)>0) AND (B[AT]=-F) THEN
    FOR J:=1 TO 9 DO
    IF B[10*J+TOMOD10]=F THEN OPENB:=OPENB-10;
    IF (B[WILL]=F) AND ((FROMOD10<4) OR (FROMOD10>5)) 
    THEN OPENB:=OPENB-10; 
    IF ((CBITF(TREE[I,1],16,2)>0) AND (B[AT]=-F)) 
    AND ((TOMOD10=4) OR (TOMOD10=5)) THEN 
    BEGIN TBTREEPTR:=TREEPTR; SAVE(LM[1],B[21],MATERIAL,DEPTH); 
      MV[1]:=TREE[I,1]; MV[2]:=TREE[I,2]; 
      ECUTE(MV,LM,B,PCVAL,DEPTH,F,BW,MATERIAL); PUSHM;
      FOR J:=TBTREEPTR+1 TO TREEPTR DO
      IF (CBITF(TREE[I,1],0,7)=AT) AND
      (CBITF(TREE[J,1],16,2)>0) THEN
      BEGIN OPENB:=OPENB-15; GO JUMPOUT END;
      OPENB:=OPENB+50;
JUMPOUT: RETRO(LM[1],B[21],F,MATERIAL,DEPTH); TREEPTR:=TBTREEPTR
    END;
RETN: END OF OPENB; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  INTEGER PROCEDURE MDBON(I); INTEGER I;
  BEGIN INTEGER J;
    MDBON:=OPENB(I); WILL:=CBITF(TREE[I,1],7,7);
    FROMOD10:=WILL MOD 10; AT:=CBITF(TREE[I,1],0,7);
    TOMOD10:=AT MOD 10; A[3]:=0;
    IF F=1 THEN BEGIN 
      A[1]:=36; A[2]:=46; A[4]:=33; A[5]:=43 END
    ELSE BEGIN
      A[1]:=86; A[2]:=76; A[4]:=83; A[5]:=73 END; 
    IF (B[WILL]=F) AND ((FROMOD10<4) OR (FROMOD10>5)) 
    THEN MDBON:=MDBON+5;
    IF ((BW=1) AND (WHITEPOINTS>BLACKPOINTS)) OR
    ((BW=-1) AND (BLACKPOINTS>WHITEPOINTS)) THEN
    IF CBITF(TREE[I,1],16,2)>0 THEN MDBON:=MDBON+10;
    IF ((WILL=A[5]) AND (B[A[4]]=F)) OR 
    ((WILL=A[2]) AND (B[A[1]]=F)) THEN MDBON:=MDBON+5 
  END OF MDBON; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE POSIT;
  BEGIN INTEGER II, ORG, DST; 
    OUTPUT DATA(II,FOR I:=1 TO 5 DO[OUTS[I]],ORG,DST,CENCON(II)); 
  &* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    PROCEDURE SETM; 
    BEGIN BLANK(OUTS); ORG:=CBITF(TREE[II,1],7,7);
      DST:=CBITF(TREE[II,1],0,7); OUTS[3]:=PCS[ABS(B[ORG])] 
    END OF SETM;
  &* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    IZERO(POSITIONVAL); 
    TRACPOS:=KEYS AND 1;
    IF MOVE<6 THEN
    BEGIN PIECEVAL[1]:=1; PIECEVAL[2]:=4; PIECEVAL[3]:=3; 
      PIECEVAL[4]:=2; PIECEVAL[5]:=1; PIECEVAL[6]:=-1;
      IF TRACPOS=1 THEN WRITE(LISTU,OPENA); 
      FOR II:=1 TO TREEPTR DO 
      BEGIN POSITIONVAL[II]:=CENCON(II)+OPENB(II);
        IF TRACPOS=1 THEN 
        BEGIN SETM; WRITE(LISTU,LIN2,DATA,OPENB(II))
      END END; SORT 
    END ELSE
    IF MDGAME THEN
    BEGIN PIECEVAL[1]:=3; PIECEVAL[2]:=4; PIECEVAL[3]:=3; 
      PIECEVAL[4]:=2; PIECEVAL[5]:=1; PIECEVAL[6]:=1; 
      IF TRACPOS=1 THEN WRITE(LISTU,MIDFORM); 
      FOR II:=1 TO TREEPTR DO 
      BEGIN POSITIONVAL[II]:=CENCON(II)+MOBILE(II)+KINGCH(II) 
        +MDBON(II); 
      IF TRACPOS=1 THEN 
      BEGIN SETM; WRITE(LISTU,LIN2,DATA,MOBILE(II),KINGCH(II),
        MDBON(II),POSITIONVAL[II])
    END END; SORT 
    END; FOR I:=1 TO TREEPTR DO TREE[I,2]:=TREE[I,2] AND @167777; 
    TREE[TREEPTR,2]:=TREE[TREEPTR,2]OR @10000 
  END OF POSIT; 
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE GENMOV; 
  BEGIN LABEL LOOP, EXITBLOCK; INTEGER I, J;
    OUTPUT DUMP2(I,DEPTH,MATERIAL,CBITF(TREE[I,1],7,7), 
      CBITF(TREE[I,1],0,7),TREE[I,2],TREE[I,1],PVAR[2],PVAR[1], 
      NEXT[2],NEXT[1]); 
  &* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
  PROCEDURE DUMPIT; 
  BEGIN INTEGER IDEPTH; FORMAT LINER(5X"DEPTH="I1,2(2XI2)); 
    IDEPTH:=1;
    FOR I:=0 TO TREEPTR DO IF TREE[I,2]<0 THEN
    BEGIN WRITE(LISTU,LINER,IDEPTH,CBITF(TREE[I,1],7,7),
        CBITF(TREE[I,1],0,7)); IDEPTH:=IDEPTH+1 
    END; WRITE(LISTU,LINER,DEPTH,CBITF(NEXT[1],7,7),
     CBITF(NEXT[1],0,7)); 
    WRITE(LISTU,#(9(2XI6)),FOR IDEPTH:=0 TO MDEPTH DO[AB[IDEPTH]])
  END;
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    PROCEDURE BAKUP1; 
    BEGIN LABEL OUT; T:=AB[DEPTH];
      IF T>AB[DEPTH-1] THEN 
      BEGIN COMMENT HAVE NEW PBV; 
        IF T>=AB[DEPTH-2] THEN
        BEGIN COMMENT: CUT-OFF, STRIP PRUNED MOVES; 
          IF DEPTH=1 THEN GO OUT; 
          DO TREEPTR:=TREEPTR-1 UNTIL TREE[TREEPTR+1,2];
          RETRO(LM[1],B[21],F,MATERIAL,DEPTH) 
        END ELSE
      BEGIN IF (KEYS AND 2)=2 THEN DUMPIT;
          AB[DEPTH-1]:=T; IF DEPTH=1 THEN 
          BEGIN PVAR[1]:=NEXT[1]; PVAR[2]:=NEXT[2] END
      END END;
OUT: END OF BAKUP1; 
  &* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    PROCEDURE BAKUP2; 
  BEGIN T:=AB[DEPTH]; 
      IF T<AB[DEPTH-1] THEN 
      BEGIN IF T<=AB[DEPTH-2] THEN
        BEGIN DO TREEPTR:=TREEPTR-1 UNTIL TREE[TREEPTR+1,2];
          RETRO(LM[1],B[21],F,MATERIAL,DEPTH) 
        END ELSE
            BEGIN IF (KEYS AND 2)=2 THEN DUMPIT; AB[DEPTH-1]:=T;
    END END END OF BAKUP2;
  &* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
    MATERIAL:=0;
    TREEPTR:=DEPTH:=0; PUSHM; POSIT;
  IF (KEYS AND 4)=4 THEN WRITE(LISTU,#("0 F"3X"BW"2X"DEPTH"3X"PTR"
      2X"MATERIAL"8X"TREE"8X"NEXT"10X"LM"/)); 
    AB[0]:=-30000; AB[-1]:=AB[1]:=30000;
LOOP: NEXT[1]:=TREE[TREEPTR,1]; NEXT[2]:=TREE[TREEPTR,2]; 
    TREE[TREEPTR,2]:=NEXT[2] OR @100000;
    IF CBITF(NEXT[1],27,1)=(IF F>0 THEN 1 ELSE 0) THEN
    BEGIN & SAVE THE OLD BOARD AND EXECUTE NEW MOVE 
      IF CBITF(NEXT[1],28,1)=1 THEN 
      SAVE(LM[1],B[21],MATERIAL,DEPTH); 
      ECUTE(NEXT,LM,B,PCVAL,DEPTH,F,BW,MATERIAL)
    END;
     IF (KEYS AND 4)=4 THEN TRY;
    IF NEXT[2]>=0 THEN
    BEGIN & DEPTH OF 3 AT MAXIMUM DEPTH 
      IF DEPTH>=MDEPTH THEN AB[DEPTH]:=MATERIAL 
      ELSE BEGIN & GET NEXT MOVES AND CARRY DOWN A/B VALUES 
        PUSHM; AB[DEPTH]:=AB[DEPTH-2]; GO EXITBLOCK 
    END END;
    TREEPTR:=TREEPTR-1; 
  &    IF REQUIRED, BACKUP ALPHA OR BETA VALUE
    IF DEPTH MOD 2=1 THEN BAKUP1 ELSE BAKUP2; 
    RETRO(LM[1],B[21],F,MATERIAL,DEPTH);
EXITBLOCK:  IF (KEYS AND 4)=4 THEN TRY; 
    IF TREEPTR>0 THEN GO LOOP;
    IF CBITF(PVAR[1],18,1)=1 THEN 
    BEGIN I:=CBITF(PVAR[1],14,2); WRITE(TTY,#("PROMOTION:"I3),I)
    END; PVAR[2]:=PVAR[2] AND @77777; 
    ECUTE(PVAR,LM,B,PCVAL,DEPTH,F,BW,MATERIAL); PUSHM;
    WRITE(LISTU,#(/" MY MOVE FROM "I2" TO "I2//),CBITF(PVAR[1],7,7),
         CBITF(PVAR[1],0,7)); 
    FOR I:=0 TO TREEPTR DO
    IF (ABS(B[CBITF(TREE[I,1],0,7)])=6 AND MYCHECK=1) THEN
    BEGIN WRITE(6,CHECKMATE); GO DONE END;
    MYCHECK:=YOUCHECK:=TREEPTR:=0; F:=-F; PUSHM;
    FOR I:=0 TO TREEPTR DO
    IF ABS(B[CBITF(TREE[I,1],0,7)])=6 THEN
    BEGIN WRITE(LISTU,CHEK); YOUCHECK:=1 END; 
    F:=-F 
  END OF GENMOV;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
  PROCEDURE SETBOARD; 
  BEGIN LABEL LOOP,ITSOK, CONTINUE; 
    FOR I:=20 STEP 10 UNTIL 90 DO FOR J:=1 TO 8 DO B[I+J]:=0; 
    WRITE(TTY,F1);
LOOP: WRITE(TTY,SQ); READ(KBD,*,SQUARE);
    IF SQUARE=0 THEN GO CONTINUE; 
    FOR I:=20 STEP 10 UNTIL 90 DO FOR J:=1 TO 8 DO
    IF SQUARE=I+J THEN GO ITSOK;
    WRITE(TTY,ILL); GO LOOP;
ITSOK: WRITE(TTY,PC); READ(KBD,*,PIECE);
    IF ABS(PIECE)>6 THEN
    BEGIN WRITE(TTY,ILL); GO LOOP END;
    B[SQUARE]:=PIECE; GO LOOP;
CONTINUE: TYPEB; WRITE(TTY,#("BOARD OK? (YES=1) _")); 
    READ(KBD,*,SQUARE); IF SQUARE#1 THEN GO LOOP; 
    WRITE(TTY,#("MOVE NO? _")); READ(KBD,*,MOVE); 
    WRITE(TTY,#("0=FULL RIGHTS, 1=DISALLOW QUEENS SIDE,"/ 
      "2=DISALLOW KINGS SIDE, 3= DISALLOW ANY"/ 
      "CASTLING RIGHTS, WHITE? _")); READ(1,*,SQUARE);
    SBITF(LM[1],22,2,SQUARE); 
    WRITE(TTY,#("CASTLING RIGHTS, BLACK? _")); READ(TTY,*,SQUARE);
    SBITF(LM[1],20,2,SQUARE); 
    WRITE(TTY,#(/"WHITE'S MOVE=1, BLACK=-1 _")); READ(KBD,*,F)
  END OF SETBOARD;
& 
&* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
& 
    WRITE(TTY,HEADER);
  WRITE(TTY,#("TYPE 1 FOR A NEW GAME, 0 FOR OLD _")); 
  READ(KBD,*,I); WRITE(TTY,SLECT); READ(KBD,*,BW);
  LM[1]:=1; LM[2]:=MATERIAL:=MOVE:=0; 
  YOUCHECK:=MYCHECK:=0; 
  IF I=1 THEN F:=1 ELSE SETBOARD; 
NMOVE: IF F=1 THEN MOVE:=MOVE+1;
  IF F=1 THEN WRITE(LISTU,#("1"//" MOVE= ",I2/),MOVE);
  IF BW=F THEN GENMOV ELSE READM; GO NMOVE; 
DONE: END OF CHESS$ 
