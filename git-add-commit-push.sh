#!/bin/zsh

# Script to add, commit, and push changes to a Git repository
# Usage: ./git-add-commit-push.sh [commit-message] [--all]

echo "🚀 Git Add, Commit, Push Script"
echo "==============================="

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get repository information
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
CURRENT_BRANCH=$(git branch --show-current)

echo "📍 Repository: $REPO_NAME"
echo "📍 Current branch: $CURRENT_BRANCH"
echo ""

# Check if there are any changes to commit
if git diff --quiet && git diff --cached --quiet; then
  echo "ℹ️  No changes to commit."
  
  # Check for untracked files
  if [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "ℹ️  No untracked files to add."
    echo "❌ Nothing to commit or push. Exiting."
    exit 0
  else
    echo "🔍 Found untracked files:"
    git ls-files --others --exclude-standard
  fi
else
  echo "🔍 Current changes:"
  git status -s
fi

# Determine what to add
if [[ "$1" == "--all" || "$2" == "--all" ]]; then
  ADD_OPTION="all"
  echo "ℹ️  Will add all changes and untracked files."
else
  echo ""
  echo "What would you like to add?"
  echo "   1. Add all changes and untracked files"
  echo "   2. Add only tracked files with changes"
  echo "   3. Select specific files to add"
  echo "   4. Interactive staging"
  read "add_option?Choose an option (1/2/3/4): "
  
  case $add_option in
    1) ADD_OPTION="all" ;;
    2) ADD_OPTION="tracked" ;;
    3) ADD_OPTION="specific" ;;
    4) ADD_OPTION="interactive" ;;
    *) 
      echo "❌ Invalid option. Exiting."
      exit 1
      ;;
  esac
fi

# Process the add operation
case $ADD_OPTION in
  "all")
    echo "📝 Adding all changes..."
    git add .
    ;;
  "tracked")
    echo "📝 Adding only tracked files with changes..."
    git add -u
    ;;
  "specific")
    echo "📝 Select specific files to add:"
    git status -s
    echo ""
    read "files?Enter files/patterns to add (space-separated): "
    for file in $files; do
      git add $file
    done
    ;;
  "interactive")
    echo "📝 Interactive staging..."
    git add -i
    ;;
esac

# Check if there are changes staged for commit
if git diff --cached --quiet; then
  echo "❌ No changes staged for commit. Exiting."
  exit 1
fi

# Show what's staged for commit
echo ""
echo "📋 Changes staged for commit:"
git diff --cached --stat

# Get commit message
COMMIT_MSG=""
if [[ "$1" && "$1" != "--all" ]]; then
  COMMIT_MSG="$1"
else
  echo ""
  echo "Enter commit message:"
  read "COMMIT_MSG?> "
fi

if [[ -z "$COMMIT_MSG" ]]; then
  echo "❌ Empty commit message. Exiting."
  exit 1
fi

# Confirm commit
echo ""
echo "🔍 Ready to commit with message:"
echo "    \"$COMMIT_MSG\""
read "confirm_commit?Proceed with commit? (y/n): "

if [[ ! "$confirm_commit" =~ ^[Yy]$ ]]; then
  echo "❌ Commit aborted."
  exit 1
fi

# Perform the commit
echo "💾 Committing changes..."
git commit -m "$COMMIT_MSG"

if [ $? -ne 0 ]; then
  echo "❌ Commit failed. Exiting."
  exit 1
fi

# Get remote information
echo ""
echo "🌐 Checking remote repository..."
DEFAULT_REMOTE="origin"
DEFAULT_REMOTE_EXISTS=false
REMOTES=$(git remote)

if [ -z "$REMOTES" ]; then
  echo "ℹ️  No remotes found. Skipping push."
  exit 0
else
  if git remote get-url $DEFAULT_REMOTE > /dev/null 2>&1; then
    DEFAULT_REMOTE_EXISTS=true
    echo "ℹ️  Found default remote: $DEFAULT_REMOTE"
  else
    echo "ℹ️  Available remotes:"
    git remote -v
    read "remote_name?Enter remote name to push to: "
    DEFAULT_REMOTE=$remote_name
  fi
fi

# Check if branch exists on remote
UPSTREAM_SET=true
if ! git rev-parse --abbrev-ref @{upstream} &>/dev/null; then
  UPSTREAM_SET=false
  echo "⚠️  No upstream branch set for '$CURRENT_BRANCH'."
  echo "    Will set upstream when pushing."
fi

# Ask to push
echo ""
if [[ "$UPSTREAM_SET" == true ]]; then
  echo "🔍 Will push to: $DEFAULT_REMOTE/$CURRENT_BRANCH"
else
  echo "🔍 Will push and set upstream to: $DEFAULT_REMOTE/$CURRENT_BRANCH"
fi
read "confirm_push?Push changes now? (y/n): "

if [[ ! "$confirm_push" =~ ^[Yy]$ ]]; then
  echo "ℹ️  Push skipped. Changes are committed locally."
  exit 0
fi

# Check for changes on remote
if [[ "$UPSTREAM_SET" == true ]]; then
  echo "🔄 Checking for remote changes..."
  git fetch $DEFAULT_REMOTE $CURRENT_BRANCH
  
  BEHIND=$(git rev-list --count HEAD..@{upstream})
  if [ $BEHIND -gt 0 ]; then
    echo "⚠️  Warning: Remote has $BEHIND commit(s) that you don't have locally."
    echo "   Options:"
    echo "   1. Pull changes first (recommended)"
    echo "   2. Force push (overwrites remote changes)"
    echo "   3. Abort push"
    read "pull_option?Choose an option (1/2/3): "
    
    case $pull_option in
      1)
        echo "⬇️  Pulling changes first..."
        git pull $DEFAULT_REMOTE $CURRENT_BRANCH
        if [ $? -ne 0 ]; then
          echo "❌ Pull failed. Push aborted."
          exit 1
        fi
        ;;
      2)
        echo "⚠️  Force pushing (use with caution)..."
        read "confirm?Are you sure? This will overwrite remote changes (y/n): "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          git push --force $DEFAULT_REMOTE $CURRENT_BRANCH
          echo "✅ Force push successful."
          exit 0
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
fi

# Perform the push
echo "⬆️  Pushing changes to $DEFAULT_REMOTE/$CURRENT_BRANCH..."
if [[ "$UPSTREAM_SET" == false ]]; then
  git push -u $DEFAULT_REMOTE $CURRENT_BRANCH
else
  git push $DEFAULT_REMOTE $CURRENT_BRANCH
fi

# Check result
if [ $? -eq 0 ]; then
  echo "✅ Push successful!"
else
  echo "❌ Push failed. See error message above."
  exit 1
fi

echo ""
echo "✨ All done!"
