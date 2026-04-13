@echo off

IF NOT DEFINED LOVE_HOME (
    SET LOVE_HOME=C:\Program Files\LOVE
)

"%LOVE_HOME%\lovec.exe" .