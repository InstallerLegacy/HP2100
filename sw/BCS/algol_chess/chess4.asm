ASMB,R,L,B
      NAM CBITF,7 
      ENT CBITF 
      EXT .ENTR 
      SPC 1 
IWD   NOP 
IORG  NOP 
ILEN  NOP 
      SPC 1 
*     THIS IS AN ALGOL/FORTRAN CALLABLE SUBROUTINE TO 
*     EXTRACT A BIT FIELD FROM A WORD PAIR. 
      SPC 1 
*     THE PARAMETERS HAVE THE FOLLOWING MEANING.
*       IWD = ADDRESS OF FIRST WORD OF PAIR 
*       IORG = STARTING BIT LOCATION
*       ILEN = LENGTH OF BIT FIELD
      SPC 3 
CBITF NOP           ENTRY/EXIT
      JSB .ENTR     LINK THE
      DEF IWD         PARAMETERS
      LDA ILEN,I    GET THE BIT LENGTH
      ADA TABLE     ADD STARTING ADDRESS
      LDA 0,I       GET THE MASK DESIRED. 
      STA MASK      SAVE IT.
      SPC 1 
      LDA IORG,I    GET THE STARTING POSITION 
      AND =B20      MASK FOR A/B REG IND
      STA FLAG
      SPC 1 
      LDA IORG,I    GET IT BACK 
      AND =B17      FIND NO. OF BITS
      STA 1         SAVE FOR
      IOR RRR       INCLUDE THE INSTRUCTION 
      STA SW.1      PUT IN SEQUENCE 
      SPC 1 
      LDA FLAG      GET THE FLAG
      SZA 
      JMP .SWAP 
      STA .SWP
      SZB 
      JMP LOAD
      STA SW.1
.SWAP LDA .SWP. 
      SZB,RSS 
      CLA 
      STA .SWP
      SPC 1 
LOAD  DLD IWD,I 
* .SWP  SWP 
.SWP  OCT 101100
* SW.1  RRR 4         POSITION
SW.1  OCT 101104
      AND MASK      MASK FOR DESIRED BITS.
      JMP CBITF,I   RETURN
      SPC 1 
* .SWP. SWP 
.SWP. OCT 101100
FLAG  NOP 
RRR   OCT 101100
MASK  NOP 
TABLE DEF * 
      OCT 1,3,7,17,37,77,177
      OCT 377,777,1777,3777,7777,17777,37777,77777
      SPC 1 
      END 
