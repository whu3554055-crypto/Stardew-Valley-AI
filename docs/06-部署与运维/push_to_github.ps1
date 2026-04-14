# PowerShell Script to Push to GitHub
# This script helps you push your local repository to GitHub

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Stardew Valley AI - GitHub Push Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if remote already exists
$remoteExists = git remote -v 2>$null
if ($remoteExists) {
    Write-Host "Remote repository already configured:" -ForegroundColor Green
    Write-Host $remoteExists
    Write-Host ""
    $choice = Read-Host "Do you want to change the remote URL? (y/n)"
    if ($choice -ne 'y') {
        Write-Host ""
        Write-Host "Pushing to existing remote..." -ForegroundColor Yellow
        git branch -M main
        git push -u origin main
        exit
    }
}

Write-Host "Please choose a method to push to GitHub:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. GitHub Desktop (Recommended)" -ForegroundColor Green
Write-Host "   - Opens GitHub Desktop with this repository" -ForegroundColor Gray
Write-Host "   - Easiest method, handles authentication automatically" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Manual Setup (GitHub Website + Git Commands)" -ForegroundColor Green
Write-Host "   - I'll guide you through creating a repo on GitHub" -ForegroundColor Gray
Write-Host "   - Then add remote and push via command line" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Open Push Guide Document" -ForegroundColor Green
Write-Host "   - Opens detailed PUSH_TO_GITHUB.md guide" -ForegroundColor Gray
Write-Host ""

$method = Read-Host "Enter your choice (1/2/3)"

switch ($method) {
    "1" {
        Write-Host ""
        Write-Host "Opening GitHub Desktop..." -ForegroundColor Cyan
        
        # Try to open GitHub Desktop
        $githubDesktopPath = "$env:LOCALAPPDATA\GitHubDesktop\GitHubDesktop.exe"
        if (Test-Path $githubDesktopPath) {
            Start-Process $githubDesktopPath -ArgumentList "--open-repo=`"$PWD`""
            Write-Host ""
            Write-Host "GitHub Desktop opened!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Next steps in GitHub Desktop:" -ForegroundColor Yellow
            Write-Host "1. Click 'Publish repository' button (top right)" -ForegroundColor White
            Write-Host "2. Fill in details:" -ForegroundColor White
            Write-Host "   - Name: stardew-valley-ai-clone" -ForegroundColor Gray
            Write-Host "   - Description: AI-powered NPC system for Stardew Valley" -ForegroundColor Gray
            Write-Host "   - Keep private: Your choice" -ForegroundColor Gray
            Write-Host "3. Click 'Publish repository'" -ForegroundColor White
            Write-Host ""
            Write-Host "That's it! Your code will be on GitHub." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "GitHub Desktop not found at expected location." -ForegroundColor Red
            Write-Host "Please open GitHub Desktop manually and:" -ForegroundColor Yellow
            Write-Host "1. File → Add Local Repository" -ForegroundColor White
            Write-Host "2. Select: $PWD" -ForegroundColor White
            Write-Host "3. Click 'Publish repository'" -ForegroundColor White
        }
    }
    
    "2" {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  Manual GitHub Setup Guide" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Step 1: Create Repository on GitHub" -ForegroundColor Yellow
        Write-Host "1. Open this URL in your browser:" -ForegroundColor White
        Write-Host "   https://github.com/new" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "2. Fill in:" -ForegroundColor White
        Write-Host "   - Repository name: stardew-valley-ai-clone" -ForegroundColor Gray
        Write-Host "   - Description: AI-powered NPC system for Stardew Valley" -ForegroundColor Gray
        Write-Host "   - Visibility: Public or Private" -ForegroundColor Gray
        Write-Host "   - UNCHECK 'Initialize with README'" -ForegroundColor Red
        Write-Host ""
        Write-Host "3. Click 'Create repository'" -ForegroundColor White
        Write-Host ""
        
        $continue = Read-Host "Press Enter after you've created the repository..."
        
        Write-Host ""
        Write-Host "Step 2: Configure Remote and Push" -ForegroundColor Yellow
        Write-Host ""
        
        $username = "whu3554055-crypto"
        $customUsername = Read-Host "Your GitHub username (press Enter for default: $username)"
        if ($customUsername) {
            $username = $customUsername
        }
        
        $repoUrl = "https://github.com/$username/stardew-valley-ai-clone.git"
        
        Write-Host ""
        Write-Host "Adding remote repository..." -ForegroundColor Cyan
        git remote remove origin 2>$null
        git remote add origin $repoUrl
        
        Write-Host "Setting branch name to 'main'..." -ForegroundColor Cyan
        git branch -M main
        
        Write-Host ""
        Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
        Write-Host "(You may be prompted to log in to GitHub)" -ForegroundColor Yellow
        Write-Host ""
        
        git push -u origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Green
            Write-Host "  SUCCESS! Repository pushed to GitHub" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "View your repository at:" -ForegroundColor White
            Write-Host "https://github.com/$username/stardew-valley-ai-clone" -ForegroundColor Cyan
            Write-Host ""
        } else {
            Write-Host ""
            Write-Host "Push failed. Please check:" -ForegroundColor Red
            Write-Host "- Is the repository created on GitHub?" -ForegroundColor White
            Write-Host "- Are you logged in to GitHub?" -ForegroundColor White
            Write-Host "- Try using GitHub Desktop instead (Method 1)" -ForegroundColor White
        }
    }
    
    "3" {
        Write-Host ""
        Write-Host "Opening PUSH_TO_GITHUB.md guide..." -ForegroundColor Cyan
        Start-Process "PUSH_TO_GITHUB.md"
    }
    
    default {
        Write-Host ""
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "For more help, see: PUSH_TO_GITHUB.md" -ForegroundColor Gray
