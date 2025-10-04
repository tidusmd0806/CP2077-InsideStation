@echo off
setlocal

:: コピー元のファイルパス
set "sourceFile=D:\SteamLibrary\steamapps\common\Cyberpunk 2077\bin\x64\plugins\cyber_engine_tweaks\mods\entSpawner\export\inside_station_exported.json"

:: スクリプト配置ディレクトリ（コピー先フォルダ）
set "destinationFolder=%~dp0"
if "%destinationFolder:~-1%"=="\" set "destinationFolder=%destinationFolder:~0,-1%"

:: 元ファイルをコピー（同名ファイルがあれば上書き）
echo Copying %sourceFile% to %destinationFolder%
copy "%sourceFile%" "%destinationFolder%" /Y

echo Done.
endlocal
pause