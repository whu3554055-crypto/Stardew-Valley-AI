# Hello-Agent Backend Startup Script (Windows PowerShell)
# This script starts the FastAPI backend service

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Hello-Agent Backend Service" -ForegroundColor Cyan
Write-Host "  Stardew Valley AI Agent" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if .env exists
if (-not (Test-Path ".env")) {
    Write-Host "⚠️  Warning: .env file not found!" -ForegroundColor Yellow
    Write-Host "Creating from .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "✓ Created .env file" -ForegroundColor Green
    Write-Host "Please edit .env to configure your API keys" -ForegroundColor Yellow
    Write-Host ""
}

# Check if virtual environment exists
if (-not (Test-Path "venv")) {
    Write-Host "📦 Creating virtual environment..." -ForegroundColor Cyan
    python -m venv venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
    Write-Host ""
}

# Activate virtual environment
Write-Host "🔧 Activating virtual environment..." -ForegroundColor Cyan
.\venv\Scripts\Activate.ps1
Write-Host "✓ Activated" -ForegroundColor Green
Write-Host ""

# Install dependencies
Write-Host "📥 Checking dependencies..." -ForegroundColor Cyan
pip install -q -r requirements.txt
Write-Host "✓ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Create necessary directories
if (-not (Test-Path "logs")) {
    New-Item -ItemType Directory -Path "logs" | Out-Null
}
if (-not (Test-Path "data")) {
    New-Item -ItemType Directory -Path "data" | Out-Null
}

# Start the server
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Server..." -ForegroundColor Cyan
Write-Host "  URL: http://localhost:8080" -ForegroundColor Cyan
Write-Host "  Docs: http://localhost:8080/docs" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

python -m uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
