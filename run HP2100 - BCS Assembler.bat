@echo off
title %~n0
cd sw
cd BCS
..\hp2100   run_asmb.ini   assembler/HelloWorld.ASMB.txt
