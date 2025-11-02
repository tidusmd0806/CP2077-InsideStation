@echo off
setlocal

:: コピー元のファイルパス
set "sourceFile=D:\SteamLibrary\steamapps\common\Cyberpunk 2077\bin\x64\plugins\cyber_engine_tweaks\mods\entSpawner\export\inside_station_exported.json"
set "sourceFile_2=D:\SteamLibrary\steamapps\common\Cyberpunk 2077\bin\x64\plugins\cyber_engine_tweaks\mods\nativeInteractions\projects\inside_station.json"

:: スクリプト配置ディレクトリ（コピー先フォルダ）
set "destinationFolder=%~dp0"
if "%destinationFolder:~-1%"=="\" set "destinationFolder=%destinationFolder:~0,-1%"

:: 元ファイルをコピー（同名ファイルがあれば上書き）
echo Copying %sourceFile% to %destinationFolder%
copy "%sourceFile%" "%destinationFolder%" /Y

:: Second file copy to relative path
:: Build an absolute destination path relative to the script directory so the copy
:: works regardless of the current working directory when the script is run.
set "relativeDestPath=%destinationFolder%\..\resources\bin\x64\plugins\cyber_engine_tweaks\mods\nativeInteractions\projects"
echo Copying %sourceFile_2% to %relativeDestPath%
:: Ensure destination folder exists (mkdir is safe if already exists)
if not exist "%relativeDestPath%" mkdir "%relativeDestPath%"
:: Copy the file into the destination directory (use trailing backslash to mark directory)
copy "%sourceFile_2%" "%relativeDestPath%\" /Y

echo Done.
endlocal
pause