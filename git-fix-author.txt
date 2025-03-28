#!/bin/zsh

# Script to correct author information in git commits
# Usage: ./git-fix-author.sh [--all|--specific]

echo "👤 Starting git author information fix script..."

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get the root directory of the git repository
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

echo "📍 Working in git repository root: $ROOT_DIR"

# Get current git config for reference
CURRENT_NAME=$(git config user.name)
CURRENT_EMAIL=$(git config user.email)

echo "Current git config:"
echo "   Name: $CURRENT_NAME"
echo "   Email: $CURRENT_EMAIL"
echo ""

# Determine mode
MODE="interactive"
if [[ "$1" == "--all" ]]; then
  MODE="all"
elif [[ "$1" == "--specific" ]]; then
  MODE="specific"
fi

if [[ "$MODE" == "interactive" ]]; then
  echo "How would you like to fix author information?"
  echo "   1. Fix all commits with incorrect author information"
  echo "   2. Fix specific commits"
  echo "   3. Fix all commits by a specific author"
  read "choice?Choose an option (1/2/3): "
  
  case $choice in
    1) MODE="all" ;;
    2) MODE="specific" ;;
    3) MODE="author" ;;
    *) 
      echo "❌ Invalid option. Exiting."
      exit 1
      ;;
  esac
fi

# Get new author information
echo "Enter the correct author information:"
read "NEW_NAME?New Name (default: $CURRENT_NAME): "
read "NEW_EMAIL?New Email (default: $CURRENT_EMAIL): "

# Use defaults if empty
NEW_NAME=${NEW_NAME:-$CURRENT_NAME}
NEW_EMAIL=${NEW_EMAIL:-$CURRENT_EMAIL}

echo "✅ Will use author: $NEW_NAME <$NEW_EMAIL>"

# Function to display commits
display_commits() {
  local commits=("$@")
  echo "------------------------------------------------"
  echo "| # | Commit Hash | Date | Author | Message |"
  echo "------------------------------------------------"
  local i=1
  for commit in "${commits[@]}"; do
    local hash=$(echo $commit | cut -d' ' -f1)
    local date=$(git show -s --format=%ci $hash)
    local author=$(git show -s --format='%an <%ae>' $hash)
    local message=$(git show -s --format=%s $hash | cut -c1-30)
    printf "| %-2s | %.10s | %.10s | %-30s | %-30s |\n" "$i" "$hash" "$date" "$author" "$message"
    ((i++))
  done
  echo "------------------------------------------------"
}

