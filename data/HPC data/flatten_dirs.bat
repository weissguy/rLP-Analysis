@echo off
setlocal enabledelayedexpansion

REM Get the current directory
set "current_dir=%cd%"

REM Ask user for confirmation
echo You are about to flatten all subdirectories into:
echo    %current_dir%
set /p "confirm=Are you sure you want to proceed? (y/n): "
if /i not "!confirm!"=="y" (
    echo Operation cancelled.
    exit /b
)

REM Loop through all immediate subdirectories
for /d %%D in (*) do (
    if exist "%%D\" (
        echo Processing directory: %%D

        REM Use robocopy to move files and folders robustly
        robocopy "%%D" "%current_dir%" /move /e /njh /njs /ndl /nc /ns >nul

        REM Clean up just in case
        rmdir /s /q "%%D" >nul 2>&1
    )
)

echo Done.
pause
