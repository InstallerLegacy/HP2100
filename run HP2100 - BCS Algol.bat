@echo off
title %~n0
cd sw
cd BCS
..\hp2100    run_algol.ini   algol/HelloWorld.ALGOL.txt
