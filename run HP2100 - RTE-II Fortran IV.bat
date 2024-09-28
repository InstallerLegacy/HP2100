@echo off
title %~n0
cd sw
cd RTE-II
..\hp2100 run.ini  FTN4  test_run/Sample.FTN4.txt  HELLO
