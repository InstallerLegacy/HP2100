@echo off
title %~n0
cd sw
cd RTE-II
..\hp2100 run.ini  ASMB  test_run/Sample.ASMB.txt  HOLA1
