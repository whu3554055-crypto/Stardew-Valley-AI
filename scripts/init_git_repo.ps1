# Git Repository Initialization Script for Stardew Valley Clone (Windows PowerShell)
# This script initializes a Git repository and pushes to GitHub

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Stardew Valley Clone - Git Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if git is installed
try {
    $gitVersion = git --version
    Write-Host "✓ Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Git is not installed. Please install Git first." -ForegroundColor Red
    Write-Host "Download from: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Check if already a git repository
if (Test-Path ".git") {
    Write-Host "⚠️  Warning: This directory is already a Git repository." -ForegroundColor Yellow
    $response = Read-Host "Do you want to continue? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
} else {
    # Initialize git repository
    Write-Host "📦 Initializing Git repository..." -ForegroundColor Cyan
    git init
    Write-Host "✓ Git repository initialized" -ForegroundColor Green
    Write-Host ""
}

# Configure git user (if not configured)
$currentName = git config user.name
if ([string]::IsNullOrEmpty($currentName)) {
    $gitUsername = Read-Host "Please enter your Git username"
    git config user.name $gitUsername
}

$currentEmail = git config user.email
if ([string]::IsNullOrEmpty($currentEmail)) {
    $gitEmail = Read-Host "Please enter your Git email"
    git config user.email $gitEmail
}

Write-Host "✓ Git user configured: $(git config user.name) <$(git config user.email)>" -ForegroundColor Green
Write-Host ""

# Add all files
Write-Host "📝 Adding files to staging area..." -ForegroundColor Cyan
git add .
Write-Host "✓ Files staged" -ForegroundColor Green
Write-Host ""

# Initial commit
Write-Host "💾 Creating initial commit..." -ForegroundColor Cyan
$commitMessage = @"
Initial commit: Stardew Valley AI Clone project setup

- Environment system (Season, Weather, Items) completed
- Hello-Agent backend structure ready
- CI/CD workflows configured
- Documentation complete
- Contributing guidelines established

🤖 Generated with Lingma
"@

git commit -m $commitMessage
Write-Host "✓ Initial commit created" -ForegroundColor Green
Write-Host ""

# GitHub repository setup instructions
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  GitHub Repository Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Please create a new repository on GitHub:" -ForegroundColor White
Write-Host "1. Go to https://github.com/new" -ForegroundColor Yellow
Write-Host "2. Repository name: stardew_valley" -ForegroundColor Yellow
Write-Host "3. Description: AI-driven farming simulation with intelligent NPCs" -ForegroundColor Yellow
Write-Host "4. Keep it Public or Private (your choice)" -ForegroundColor Yellow
Write-Host "5. DO NOT initialize with README, .gitignore, or license" -ForegroundColor Yellow
Write-Host "6. Click 'Create repository'" -ForegroundColor Yellow
Write-Host ""
Write-Host "After creating the repository, copy the HTTPS URL." -ForegroundColor White
Write-Host "It should look like: https://github.com/YOUR_USERNAME/stardew_valley.git" -ForegroundColor White
Write-Host ""

$githubUrl = Read-Host "Enter your GitHub repository URL"

# Validate URL format
if ($githubUrl -notmatch "^https://github\.com/.+") {
    Write-Host "❌ Error: Invalid GitHub URL format" -ForegroundColor Red
    exit 1
}

# Add remote origin
Write-Host ""
Write-Host "🔗 Adding remote origin..." -ForegroundColor Cyan
git remote add origin $githubUrl
Write-Host "✓ Remote added: $githubUrl" -ForegroundColor Green
Write-Host ""

# Push to GitHub
Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Cyan
git branch -M main
git push -u origin main

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  ✅ Success!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your project has been pushed to GitHub!" -ForegroundColor Green
Write-Host "Repository URL: $githubUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "1. Visit your repository on GitHub" -ForegroundColor Yellow
Write-Host "2. Create a GitHub Project Board (see docs/03-研发管理/GITHUB_PROJECTS_SETUP.md)" -ForegroundColor Yellow
Write-Host "3. Set up branch protection rules" -ForegroundColor Yellow
Write-Host "4. Invite team members" -ForegroundColor Yellow
Write-Host "5. Start creating issues and planning sprints!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Happy coding! 🎮" -ForegroundColor Green
