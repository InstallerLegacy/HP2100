@echo off
title %~n0
cd sw
cd RTE-III
..\hp2100    run_pas.ini  test_run/Sample.pas.txt   EIGHTQUEENS
