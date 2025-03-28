#!/bin/zsh

# Script to update a GitHub repository from local changes
# Performs git add, commit, and push with interactive options

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get repository name
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
echo "🔄 Updating GitHub repository: $REPO_NAME"

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📂 Current branch: $CURRENT_BRANCH"

# Check for changes
if git diff --quiet && git diff --cached --quiet; then
  echo "ℹ️  No changes to commit."
  
  # Check if we need to push
  if git rev-parse --abbrev-ref @{upstream} &>/dev/null; then
    AHEAD=$(git rev-list --count @{upstream}..HEAD)
    if [ $AHEAD -eq 0 ]; then
      echo "✅ Branch is up to date with remote. Nothing to push."
      exit 0
    else
      echo "ℹ️  You have $AHEAD commit(s) to push."
    fi
  else
    echo "⚠️  No upstream branch set. Will push and set upstream."
  fi
else
  # Show status
  echo "📊 Current changes:"
  git status -s
  
  # Select files to add
  echo ""
  echo "Select files to add:"
  echo "   1. Add all changes"
  echo "   2. Add specific files"
  echo "   3. Stage changes interactively"
  read "choice?Choose an option (1/2/3): "
  
  case $choice in
    1)
      echo "📝 Adding all changes..."
      git add .
      ;;
    2)
      echo "📝 Adding specific files..."
      git status -s
      read "files?Enter files/patterns to add (space-separated): "
      for file in $files; do
        git add $file
      done
      ;;
    3)
      echo "📝 Interactive staging..."
      git add -i
      ;;
    *)
      echo "❌ Invalid option. Push aborted."
      exit 1
      ;;
  esac
  
  # Show what's staged
  echo "📊 Changes to be committed:"
  git status -s
  
  # Get commit message
  echo ""
  read "commit_msg?Enter commit message: "
  
  if [[ -z "$commit_msg" ]]; then
    echo "❌ Empty commit message. Push aborted."
    exit 1
  fi
  
  # Commit changes
  echo "💾 Committing changes..."
  git commit -m "$commit_msg"
  
  if [ $? -ne 0 ]; then
    echo "❌ Commit failed. Push aborted."
    exit 1
  fi
fi

# Check if branch exists on remote
UPSTREAM_SET=true
if ! git rev-parse --abbrev-ref @{upstream} &>/dev/null; then
  UPSTREAM_SET=false
  echo "⚠️  No upstream branch set for '$CURRENT_BRANCH'."
  echo "   Will push and set upstream."
fi

# Perform the push
echo "⬆️  Pushing changes to GitHub..."

if [ "$UPSTREAM_SET" = false ]; then
  git push -u origin $CURRENT_BRANCH
else
  # Check for other changes on remote
  git fetch origin $CURRENT_BRANCH
  
  BEHIND=$(git rev-list --count HEAD..@{upstream})
  if [ $BEHIND -gt 0 ]; then
    echo "⚠️  Warning: Remote has $BEHIND commit(s) that you don't have locally."
    echo "   Options:"
    echo "   1. Pull changes first (recommended)"
    echo "   2. Force push (overwrites remote changes)"
    echo "   3. Abort push"
    read "choice?Choose an option (1/2/3): "
    
    case $choice in
      1)
        echo "⬇️  Pulling changes first..."
        git pull origin $CURRENT_BRANCH
        if [ $? -ne 0 ]; then
          echo "❌ Pull failed. Push aborted."
          exit 1
        fi
        ;;
      2)
        echo "⚠️  Force pushing (use with caution)..."
        read "confirm?Are you sure? This will overwrite remote changes (y/n): "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          git push --force origin $CURRENT_BRANCH
          if [ $? -eq 0 ]; then
            echo "✅ Force push successful."
          else
            echo "❌ Force push failed."
          fi
          exit $?
        else
          echo "❌ Force push aborted."
          exit 1
        fi
        ;;
      3)
        echo "❌ Push aborted."
        exit 1
        ;;
      *)
        echo "❌ Invalid option. Push aborted."
        exit 1
        ;;
    esac
  fi
  
  # Normal push
  git push origin $CURRENT_BRANCH
fi

# Check result
if [ $? -eq 0 ]; then
  echo "✅ Successfully pushed changes to GitHub."
else
  echo "❌ Push failed. See error messages above."
  exit 1
fi

echo "✨ All done!"
