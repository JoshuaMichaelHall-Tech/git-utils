#!/bin/zsh

# Script to identify and remove branches that have been merged into the main branch
# Usage: ./git-prune-merged-branches.sh [main-branch-name]

echo "🌿 Starting merged branch pruning script..."

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get the root directory of the git repository
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

echo "📍 Working in git repository root: $ROOT_DIR"

# Determine main branch
if [[ -n "$1" ]]; then
  MAIN_BRANCH="$1"
else
  # Try to automatically detect main branch
  if git show-ref --verify --quiet refs/heads/main; then
    MAIN_BRANCH="main"
  elif git show-ref --verify --quiet refs/heads/master; then
    MAIN_BRANCH="master"
  else
    # Get the most active branch
    MAIN_BRANCH=$(git branch -l --sort=-committerdate | head -n1 | tr -d '* ')
    echo "⚠️  No main or master branch found. Using most active branch: $MAIN_BRANCH"
    read "confirm?Is this correct? (y/n): "
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "Please specify the main branch name as a parameter."
      exit 1
    fi
  fi
fi

echo "🔍 Using $MAIN_BRANCH as the main branch"

# Update main branch with remote changes
echo "⬇️  Updating local $MAIN_BRANCH branch..."
git checkout "$MAIN_BRANCH"
git fetch origin "$MAIN_BRANCH"
git pull origin "$MAIN_BRANCH"

# Find all branches that have been merged into main
echo "🔍 Identifying branches fully merged into $MAIN_BRANCH..."
MERGED_BRANCHES=($(git branch --merged "$MAIN_BRANCH" | grep -v "^\*" | grep -v "$MAIN_BRANCH" | grep -v "develop" | grep -v "staging" | grep -v "production" | tr -d ' '))

# Check if there are any merged branches
if [[ ${#MERGED_BRANCHES[@]} -eq 0 ]]; then
  echo "✅ No merged branches found to prune."
  exit 0
fi

# Display merged branches
echo "📋 Found ${#MERGED_BRANCHES[@]} branches merged into $MAIN_BRANCH:"
echo "------------------------------------------------"
for i in {1..${#MERGED_BRANCHES[@]}}; do
  echo "   $i. ${MERGED_BRANCHES[$i-1]}"
done
echo "------------------------------------------------"

# Ask user what they want to do
echo ""
echo "Select an action:"
echo "   1. Delete all merged branches"
echo "   2. Select specific branches to delete"
echo "   3. Exit without deleting any branches"
read "choice?Choose an option (1/2/3): "

case $choice in
  1)
    echo "🗑️  Deleting all merged branches..."
    for BRANCH in "${MERGED_BRANCHES[@]}"; do
      echo "   Deleting branch: $BRANCH"
      git branch -d "$BRANCH"
    done
    echo "✅ All merged branches have been deleted."
    ;;
  2)
    echo "Select branches to delete (comma-separated list, e.g., 1,3,5):"
    read "selected?Enter numbers: "
    
    # Parse comma-separated selection
    SELECTED_INDICES=(${(s:,:)selected})
    
    echo "🗑️  Deleting selected branches..."
    for INDEX in "${SELECTED_INDICES[@]}"; do
      if [[ $INDEX -le ${#MERGED_BRANCHES[@]} && $INDEX -gt 0 ]]; then
        BRANCH=${MERGED_BRANCHES[$INDEX-1]}
        echo "   Deleting branch: $BRANCH"
        git branch -d "$BRANCH"
      else
        echo "⚠️  Invalid selection: $INDEX. Skipping."
      fi
    done
    echo "✅ Selected branches have been deleted."
    ;;
  3)
    echo "❌ Operation canceled. No branches were deleted."
    exit 0
    ;;
  *)
    echo "❌ Invalid option. No branches were deleted."
    exit 1
    ;;
esac

# Check if we need to push the changes to remote
echo ""
echo "Would you like to remove these branches from the remote repository as well?"
read "remote_delete?Delete branches from remote? (y/n): "

if [[ "$remote_delete" =~ ^[Yy]$ ]]; then
  echo "🌍 Removing branches from remote..."
  for BRANCH in "${MERGED_BRANCHES[@]}"; do
    # Check if branch exists on remote before attempting to delete
    if git branch -r | grep -q "origin/$BRANCH"; then
      echo "   Deleting remote branch: origin/$BRANCH"
      git push origin --delete "$BRANCH"
    fi
  done
  echo "✅ Remote branches have been removed."
fi

echo "✨ All done!"
