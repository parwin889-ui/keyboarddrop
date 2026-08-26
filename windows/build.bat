@echo off
echo Building KeyboardDrop for Windows...
echo.

REM Check if dotnet is installed
where dotnet >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] .NET SDK not found. Please install .NET 8 SDK from:
    echo   https://dotnet.microsoft.com/download
    pause
    exit /b 1
)

REM Build
dotnet build -c Release
if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    pause
    exit /b 1
)

echo.
echo Build successful!
echo.
echo To run KeyboardDrop:
echo   dotnet run -c Release
echo.
echo Or use the built executable:
echo   bin\Release\net8.0-windows\KeyboardDrop.exe
echo.
echo Config file location:
echo   %%APPDATA%%\KeyboardDrop\config.json
echo.
pause
