@echo off

REM This batch file registers the ETW event manifest or runs the product with some basic logging on.
REM USAGE:
REM    Run ogs-etw.bat to register the event manifest

REM ONLY VISTA AND LATER ARE SUPPORTED
if not exist "%SystemRoot%\system32\wevtutil.exe" goto unsupported

setlocal

rem Extract the exedir from the full path to this batch file. If you copy this batch file somewhere else
rem then you must update this.
set EXEDIR=%~dp0

rem copy OGSTrace*.dll to the ALLUSERSPROFILE folder. Hopefully, ALLUSERSPROFILE is a 'real' path. 
rem This path must be accessible globally by the LOCAL_SERVICE account. It cannot be a subst drive.
rem This dll contains resource strings that ogs-etw.man references. The OS must have this available.

pushd %EXEDIR%
echo Copying message resource dll
copy /y /b OGSTrace*.dll "%ALLUSERSPROFILE%\ogs-etw.dll" >nul

rem register event manifest
echo Registering event manifest
wevtutil um ogs-etw.man
wevtutil im ogs-etw.man
if errorlevel 1 goto error

popd