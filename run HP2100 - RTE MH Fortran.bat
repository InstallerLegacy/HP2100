@echo off
title %~n0
cd sw
cd RTE
..\hp2100  run_mh.ini  FTN  Sample/Sample.FTN.txt  HELLO
