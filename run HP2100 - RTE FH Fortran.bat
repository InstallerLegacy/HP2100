@echo off
title %~n0
cd sw
cd RTE
..\hp2100 run_fh.ini  FTN  Sample/Sample.FTN.txt  HELLO
