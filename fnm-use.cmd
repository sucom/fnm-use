@echo off

:: =====================================================================
:: Phase 1: The Anti-Pollution Path Guard
:: =====================================================================
:: Freeze the original, pristine system PATH on the very first run.
:: This variable persists across changes in the same terminal window.
if not defined USER_BASE_PATH (
    set "USER_BASE_PATH=%PATH%"
)

setlocal enabledelayedexpansion

:: =====================================================================
:: Phase 2: Target Version Resolution
:: =====================================================================
set "REQ_VER=%~1"

:: If no argument given, look for project configuration files
if "!REQ_VER!"=="" (
    if exist .node-version (
        set /p REQ_VER=<.node-version
    ) else if exist .nvmrc (
        set /p REQ_VER=<.nvmrc
    )
)

:: If still empty, exit gracefully and let the shell use the default fallback
if "!REQ_VER!"=="" (
    echo [fnm-use] No version specified and no .node-version/.nvmrc found.
    echo [fnm-use] Staying on current/global-default.
    :: Print confirmation using the newly mounted binary
    call node -v
    endlocal
    exit /b 0
)

:: Clean up input: remove quotes and strip a leading 'v' if present
set "REQ_VER=!REQ_VER:"=!"
if "!REQ_VER:~0,1!"=="v" set "REQ_VER=!REQ_VER:~1!"

:: Trim any trailing carriage returns or accidental spaces from file reading
for /f "tokens=1" %%a in ("!REQ_VER!") do set "REQ_VER=%%a"

:: =====================================================================
:: Phase 3: Smart Directory Matching & Highest Version Selection
:: =====================================================================
set "MATCH_COUNT=0"
set "TARGET_PATH="
set "TARGET_NAME="

:: Loop through directories. The natural alphabetical sort ensures that
:: higher dot-versions (e.g. v22.23.1 over v22.1.0) are processed last.
for /d %%d in ("%FNM_DIR%\node-versions\v!REQ_VER!*") do (
    if exist "%%d\installation\node.exe" (
        set /a MATCH_COUNT+=1
        set "TARGET_PATH=%%d\installation"
        set "TARGET_NAME=%%~nxd"
    )
)

:: =====================================================================
:: Phase 4: Lazy-Loading / Installation Prompt
:: =====================================================================
if not defined TARGET_PATH (
    echo [fnm-use] Version "v!REQ_VER!" is not installed locally.
    set /p CHOICE="Would you like to download it now via fnm? [y/n]: "
    if /i "!CHOICE!"=="y" (
        endlocal
        fnm install "%~1"
        :: Re-run the script with the newly installed version
        call "%~f0" "%~1"
        exit /b
    )
    endlocal
    exit /b 1
)

:: =====================================================================
:: Phase 5: Feedback Generation
:: =====================================================================
if !MATCH_COUNT! GTR 1 (
    echo [fnm-use] Found !MATCH_COUNT! matches. Auto-selecting highest version: !TARGET_NAME!
) else (
    echo [fnm-use] Mounting runtime version: !TARGET_NAME!
)

:: =====================================================================
:: Phase 6: Export to Parent Environment & Verification
:: =====================================================================
:: The closing parenthesis trick ensures local variables are expanded
:: *before* endlocal discards the scope, safely rewriting the parent PATH.
endlocal & (
    set "PATH=%TARGET_PATH%;%USER_BASE_PATH%"
)

:: Print confirmation using the newly mounted binary
call node -v