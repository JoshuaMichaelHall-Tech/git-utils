#!/bin/zsh

# Non-interactive script to update a GitHub repository from local changes
# Performs git add, commit, and push automatically
# Designed for batch operations with run-on-all-repos.sh

# Default commit message if none provided
DEFAULT_COMMIT_MSG="Batch update via script"
COMMIT_MSG=${1:-$DEFAULT_COMMIT_MSG}
AUTO_CONFIRM=false

# Process arguments
for arg in "$@"; do
  if [[ "$arg" == "--yes" || "$arg" == "-y" ]]; then
    AUTO_CONFIRM=true
  fi
done

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
      echo "✅ Branch '$CURRENT_BRANCH' is up to date with remote. Nothing to push."
      echo "✨ Operation completed. No changes were needed."
      exit 0
    else
      echo "ℹ️  You have $AHEAD commit(s) to push."
    fi
  else
    echo "⚠️  No upstream branch set for '$CURRENT_BRANCH'. Will push and set upstream."
  fi
else
  # Show status
  echo "📊 Current changes:"
  git status -s
  
  # Add all changes automatically
  echo "📝 Adding all changes..."
  git add .
  
  # Show what's staged
  echo "📊 Changes to be committed:"
  git status -s
  
  # Commit changes
  echo "💾 Committing changes with message: $COMMIT_MSG"
  git commit -m "$COMMIT_MSG"
  
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
    echo "   Automatically pulling changes first..."
    git pull --no-edit origin $CURRENT_BRANCH
    if [ $? -ne 0 ]; then
      echo "❌ Pull failed due to conflicts. Push aborted."
      echo "   You'll need to resolve conflicts manually in this repository."
      exit 1
    fi
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