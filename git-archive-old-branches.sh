#!/bin/zsh

# Script to identify and archive/delete inactive branches
# Usage: ./git-archive-old-branches.sh [months] [--delete]

echo "🗄️  Starting branch archiving script..."

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get the root directory of the git repository
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

echo "📍 Working in git repository root: $ROOT_DIR"

# Parse arguments
MONTHS=${1:-3}  # Default to 3 months
DELETE_MODE=false
if [[ "$2" == "--delete" ]]; then
  DELETE_MODE=true
  echo "⚠️  DELETE MODE ENABLED: Branches will be deleted after confirmation"
else
  echo "ℹ️  ARCHIVE MODE: Branches will be archived as refs/archived/"
fi

echo "🔍 Looking for branches not modified in the last $MONTHS months..."

# Get current date in seconds since epoch
CURRENT_DATE=$(date +%s)
# Convert months to seconds
THRESHOLD_SECONDS=$((MONTHS * 30 * 24 * 60 * 60))

# Create a temporary file to store branch data
TEMP_FILE=$(mktemp)

# Get all branches and their last commit dates
git for-each-ref --sort=committerdate refs/heads/ --format='%(refname:short) %(committerdate:unix)' > "$TEMP_FILE"

# Protected branches that will never be archived/deleted
PROTECTED_BRANCHES=("master" "main" "develop" "release" "staging" "production")

# Initialize arrays for branches to process
OLD_BRANCHES=()
BRANCH_DATES=()
BRANCH_AGE=()

# Read the branch data
while read -r BRANCH COMMIT_DATE; do
  # Skip protected branches
  if [[ " ${PROTECTED_BRANCHES[@]} " =~ " ${BRANCH} " ]]; then
    continue
  fi
  
  # Calculate age in seconds
  AGE_SECONDS=$((CURRENT_DATE - COMMIT_DATE))
  
  # Check if branch is older than threshold
  if [[ $AGE_SECONDS -gt $THRESHOLD_SECONDS ]]; then
    # Calculate age in days for display
    AGE_DAYS=$((AGE_SECONDS / 86400))
    
    # Store branch info
    OLD_BRANCHES+=("$BRANCH")
    BRANCH_DATES+=("$(date -r $COMMIT_DATE '+%Y-%m-%d')")
    BRANCH_AGE+=("$AGE_DAYS")
  fi
done < "$TEMP_FILE"

# Remove temporary file
rm "$TEMP_FILE"

# Check if we found any old branches
if [[ ${#OLD_BRANCHES[@]} -eq 0 ]]; then
  echo "✅ No inactive branches found older than $MONTHS months."
  exit 0
fi

# Display old branches
echo "📋 Found ${#OLD_BRANCHES[@]} inactive branches:"
echo "------------------------------------------------"
echo "| Branch | Last Modified | Age (Days) |"
echo "------------------------------------------------"
for i in {1..${#OLD_BRANCHES[@]}}; do
  printf "| %-30s | %-12s | %-9s |\n" "${OLD_BRANCHES[$i-1]}" "${BRANCH_DATES[$i-1]}" "${BRANCH_AGE[$i-1]}"
done
echo "------------------------------------------------"

# Ask what to do with these branches
echo ""
if [[ "$DELETE_MODE" == true ]]; then
  echo "⚠️  These branches will be DELETED. This operation cannot be undone."
  read "confirm?Are you sure you want to delete these branches? (y/n): "
  
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "🗑️  Deleting inactive branches..."
    for BRANCH in "${OLD_BRANCHES[@]}"; do
      echo "   Deleting branch: $BRANCH"
      git branch -D "$BRANCH"
    done
    echo "✅ All inactive branches have been deleted."
  else
    echo "❌ Operation canceled. No branches were deleted."
    exit 0
  fi
else
  echo "🗄️  These branches will be archived under refs/archived/"
  read "confirm?Are you sure you want to archive these branches? (y/n): "
  
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Ensure archive directory exists
    git show-ref refs/archived &>/dev/null || git update-ref refs/archived HEAD
    
    echo "🗄️  Archiving inactive branches..."
    for BRANCH in "${OLD_BRANCHES[@]}"; do
      echo "   Archiving branch: $BRANCH"
      # Create timestamp for unique archive names
      TIMESTAMP=$(date +%Y%m%d%H%M%S)
      # Create the archive reference
      git update-ref "refs/archived/$BRANCH-$TIMESTAMP" "refs/heads/$BRANCH"
      # Delete the original branch
      git branch -D "$BRANCH"
    done
    echo "✅ All inactive branches have been archived."
    echo "ℹ️  To view archived branches, use: git show-ref | grep refs/archived/"
    echo "ℹ️  To restore an archived branch, use: git checkout -b new_branch_name refs/archived/branch_name"
  else
    echo "❌ Operation canceled. No branches were archived."
    exit 0
  fi
fi

echo "✨ All done!"
