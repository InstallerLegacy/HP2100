@echo off
title %~n0
cd sw
cd MTS
..\hp2100   run.ini  ASMB  Sample/Sample.ASMB.txt   HELLO
