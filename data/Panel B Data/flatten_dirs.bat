@echo off
setlocal enabledelayedexpansion

REM Get the current directory
set "current_dir=%cd%"

REM Loop through all immediate subdirectories
for /d %%D in (*) do (
    REM Check if it's truly a directory (extra safety)
    if exist "%%D\" (
        echo Processing directory: %%D

        REM Move all files and folders from subdirectory to current directory
        pushd "%%D"
        for %%F in (*) do (
            move "%%F" "%current_dir%" >nul 2>&1
        )
        for /d %%S in (*) do (
            move "%%S" "%current_dir%" >nul 2>&1
        )
        popd

        REM Remove the (now empty) subdirectory
        rmdir "%%D"
    )
)

echo Done.
pause
