#!/bin/bash
# Git Repository Initialization Script for Stardew Valley Clone
# This script initializes a Git repository and pushes to GitHub

set -e  # Exit on error

echo "=========================================="
echo "  Stardew Valley Clone - Git Setup"
echo "=========================================="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git is not installed. Please install Git first."
    exit 1
fi

echo "✓ Git found: $(git --version)"
echo ""

# Check if already a git repository
if [ -d ".git" ]; then
    echo "⚠️  Warning: This directory is already a Git repository."
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Initialize git repository if not exists
if [ ! -d ".git" ]; then
    echo "📦 Initializing Git repository..."
    git init
    echo "✓ Git repository initialized"
    echo ""
fi

# Configure git user (if not configured)
if [ -z "$(git config user.name)" ]; then
    echo "Please enter your Git username:"
    read GIT_USERNAME
    git config user.name "$GIT_USERNAME"
fi

if [ -z "$(git config user.email)" ]; then
    echo "Please enter your Git email:"
    read GIT_EMAIL
    git config user.email "$GIT_EMAIL"
fi

echo "✓ Git user configured: $(git config user.name) <$(git config user.email)>"
echo ""

# Add all files
echo "📝 Adding files to staging area..."
git add .
echo "✓ Files staged"
echo ""

# Initial commit
echo "💾 Creating initial commit..."
git commit -m "$(cat <<'EOF'
Initial commit: Stardew Valley AI Clone project setup

- Environment system (Season, Weather, Items) completed
- Hello-Agent backend structure ready
- CI/CD workflows configured
- Documentation complete
- Contributing guidelines established

🤖 Generated with Lingma
EOF
)"
echo "✓ Initial commit created"
echo ""

# Ask for GitHub repository URL
echo "=========================================="
echo "  GitHub Repository Setup"
echo "=========================================="
echo ""
echo "Please create a new repository on GitHub:"
echo "1. Go to https://github.com/new"
echo "2. Repository name: stardew_valley"
echo "3. Description: AI-driven farming simulation with intelligent NPCs"
echo "4. Keep it Public or Private (your choice)"
echo "5. DO NOT initialize with README, .gitignore, or license"
echo "6. Click 'Create repository'"
echo ""
echo "After creating the repository, copy the HTTPS URL."
echo "It should look like: https://github.com/YOUR_USERNAME/stardew_valley.git"
echo ""
read -p "Enter your GitHub repository URL: " GITHUB_URL

# Validate URL format
if [[ ! $GITHUB_URL =~ ^https://github\.com/.+ ]]; then
    echo "❌ Error: Invalid GitHub URL format"
    exit 1
fi

# Add remote origin
echo ""
echo "🔗 Adding remote origin..."
git remote add origin "$GITHUB_URL"
echo "✓ Remote added: $GITHUB_URL"
echo ""

# Push to GitHub
echo "🚀 Pushing to GitHub..."
git branch -M main
git push -u origin main

echo ""
echo "=========================================="
echo "  ✅ Success!"
echo "=========================================="
echo ""
echo "Your project has been pushed to GitHub!"
echo "Repository URL: $GITHUB_URL"
echo ""
echo "Next steps:"
echo "1. Visit your repository on GitHub"
echo "2. Create a GitHub Project Board (see docs/03-研发管理/GITHUB_PROJECTS_SETUP.md)"
echo "3. Set up branch protection rules"
echo "4. Invite team members"
echo "5. Start creating issues and planning sprints!"
echo ""
echo "Happy coding! 🎮"
