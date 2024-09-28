@echo off
title %~n0
cd sw
cd RTE
..\hp2100 run_fh.ini  ASMB  Sample/Sample.ASMB.txt  HOLA1
