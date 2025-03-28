#!/bin/zsh

# Script to create a summary of changes between git versions
# Usage: ./git-summarize-changes.sh [from-ref] [to-ref] [--markdown|--txt|--html]

echo "📋 Starting git change summary script..."

# Ensure we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "❌ Error: Not in a git repository. Please run this script from within a git repository."
  exit 1
fi

# Get the root directory of the git repository
ROOT_DIR=$(git rev-parse --show-toplevel)
cd "$ROOT_DIR"

echo "📍 Working in git repository root: $ROOT_DIR"

# Get repository name
REPO_NAME=$(basename "$ROOT_DIR")
echo "📦 Repository: $REPO_NAME"

# Parse arguments
FROM_REF=""
TO_REF=""
FORMAT="markdown"

if [[ $# -ge 1 ]]; then
  FROM_REF=$1
fi

if [[ $# -ge 2 ]]; then
  TO_REF=$2
fi

if [[ $# -ge 3 ]]; then
  case $3 in
    --markdown) FORMAT="markdown" ;;
    --txt) FORMAT="txt" ;;
    --html) FORMAT="html" ;;
    *) echo "⚠️  Unknown format option: $3. Using markdown as default." ;;
  esac
fi

# If refs are not provided, offer to choose them
if [[ -z "$FROM_REF" ]]; then
  echo "Select the starting reference point:"
  echo "   1. Choose from tags"
  echo "   2. Choose from branches"
  echo "   3. Enter a specific commit hash"
  read "choice?Select option (1/2/3): "
  
  case $choice in
    1)
      echo "Available tags:"
      git tag | sort -V | nl
      read "tag_num?Enter tag number: "
      FROM_REF=$(git tag | sort -V | sed -n "${tag_num}p")
      ;;
    2)
      echo "Available branches:"
      git branch | grep -v "^\*" | sed 's/^[ \t]*//' | nl
      read "branch_num?Enter branch number: "
      FROM_REF=$(git branch | grep -v "^\*" | sed 's/^[ \t]*//' | sed -n "${branch_num}p")
      ;;
    3)
      read "FROM_REF?Enter commit hash: "
      ;;
    *)
      echo "❌ Invalid option. Using the oldest commit as starting point."
      FROM_REF=$(git rev-list --max-parents=0 HEAD)
      ;;
  esac
fi

if [[ -z "$TO_REF" ]]; then
  echo "Select the ending reference point:"
  echo "   1. HEAD (current state)"
  echo "   2. Choose from tags"
  echo "   3. Choose from branches"
  echo "   4. Enter a specific commit hash"
  read "choice?Select option (1/2/3/4): "
  
  case $choice in
    1)
      TO_REF="HEAD"
      ;;
    2)
      echo "Available tags:"
      git tag | sort -V | nl
      read "tag_num?Enter tag number: "
      TO_REF=$(git tag | sort -V | sed -n "${tag_num}p")
      ;;
    3)
      echo "Available branches:"
      git branch | grep -v "^\*" | sed 's/^[ \t]*//' | nl
      read "branch_num?Enter branch number: "
      TO_REF=$(git branch | grep -v "^\*" | sed 's/^[ \t]*//' | sed -n "${branch_num}p")
      ;;
    4)
      read "TO_REF?Enter commit hash: "
      ;;
    *)
      echo "❌ Invalid option. Using HEAD as ending point."
      TO_REF="HEAD"
      ;;
  esac
fi

echo "Generating summary of changes from $FROM_REF to $TO_REF..."

# Get commit range nicely formatted
RANGE="$FROM_REF..$TO_REF"
if [[ "$TO_REF" == "HEAD" ]]; then
  CURRENT_BRANCH=$(git branch --show-current)
  PRETTY_TO="$CURRENT_BRANCH (current)"
else
  PRETTY_TO="$TO_REF"
fi

# Get commit count
COMMIT_COUNT=$(git rev-list --count "$RANGE")

# Get date range
FROM_DATE=$(git show -s --format=%ci "$FROM_REF")
TO_DATE=$(git show -s --format=%ci "$TO_REF")

# Get authors
AUTHORS=$(git log "$RANGE" --format="%an" | sort | uniq -c | sort -nr)