case $MODE in
  "all")
    echo "⚠️  WARNING: This will change the author in ALL commits in the repository."
    echo "    This rewrites git history and requires a force push."
    read "confirm?Are you sure you want to proceed? (y/n): "
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "❌ Operation canceled."
      exit 0
    fi
    
    echo "🔄 Rewriting all commits with new author information..."
    git filter-branch --env-filter "
      export GIT_AUTHOR_NAME='$NEW_NAME'
      export GIT_AUTHOR_EMAIL='$NEW_EMAIL'
      export GIT_COMMITTER_NAME='$NEW_NAME'
      export GIT_COMMITTER_EMAIL='$NEW_EMAIL'
    " --tag-name-filter cat -- --all
    
    echo "✅ All commits have been updated with the new author information."
    ;;
    
  "specific")
    # List recent commits
    echo "🔍 Listing recent commits..."
    COMMITS=($(git log --pretty=format:"%H %an <%ae>" -n 20))
    
    display_commits "${COMMITS[@]}"
    
    echo "Enter the numbers of the commits to fix (comma-separated, e.g. 1,3,5):"
    read "selected?Commits to fix: "
    
    if [[ -z "$selected" ]]; then
      echo "❌ No commits selected. Exiting."
      exit 0
    fi
    
    # Parse comma-separated selection
    SELECTED_INDICES=(${(s:,:)selected})
    COMMITS_TO_FIX=()
    
    for INDEX in "${SELECTED_INDICES[@]}"; do
      if [[ $INDEX -le ${#COMMITS[@]} && $INDEX -gt 0 ]]; then
        COMMIT_HASH=$(echo ${COMMITS[$INDEX-1]} | cut -d' ' -f1)
        COMMITS_TO_FIX+=($COMMIT_HASH)
      else
        echo "⚠️  Invalid selection: $INDEX. Skipping."
      fi
    done
    
    if [[ ${#COMMITS_TO_FIX[@]} -eq 0 ]]; then
      echo "❌ No valid commits selected. Exiting."
      exit 0
    fi
    
    echo "⚠️  WARNING: This will rewrite git history for the selected commits."
    echo "    You will need to force push after this operation."
    read "confirm?Are you sure you want to proceed? (y/n): "
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "❌ Operation canceled."
      exit 0
    fi
    
    echo "🔄 Rewriting selected commits with new author information..."
    
    for COMMIT in "${COMMITS_TO_FIX[@]}"; do
      git filter-branch --env-filter "
        if [ \$GIT_COMMIT = $COMMIT ]; then
          export GIT_AUTHOR_NAME='$NEW_NAME'
          export GIT_AUTHOR_EMAIL='$NEW_EMAIL'
          export GIT_COMMITTER_NAME='$NEW_NAME'
          export GIT_COMMITTER_EMAIL='$NEW_EMAIL'
        fi
      " --tag-name-filter cat -- --all
    done
    
    echo "✅ Selected commits have been updated with the new author information."
    ;;
    
  "author")
    echo "Enter the current author information to fix:"
    read "OLD_NAME?Old Name: "
    read "OLD_EMAIL?Old Email (optional): "
    
    if [[ -z "$OLD_NAME" && -z "$OLD_EMAIL" ]]; then
      echo "❌ You must specify at least a name or email to search for. Exiting."
      exit 1
    fi
    
    # Construct search criteria
    SEARCH_CRITERIA=""
    if [[ -n "$OLD_NAME" && -n "$OLD_EMAIL" ]]; then
      SEARCH_CRITERIA="$OLD_NAME <$OLD_EMAIL>"
    elif [[ -n "$OLD_NAME" ]]; then
      SEARCH_CRITERIA="$OLD_NAME"
    else
      SEARCH_CRITERIA="$OLD_EMAIL"
    fi
    
    echo "🔍 Finding commits by author: $SEARCH_CRITERIA"
    
    # Find commits by the specified author
    if [[ -n "$OLD_EMAIL" ]]; then
      COMMITS=($(git log --author="$OLD_EMAIL" --pretty=format:"%H %an <%ae>"))
    else
      COMMITS=($(git log --author="$OLD_NAME" --pretty=format:"%H %an <%ae>"))
    fi
    
    if [[ ${#COMMITS[@]} -eq 0 ]]; then
      echo "❌ No commits found with the specified author. Exiting."
      exit 0
    fi
    
    echo "📋 Found ${#COMMITS[@]} commits by the specified author."
    
    # Display first 10 commits
    if [[ ${#COMMITS[@]} -gt 10 ]]; then
      echo "Displaying first 10 commits:"
      display_commits "${COMMITS[@]:0:10}"
      echo "... and ${#COMMITS[@]-10} more."
    else
      display_commits "${COMMITS[@]}"
    fi
    
    echo "⚠️  WARNING: This will change the author for ALL these commits."
    echo "    This rewrites git history and requires a force push."
    read "confirm?Are you sure you want to proceed? (y/n): "
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "❌ Operation canceled."
      exit 0
    fi
    
    echo "🔄 Rewriting commits with new author information..."
    
    # Prepare filter expression based on what was provided
    FILTER_EXPR=""
    if [[ -n "$OLD_NAME" && -n "$OLD_EMAIL" ]]; then
      FILTER_EXPR="if [ \"\$GIT_AUTHOR_NAME\" = \"$OLD_NAME\" ] && [ \"\$GIT_AUTHOR_EMAIL\" = \"$OLD_EMAIL\" ]; then"
    elif [[ -n "$OLD_NAME" ]]; then
      FILTER_EXPR="if [ \"\$GIT_AUTHOR_NAME\" = \"$OLD_NAME\" ]; then"
    else
      FILTER_EXPR="if [ \"\$GIT_AUTHOR_EMAIL\" = \"$OLD_EMAIL\" ]; then"
    fi
    
    git filter-branch --env-filter "
      $FILTER_EXPR
        export GIT_AUTHOR_NAME='$NEW_NAME'
        export GIT_AUTHOR_EMAIL='$NEW_EMAIL'
        export GIT_COMMITTER_NAME='$NEW_NAME'
        export GIT_COMMITTER_EMAIL='$NEW_EMAIL'
      fi
    " --tag-name-filter cat -- --all
    
    echo "✅ All commits by the specified author have been updated."
    ;;
esac

# Clean up
echo "🧹 Cleaning up..."
git for-each-ref --format="%(refname)" refs/original/ | xargs -n 1 git update-ref -d
git reflog expire --expire=now --all
git gc --prune=now

echo "⚠️  You need to force push these changes to update the remote repository:"
echo "    git push origin --force --all"
echo "⚠️  Team members will need to reclone or carefully rebase their repositories."

echo "✨ All done!"