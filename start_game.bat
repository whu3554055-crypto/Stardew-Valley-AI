@echo off
chcp 65001 >nul
echo ========================================
echo   Stardew Valley Clone - AI NPC Edition
echo ========================================
echo.

REM Check if Ollama is running
echo [1/3] Checking Ollama status...
ollama ps >nul 2>&1
if errorlevel 1 (
    echo Starting Ollama service...
    start "" ollama serve
    timeout /t 3 /nobreak >nul
) else (
    echo Ollama is running!
)

REM Verify model exists
echo [2/3] Verifying qwen3.5:9b model...
ollama list | findstr "qwen3.5:9b" >nul
if errorlevel 1 (
    echo Model not found! Pulling qwen3.5:9b...
    ollama pull qwen3.5:9b
) else (
    echo Model ready!
)

REM Launch Godot project
echo [3/3] Launching Godot...
echo.
echo Starting Godot Engine with the project...
start "" "D:\program\Godot_v4.6.2-stable_win64.exe" --path "%~dp0"

echo.
echo ========================================
echo   Game launched successfully!
echo ========================================
echo.
echo Next steps:
echo 1. Press F5 in Godot to run the game
echo 2. NPCs will use AI dialogue automatically
echo 3. Talk to Pierre, Abigail, or Mayor Lewis
echo.
echo AI Configuration:
echo - Model: qwen3.5:9b
echo - Endpoint: http://localhost:11434
echo.
pause
