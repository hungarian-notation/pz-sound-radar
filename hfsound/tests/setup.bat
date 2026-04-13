@echo off
rmdir %~dp0media
mklink /D %~dp0media ..\.dist\Contents\mods\hfsound\common\media
pause