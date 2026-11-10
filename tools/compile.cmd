@echo off
setlocal EnableExtensions

echo === DuckDNS IP Update - Compile ===
echo.

:: Set paths
set "ProjectDir=%~dp0.."
set "SourceFile=%ProjectDir%\duckdns-ip-update.ahk"
set "OutputFile=%ProjectDir%\duckdns-ip-update.exe"
set "Compiler=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set "BaseFile=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

:: Check if compiler exists
if not exist "%Compiler%" (
    echo [ERROR] Compiler not found: %Compiler%
    echo Please install AutoHotkey v2 with the compiler component.
    goto :end
)

:: Check if source file exists
if not exist "%SourceFile%" (
    echo [ERROR] Source file not found: %SourceFile%
    goto :end
)

echo Compiling...
echo   Source: %SourceFile%
echo   Output: %OutputFile%
echo.

:: Compile the script
if exist "%OutputFile%" del "%OutputFile%"
"%Compiler%" /in "%SourceFile%" /out "%OutputFile%" /base "%BaseFile%"

if exist "%OutputFile%" (
    echo [OK] Compilation successful.
    echo.
    for %%A in ("%OutputFile%") do echo   Size: %%~zA bytes
) else (
    echo [ERROR] Compilation failed.
)

:end
echo.
pause
endlocal