# Create categories for meaningful grouping
declare -A CATEGORIES
CATEGORIES=(
  ["feature"]="New Features"
  ["feat"]="New Features"
  ["add"]="New Features"
  ["fix"]="Bug Fixes"
  ["bug"]="Bug Fixes"
  ["docs"]="Documentation"
  ["doc"]="Documentation"
  ["style"]="Style Improvements"
  ["refactor"]="Code Refactoring"
  ["perf"]="Performance Improvements"
  ["test"]="Tests"
  ["build"]="Build System"
  ["ci"]="CI/CD Changes"
  ["chore"]="Chores"
)

# Function to categorize a commit message
categorize_commit() {
  local msg="$1"
  local category="Other Changes"
  
  # Check for conventional commit format first (type: message)
  if [[ "$msg" =~ ^([a-z]+)(\([a-z0-9_-]+\))?!?:\ .* ]]; then
    local type="${match[1]}"
    if [[ -n "${CATEGORIES[$type]}" ]]; then
      category="${CATEGORIES[$type]}"
    fi
  else
    # Check for keywords in the message
    for key in "${(@k)CATEGORIES}"; do
      if [[ "$msg" =~ (?i)$key ]]; then
        category="${CATEGORIES[$key]}"
        break
      fi
    done
  fi
  
  echo "$category"
}

# Get commits grouped by category
declare -A COMMITS_BY_CATEGORY
for category in "${(@v)CATEGORIES}"; do
  COMMITS_BY_CATEGORY[$category]=()
done
COMMITS_BY_CATEGORY["Other Changes"]=()

# Get commits and categorize them
while read -r HASH MSG; do
  CATEGORY=$(categorize_commit "$MSG")
  COMMITS_BY_CATEGORY[$CATEGORY]+="$HASH $MSG"
done < <(git log --pretty=format:"%h %s" "$RANGE")

# File changes summary
FILES_CHANGED=$(git diff --name-only "$RANGE" | wc -l | tr -d ' ')
INSERTIONS=$(git diff --shortstat "$RANGE" | grep -o '[0-9]\+ insertion' | cut -d' ' -f1)
DELETIONS=$(git diff --shortstat "$RANGE" | grep -o '[0-9]\+ deletion' | cut -d' ' -f1)
INSERTIONS=${INSERTIONS:-0}
DELETIONS=${DELETIONS:-0}

# Prepare output
OUTPUT_FILE="$ROOT_DIR/CHANGELOG_${FROM_REF}_to_${TO_REF}.${FORMAT}"

