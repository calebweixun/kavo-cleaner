@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
color 1f
title 捷徑病毒修復工具 - kavo-cleaner

:: ================================================================
:: kavo-cleaner - Windows Shortcut Virus cleanup helper
::
:: Based on the recovery procedure documented in the NTUST_Talk post:
:: https://www.ptt.cc/bbs/NTUST_Talk/M.1370194255.A.FAE.html
::
:: This script intentionally does NOT delete wscript.exe itself.
:: ================================================================

call :require_admin
if errorlevel 1 exit /b 1

cls
echo ================================================================
echo              捷徑病毒自動修復工具
 echo ================================================================
echo.
echo 來源方法：PTT NTUST_Talk M.1370194255.A.FAE
echo 專案：kavo-cleaner
 echo.
echo 注意：這是針對捷徑病毒徵狀的清理工具，不是完整防毒軟體。
echo 清理前會先把可疑檔案移到隔離區，而不是直接永久刪除。
echo.

set "TARGET="
set /p "TARGET=請輸入要修復的磁碟機代號或路徑（例如 F: 或 Z:\Share）: "
if not defined TARGET goto :cancel

:: Normalize a plain drive letter such as F: to F:\
if "!TARGET:~1!"==":" set "TARGET=!TARGET!\"

if not exist "!TARGET!" (
    echo.
    echo [錯誤] 找不到目標：!TARGET!
    pause
    exit /b 2
)

for %%I in ("!TARGET!") do set "TARGET=%%~fI"
set "ROOT=!TARGET!"
if "!ROOT:~-1!"=="\" set "ROOT=!ROOT:~0,-1!"

echo.
echo 目標：!TARGET!
echo.
choice /C YN /N /M "確定要開始修復嗎？ [Y/N] "
if errorlevel 2 goto :cancel

set "QUARANTINE=!TEMP!\kavo-cleaner-%RANDOM%%RANDOM%"
md "!QUARANTINE!" >nul 2>&1
if not exist "!QUARANTINE!" (
    echo [錯誤] 無法建立隔離資料夾：!QUARANTINE!
    pause
    exit /b 3
)

call :banner "1/5 關閉 Windows Script Host 執行程序"
taskkill /F /IM wscript.exe /T >nul 2>&1
if not errorlevel 1 echo 已停止 wscript.exe
ntaskkill /F /IM cscript.exe /T >nul 2>&1
if not errorlevel 1 echo 已停止 cscript.exe

echo.
call :banner "2/5 隔離已知的捷徑病毒檔案"

:: The source procedure explicitly identifies these artifacts.
call :quarantine_dir "!ROOT!\loopqa"
call :quarantine_dir "!ROOT!\autorun.inf"

:: Only quarantine root-level shortcut files. This avoids destroying legitimate
:: shortcuts throughout a normal document tree.
for /f "delims=" %%F in ('dir /b /a:-d "!ROOT!\*.lnk" 2^>nul') do (
    call :quarantine_file "!ROOT!\%%F"
)

:: The historical infection uses a VBS payload in the root. Do not blindly
:: delete every VBS on the machine; quarantine only root-level VBS files.
for /f "delims=" %%F in ('dir /b /a:-d "!ROOT!\*.vbs" 2^>nul') do (
    call :quarantine_file "!ROOT!\%%F"
)

echo.
call :banner "3/5 還原被感染檔案的屬性"
echo 正在移除 H(隱藏)、S(系統)、R(唯讀) 屬性...
attrib -H -S -R "!ROOT!\*" /S /D >nul 2>&1
if errorlevel 1 (
    echo [警告] attrib 執行時出現錯誤，請稍後檢查結果。
) else (
    echo 屬性還原完成。
)

echo.
call :banner "4/5 清理目前使用者的典型感染殘留"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "USER_TEMP=%TEMP%"

call :quarantine_matching_name "!STARTUP!" "*.vbs"
call :quarantine_matching_name "!USER_TEMP!" "*.vbs"

echo.
call :banner "5/5 檢查啟動項目"
echo.
echo 本工具不會直接修改 Windows 的啟動設定，以免誤傷合法軟體。
echo 請在修復後開啟「工作管理員 ^> 啟動應用程式」或 msconfig 檢查：
echo   Windows Script Host / 可疑 .vbs 啟動項目

echo.
echo ================================================================
echo 修復程序完成
 echo ================================================================
echo 隔離區：!QUARANTINE!
echo.
echo 建議：
echo  1. 先確認資料夾與檔案已恢復可見。
echo  2. 不要刪除 Windows 內建的 wscript.exe。
echo  3. 使用 Windows Security 做一次完整掃描。
echo  4. 若症狀持續，重新啟動後再檢查 USB/磁碟機。
echo.
echo 隔離區內的檔案請先確認內容，再手動刪除。
echo.
pause
exit /b 0

:quarantine_file
set "SRC=%~1"
if not exist "!SRC!" exit /b 0
for %%I in ("!SRC!") do set "NAME=%%~nxI"
set "DST=!QUARANTINE!\!NAME!"
if exist "!DST!" (
    set "DST=!QUARANTINE!\%RANDOM%_!NAME!"
)
move /Y "!SRC!" "!DST!" >nul 2>&1
if not errorlevel 1 (
    echo [隔離] !SRC!
) else (
    echo [無法隔離] !SRC!
)
exit /b 0

:quarantine_dir
set "SRC_DIR=%~1"
if not exist "!SRC_DIR!" exit /b 0
for %%I in ("!SRC_DIR!") do set "NAME=%%~nxI"
set "DST=!QUARANTINE!\!NAME!"
if exist "!DST!" set "DST=!QUARANTINE!\%RANDOM%_!NAME!"
move /Y "!SRC_DIR!" "!DST!" >nul 2>&1
if not errorlevel 1 (
    echo [隔離資料夾] !SRC_DIR!
) else (
    echo [無法隔離資料夾] !SRC_DIR!
)
exit /b 0

:quarantine_matching_name
set "DIR=%~1"
set "PATTERN=%~2"
if not exist "!DIR!" exit /b 0
for /f "delims=" %%F in ('dir /b /a:-d "!DIR!\!PATTERN!" 2^>nul') do (
    call :quarantine_file "!DIR!\%%F"
)
exit /b 0

:banner
echo ================================================================
echo [%~1]
echo ================================================================
exit /b 0

:require_admin
net session >nul 2>&1
if not errorlevel 1 exit /b 0

echo 正在要求系統管理員權限...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b 1

:cancel
echo.
echo 已取消，未修改目標路徑。
pause
exit /b 0
