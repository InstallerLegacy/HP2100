@echo off
title %~n0
cd sw
cd BCS
..\hp2100   run_fortran.ini   fortran/HelloWorld.FTN.txt
