@echo off
title %~n0
cd sw
cd MTS
..\hp2100   run.ini  ALGOL  Sample/Sample.ALGOL.txt   PROG
