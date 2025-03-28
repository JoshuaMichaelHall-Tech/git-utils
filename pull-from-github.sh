#!/bin/zsh

# Script to update a local repository from its GitHub remote
# Performs a git pull and handles common errors

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get repository name
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
echo "🔄 Updating local repository: $REPO_NAME"

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📂 Current branch: $CURRENT_BRANCH"

# Check if there are uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "⚠️  Warning: You have uncommitted changes."
  echo "   Options:"
  echo "   1. Stash changes and proceed"
  echo "   2. Commit changes before pulling"
  echo "   3. Abort pull"
  read "choice?Choose an option (1/2/3): "
  
  case $choice in
    1)
      echo "📦 Stashing changes..."
      STASH_MESSAGE="Auto-stash before pull on $(date)"
      git stash push -m "$STASH_MESSAGE"
      echo "✅ Changes stashed with message: '$STASH_MESSAGE'"
      ;;
    2)
      echo "❌ Please commit your changes first and run this script again."
      exit 1
      ;;
    3)
      echo "❌ Pull aborted."
      exit 1
      ;;
    *)
      echo "❌ Invalid option. Pull aborted."
      exit 1
      ;;
  esac
fi

# Check if branch exists on remote
if ! git ls-remote --heads origin $CURRENT_BRANCH | grep -q $CURRENT_BRANCH; then
  echo "⚠️  Warning: Branch '$CURRENT_BRANCH' doesn't exist on remote."
  echo "   Options:"
  echo "   1. Push branch to remote and set upstream"
  echo "   2. Switch to a different branch"
  echo "   3. Pull from master/main instead"
  echo "   4. Abort pull"
  read "choice?Choose an option (1/2/3/4): "
  
  case $choice in
    1)
      echo "🚀 Pushing branch to remote..."
      git push -u origin $CURRENT_BRANCH
      ;;
    2)
      echo "Available remote branches:"
      git branch -r | grep -v '\->' | sed "s/origin\///"
      read "branch?Enter branch name to switch to: "
      echo "🔄 Switching to branch: $branch"
      git checkout $branch
      ;;
    3)
      # Check if main or master exists
      if git ls-remote --heads origin main | grep -q main; then
        DEFAULT_BRANCH="main"
      elif git ls-remote --heads origin master | grep -q master; then
        DEFAULT_BRANCH="master"
      else
        echo "❌ Neither main nor master branch found on remote."
        exit 1
      fi
      echo "🔄 Pulling from $DEFAULT_BRANCH instead..."
      git pull origin $DEFAULT_BRANCH
      exit 0
      ;;
    4)
      echo "❌ Pull aborted."
      exit 1
      ;;
    *)
      echo "❌ Invalid option. Pull aborted."
      exit 1
      ;;
  esac
fi

# Perform the pull
echo "⬇️  Pulling latest changes from GitHub..."
git pull origin $CURRENT_BRANCH

# Check result
if [ $? -eq 0 ]; then
  echo "✅ Successfully pulled latest changes from GitHub."
  
  # Check if we stashed changes earlier
  LAST_STASH=$(git stash list | grep "Auto-stash before pull on $(date)" | head -n 1)
  if [[ -n "$LAST_STASH" ]]; then
    echo "📦 Restoring your stashed changes..."
    git stash pop
    
    # Check for conflicts
    if [[ $? -ne 0 ]]; then
      echo "⚠️  There were conflicts when restoring your stashed changes."
      echo "   Please resolve them manually."
    else
      echo "✅ Stashed changes successfully restored."
    fi
  fi
else
  echo "❌ Pull failed. See error messages above."
  exit 1
fi

# Show status summary
echo "📊 Repository status:"
git status -s

echo "✨ All done!"
