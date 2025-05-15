#!/bin/zsh

# Script to safely force-push changes to a remote repository
# Usage: ./force-push-to-remote.sh [remote-name] [--skip-backup]

echo "⚠️  Force Push to Remote Repository ⚠️"
echo "========================================"
echo ""

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get repository information
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
CURRENT_BRANCH=$(git branch --show-current)

# Parse arguments
REMOTE_NAME=${1:-origin}  # Default to "origin" if not specified
SKIP_BACKUP=false
AUTO_CONFIRM=false

# Process all arguments
for arg in "$@"; do
  if [[ "$arg" == "--skip-backup" ]]; then
    SKIP_BACKUP=true
  elif [[ "$arg" == "--yes" || "$arg" == "-y" ]]; then
    AUTO_CONFIRM=true
  fi
done

echo "📍 Repository: $REPO_NAME"
echo "📍 Current branch: $CURRENT_BRANCH"
echo "📍 Remote: $REMOTE_NAME"
echo ""

# Verify remote exists
if ! git remote get-url $REMOTE_NAME > /dev/null 2>&1; then
  echo "❌ Error: Remote '$REMOTE_NAME' does not exist."
  echo "Available remotes:"
  git remote -v
  exit 1
fi

# Create backup if not skipped
if [[ "$SKIP_BACKUP" == false ]]; then
  BACKUP_DIR="$HOME/git-backups"
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUP_FILE="$BACKUP_DIR/${REPO_NAME}_before_force_push_${TIMESTAMP}.bundle"
  
  echo "📦 Creating backup before force push..."
  mkdir -p "$BACKUP_DIR"
  
  git bundle create "$BACKUP_FILE" --all
  
  if [[ $? -eq 0 ]]; then
    echo "✅ Backup created: $BACKUP_FILE"
  else
    echo "❌ Backup failed. Do you want to continue without a backup?"
    
    if [[ "$AUTO_CONFIRM" != true ]]; then
      echo -n "Continue anyway? (yes/y/no/n): "
      read continue
      
      if [[ ! "$continue" =~ ^(yes|y)$ ]]; then
        echo "❌ Force push aborted."
        exit 1
      fi
    else
      echo "⚠️  Auto-confirmed with --yes flag. Continuing without backup."
    fi
  fi
else
  echo "🚫 Backup skipped as requested."
fi

# Show what will be pushed
echo ""
echo "🔍 Changes that will be pushed:"
git log --graph --oneline --decorate --color $REMOTE_NAME/$CURRENT_BRANCH..$CURRENT_BRANCH

# Ask for final confirmation
echo ""
echo "⚠️  WARNING: Force pushing will overwrite the remote repository's history."
echo "    This is a destructive operation and cannot be undone."
echo "    Any changes on the remote that aren't in your local repository will be lost."

if [[ "$AUTO_CONFIRM" != true ]]; then
  echo -n "Are you absolutely sure you want to force push? (yes/y/no/n): "
  read confirm

  if [[ ! "$confirm" =~ ^(yes|y)$ ]]; then
    echo "❌ Force push aborted."
    exit 1
  fi
else
  echo "⚠️  Auto-confirmed with --yes flag. Proceeding with force push."
fi

# Perform the force push
echo ""
echo "🚀 Force pushing to $REMOTE_NAME..."
git push $REMOTE_NAME --force --all

# Check result
if [[ $? -eq 0 ]]; then
  echo "✅ Force push successful."
else
  echo "❌ Force push failed. See error message above."
  if [[ "$SKIP_BACKUP" == false ]]; then
    echo "ℹ️  Your backup is still available at: $BACKUP_FILE"
  fi
  exit 1
fi

# Show the new remote state
echo ""
echo "📈 Current remote branches state:"
git fetch $REMOTE_NAME
git branch -r

echo ""
echo "✨ All done!"