# Generate output based on format
case $FORMAT in
  markdown)
    echo "# Changelog: $FROM_REF to $PRETTY_TO" > "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "## Summary" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "- **Period**: $(date -d "$FROM_DATE" +"%Y-%m-%d") to $(date -d "$TO_DATE" +"%Y-%m-%d")" >> "$OUTPUT_FILE"
    echo "- **Commits**: $COMMIT_COUNT" >> "$OUTPUT_FILE"
    echo "- **Files Changed**: $FILES_CHANGED" >> "$OUTPUT_FILE"
    echo "- **Lines Added**: $INSERTIONS" >> "$OUTPUT_FILE"
    echo "- **Lines Removed**: $DELETIONS" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    echo "## Contributors" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "$AUTHORS" | while read -r COUNT AUTHOR; do
      echo "- **$AUTHOR**: $COUNT commits" >> "$OUTPUT_FILE"
    done
    echo "" >> "$OUTPUT_FILE"
    
    for category in "${(@k)COMMITS_BY_CATEGORY}"; do
      if [[ ${#COMMITS_BY_CATEGORY[$category]} -gt 0 ]]; then
        echo "## $category" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        for commit in "${COMMITS_BY_CATEGORY[$category]}"; do
          HASH=$(echo "$commit" | cut -d' ' -f1)
          MSG=$(echo "$commit" | cut -d' ' -f2-)
          AUTHOR=$(git show -s --format="%an" "$HASH")
          DATE=$(git show -s --format="%ad" --date=short "$HASH")
          echo "- $MSG ([${HASH}](../../commit/${HASH})) - $AUTHOR, $DATE" >> "$OUTPUT_FILE"
        done
        echo "" >> "$OUTPUT_FILE"
      fi
    done
    ;;
    
  txt)
    echo "Changelog: $FROM_REF to $PRETTY_TO" > "$OUTPUT_FILE"
    echo "=================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "Summary:" >> "$OUTPUT_FILE"
    echo "--------" >> "$OUTPUT_FILE"
    echo "- Period: $(date -d "$FROM_DATE" +"%Y-%m-%d") to $(date -d "$TO_DATE" +"%Y-%m-%d")" >> "$OUTPUT_FILE"
    echo "- Commits: $COMMIT_COUNT" >> "$OUTPUT_FILE"
    echo "- Files Changed: $FILES_CHANGED" >> "$OUTPUT_FILE"
    echo "- Lines Added: $INSERTIONS" >> "$OUTPUT_FILE"
    echo "- Lines Removed: $DELETIONS" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    echo "Contributors:" >> "$OUTPUT_FILE"
    echo "-------------" >> "$OUTPUT_FILE"
    echo "$AUTHORS" | while read -r COUNT AUTHOR; do
      echo "- $AUTHOR: $COUNT commits" >> "$OUTPUT_FILE"
    done
    echo "" >> "$OUTPUT_FILE"
    
    for category in "${(@k)COMMITS_BY_CATEGORY}"; do
      if [[ ${#COMMITS_BY_CATEGORY[$category]} -gt 0 ]]; then
        echo "$category:" >> "$OUTPUT_FILE"
        echo "$(printf -- '-%.0s' {1..${#category}}):" >> "$OUTPUT_FILE"
        for commit in "${COMMITS_BY_CATEGORY[$category]}"; do
          HASH=$(echo "$commit" | cut -d' ' -f1)
          MSG=$(echo "$commit" | cut -d' ' -f2-)
          AUTHOR=$(git show -s --format="%an" "$HASH")
          DATE=$(git show -s --format="%ad" --date=short "$HASH")
          echo "- $MSG (${HASH}) - $AUTHOR, $DATE" >> "$OUTPUT_FILE"
        done
        echo "" >> "$OUTPUT_FILE"
      fi
    done
    ;;
    
  html)
    echo "<!DOCTYPE html>
<html>
<head>
  <meta charset=\"UTF-8\">
  <title>Changelog: $FROM_REF to $PRETTY_TO</title>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0 auto; max-width: 800px; padding: 20px; }
    h1, h2 { color: #333; }
    .summary { background-color: #f5f5f5; padding: 15px; border-radius: 5px; }
    .commit { margin-bottom: 10px; }
    .hash { color: #0366d6; text-decoration: none; font-family: monospace; }
    .author { color: #6a737d; }
    .date { color: #6a737d; }
  </style>
</head>
<body>
  <h1>Changelog: $FROM_REF to $PRETTY_TO</h1>
  
  <div class=\"summary\">
    <h2>Summary</h2>
    <ul>
      <li><strong>Period:</strong> $(date -d "$FROM_DATE" +"%Y-%m-%d") to $(date -d "$TO_DATE" +"%Y-%m-%d")</li>
      <li><strong>Commits:</strong> $COMMIT_COUNT</li>
      <li><strong>Files Changed:</strong> $FILES_CHANGED</li>
      <li><strong>Lines Added:</strong> $INSERTIONS</li>
      <li><strong>Lines Removed:</strong> $DELETIONS</li>
    </ul>
  </div>
  
  <h2>Contributors</h2>
  <ul>" > "$OUTPUT_FILE"
  
  echo "$AUTHORS" | while read -r COUNT AUTHOR; do
    echo "    <li><strong>$AUTHOR:</strong> $COUNT commits</li>" >> "$OUTPUT_FILE"
  done
  
  echo "  </ul>" >> "$OUTPUT_FILE"
  
  for category in "${(@k)COMMITS_BY_CATEGORY}"; do
    if [[ ${#COMMITS_BY_CATEGORY[$category]} -gt 0 ]]; then
      echo "  <h2>$category</h2>
  <ul>" >> "$OUTPUT_FILE"
      for commit in "${COMMITS_BY_CATEGORY[$category]}"; do
        HASH=$(echo "$commit" | cut -d' ' -f1)
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        AUTHOR=$(git show -s --format="%an" "$HASH")
        DATE=$(git show -s --format="%ad" --date=short "$HASH")
        echo "    <li class=\"commit\">
      $MSG (<a href=\"../../commit/${HASH}\" class=\"hash\">$HASH</a>) - 
      <span class=\"author\">$AUTHOR</span>, 
      <span class=\"date\">$DATE</span>
    </li>" >> "$OUTPUT_FILE"
      done
      echo "  </ul>" >> "$OUTPUT_FILE"
    fi
  done
  
  echo "</body>
</html>" >> "$OUTPUT_FILE"
    ;;
esac

echo "✅ Changelog generated: $OUTPUT_FILE"
echo "✨ All done!"
