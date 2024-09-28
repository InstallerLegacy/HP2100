@echo off
title %~n0
cd sw
cd RTE-III
..\hp2100 run_bas.ini  test_run/Sample.bas.txt
