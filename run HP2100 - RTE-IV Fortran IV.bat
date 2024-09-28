@echo off
title %~n0
cd sw
cd RTE-IV
..\hp2100 run.ini  FTN4  test_run/Sample.FTN4.txt  HELLO
