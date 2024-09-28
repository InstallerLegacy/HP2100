@echo off
title %~n0
cd sw
cd RTE-II
..\hp2100  run.ini  ALGOL  test_run/Sample.ALGOL.txt  HOLA1
