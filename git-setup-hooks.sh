#!/bin/zsh

# Script to install useful git hooks for code quality
# Usage: ./git-setup-hooks.sh [language]

echo "🪝 Starting git hooks setup script..."

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

# Define supported languages and their linters/formatters
LANGUAGES=(
  "ruby:rubocop,standardrb"
  "javascript:eslint,prettier"
  "typescript:tslint,eslint,prettier"
  "python:flake8,black,pylint"
  "go:gofmt,golint"
  "shell:shellcheck,shfmt"
  "java:checkstyle,google-java-format"
  "c:clang-format,cppcheck"
  "cpp:clang-format,cppcheck"
)

# Detect repository language if not provided
DETECTED_LANGUAGE=""
if [[ $# -ge 1 ]]; then
  LANGUAGE="$1"
else
  echo "🔍 Detecting repository language..."
  
  # Check for Ruby files
  if [[ -f "Gemfile" || $(find . -name "*.rb" | wc -l) -gt 0 ]]; then
    DETECTED_LANGUAGE="ruby"
  # Check for JavaScript/TypeScript files
  elif [[ -f "package.json" || $(find . -name "*.js" -o -name "*.ts" | wc -l) -gt 0 ]]; then
    if [[ $(find . -name "*.ts" | wc -l) -gt 0 ]]; then
      DETECTED_LANGUAGE="typescript"
    else
      DETECTED_LANGUAGE="javascript"
    fi
  # Check for Python files
  elif [[ -f "requirements.txt" || -f "setup.py" || $(find . -name "*.py" | wc -l) -gt 0 ]]; then
    DETECTED_LANGUAGE="python"
  # Check for Go files
  elif [[ -f "go.mod" || $(find . -name "*.go" | wc -l) -gt 0 ]]; then
    DETECTED_LANGUAGE="go"
  # Check for Shell scripts
  elif [[ $(find . -name "*.sh" | wc -l) -gt 0 ]]; then
    DETECTED_LANGUAGE="shell"
  # Check for Java files
  elif [[ -f "pom.xml" || -f "build.gradle" || $(find . -name "*.java" | wc -l) -gt 0 ]]; then
    DETECTED_LANGUAGE="java"
  # Check for C/C++ files
  elif [[ $(find . -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" | wc -l) -gt 0 ]]; then
    DETECTED_LANGUAGE="cpp"
  elif [[ $(find . -name "*.c" -o -name "*.h" | wc -l) -gt 0 ]]; then
    DETECTED_LANGUAGE="c"
  fi
  
  if [[ -n "$DETECTED_LANGUAGE" ]]; then
    echo "✅ Detected language: $DETECTED_LANGUAGE"
    LANGUAGE="$DETECTED_LANGUAGE"
  else
    echo "⚠️  Could not detect repository language."
    echo "Available languages:"
    for lang_info in "${LANGUAGES[@]}"; do
      lang=${lang_info%%:*}
      echo "   - $lang"
    done
    read "LANGUAGE?Enter repository language: "
  fi
fi

# Validate language and get available tools
VALID_LANGUAGE=false
AVAILABLE_TOOLS=""

for lang_info in "${LANGUAGES[@]}"; do
  lang=${lang_info%%:*}
  if [[ "$lang" == "$LANGUAGE" ]]; then
    VALID_LANGUAGE=true
    AVAILABLE_TOOLS=${lang_info#*:}
    break
  fi
done

if [[ "$VALID_LANGUAGE" == false ]]; then
  echo "❌ Invalid language: $LANGUAGE"
  echo "Available languages:"
  for lang_info in "${LANGUAGES[@]}"; do
    lang=${lang_info%%:*}
    echo "   - $lang"
  done
  exit 1
fi

# Convert tools to array
TOOLS=(${(s:,:)AVAILABLE_TOOLS})
echo "📋 Available tools for $LANGUAGE: ${TOOLS[@]}"

# Ask which tools to use
echo ""
echo "Select which tools to use (comma-separated list, e.g., 1,2):"
for i in {1..${#TOOLS[@]}}; do
  echo "   $i. ${TOOLS[$i-1]}"
done
read "selected?Enter tool numbers (or 'all' for all tools): "

SELECTED_TOOLS=()
if [[ "$selected" == "all" ]]; then
  SELECTED_TOOLS=("${TOOLS[@]}")
else
  # Parse comma-separated selection
  SELECTED_INDICES=(${(s:,:)selected})
  for INDEX in "${SELECTED_INDICES[@]}"; do
    if [[ $INDEX -le ${#TOOLS[@]} && $INDEX -gt 0 ]]; then
      SELECTED_TOOLS+=(${TOOLS[$INDEX-1]})
    else
      echo "⚠️  Invalid selection: $INDEX. Skipping."
    fi
  done
fi

if [[ ${#SELECTED_TOOLS[@]} -eq 0 ]]; then
  echo "❌ No tools selected. Exiting."
  exit 1
fi

echo "✅ Selected tools: ${SELECTED_TOOLS[@]}"

# Create hooks directory if it doesn't exist
HOOKS_DIR="$ROOT_DIR/.git/hooks"
mkdir -p "$HOOKS_DIR"
echo "📁 Git hooks directory: $HOOKS_DIR"

# Check for existing hooks
EXISTING_HOOKS=()
for hook_type in "pre-commit" "commit-msg" "pre-push"; do
  if [[ -x "$HOOKS_DIR/$hook_type" ]]; then
    EXISTING_HOOKS+=("$hook_type")
  fi
done

if [[ ${#EXISTING_HOOKS[@]} -gt 0 ]]; then
  echo "⚠️  Found existing hooks: ${EXISTING_HOOKS[@]}"
  echo "Select an action:"
  echo "   1. Backup and replace existing hooks"
  echo "   2. Append to existing hooks"
  echo "   3. Exit without modifying hooks"
  read "hook_action?Choose an option (1/2/3): "
  
  case $hook_action in
    1)
      echo "📦 Backing up existing hooks..."
      for hook in "${EXISTING_HOOKS[@]}"; do
        mv "$HOOKS_DIR/$hook" "$HOOKS_DIR/$hook.bak.$(date +%Y%m%d%H%M%S)"
        echo "   Backed up: $hook"
      done
      ;;
    2)
      echo "📝 Will append to existing hooks."
      ;;
    3)
      echo "❌ Exiting without modifying hooks."
      exit 0
      ;;
    *)
      echo "❌ Invalid option. Exiting without modifying hooks."
      exit 1
      ;;
  esac
fi

# Create pre-commit hook
echo "📝 Creating pre-commit hook..."
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

cat > "$PRE_COMMIT_HOOK" <<EOF
#!/bin/zsh

# Pre-commit hook for $LANGUAGE repository
# Created by git-setup-hooks.sh on $(date)

echo "🔍 Running pre-commit checks..."

# Get staged files
STAGED_FILES=\$(git diff --cached --name-only --diff-filter=ACM)

# Exit if there are no staged files
if [[ -z "\$STAGED_FILES" ]]; then
  echo "✅ No staged files to check."
  exit 0
fi

# Filter files by extension based on language
EOF

# Add language-specific file filters
case "$LANGUAGE" in
  ruby)
    echo 'LANGUAGE_FILES=$(echo "$STAGED_FILES" | grep -E "\.rb$|\.rake$|Gemfile|Rakefile")' >> "$PRE_COMMIT_HOOK"
    ;;
  javascript)
    echo 'LANGUAGE_FILES=$(echo "$STAGED_FILES" | grep -E "\.js$|\.jsx$|\.json$")' >> "$PRE_COMMIT_HOOK"
    ;;
  typescript)
    echo 'LANGUAGE_FILES=$(echo "$STAGED_FILES" | grep -E "\.ts$|\.tsx$")' >> "$PRE_COMMIT_HOOK"
    ;;
  python)
    echo 'LANGUAGE_FILES=$(echo "$STAGED_FILES" | grep -E "\.py$")' >> "$PRE_COMMIT_HOOK"
    ;;
  go)
    echo 'LANGUAGE_FILES=$(echo "$STAGED_FILES" | grep -E "\.go$")' >> "$PRE_COMMIT_HOOK"
    ;;
  shell)
    echo 'LANGUAGE_FILES=$(echo "$STAGED_FILES" | grep -E "\.sh$|\.zsh$|\.bash$")' >> "$PRE_COMMIT_HOOK"
    ;;
  java)
    echo 'LANGUAGE_FILES=$(echo "$STAGED_FILES" | grep -E "\.java$")' >> "$PRE_COMMIT_HOOK"
    ;;
  c|cpp)
    echo 'LANGUAGE_FILES=$(echo "$STAGED_FILES" | grep -E "\.c$|\.h$|\.cpp$|\.hpp$|\.cc$|\.cxx$")' >> "$PRE_COMMIT_HOOK"
    ;;
esac

cat >> "$PRE_COMMIT_HOOK" <<EOF

# Exit if there are no relevant files to check
if [[ -z "\$LANGUAGE_FILES" ]]; then
  echo "✅ No $LANGUAGE files to check."
  exit 0
fi

EXIT_CODE=0
EOF

# Add tool-specific checks
for tool in "${SELECTED_TOOLS[@]}"; do
  case "$tool" in
    rubocop)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Check code with Rubocop
if command -v rubocop &> /dev/null; then
  echo "🔍 Running Rubocop..."
  echo "\$LANGUAGE_FILES" | xargs rubocop --force-exclusion
  if [[ \$? -ne 0 ]]; then
    echo "❌ Rubocop found issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  Rubocop not found. Install with: gem install rubocop"
fi
EOF
      ;;
    standardrb)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Check code with StandardRB
if command -v standardrb &> /dev/null; then
  echo "🔍 Running StandardRB..."
  echo "\$LANGUAGE_FILES" | xargs standardrb --fix
  if [[ \$? -ne 0 ]]; then
    echo "❌ StandardRB found issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  StandardRB not found. Install with: gem install standard"
fi
EOF
      ;;
    eslint)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Check code with ESLint
if command -v eslint &> /dev/null; then
  echo "🔍 Running ESLint..."
  echo "\$LANGUAGE_FILES" | xargs eslint
  if [[ \$? -ne 0 ]]; then
    echo "❌ ESLint found issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  ESLint not found. Install with: npm install -g eslint"
fi
EOF
      ;;
    prettier)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Format code with Prettier
if command -v prettier &> /dev/null; then
  echo "🔍 Running Prettier..."
  echo "\$LANGUAGE_FILES" | xargs prettier --check
  if [[ \$? -ne 0 ]]; then
    echo "⚠️  Prettier found formatting issues. Run 'prettier --write' to fix."
    EXIT_CODE=1
  fi
else
  echo "⚠️  Prettier not found. Install with: npm install -g prettier"
fi
EOF
      ;;
    flake8)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Check code with Flake8
if command -v flake8 &> /dev/null; then
  echo "🔍 Running Flake8..."
  echo "\$LANGUAGE_FILES" | xargs flake8
  if [[ \$? -ne 0 ]]; then
    echo "❌ Flake8 found issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  Flake8 not found. Install with: pip install flake8"
fi
EOF
      ;;
    black)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Format code with Black
if command -v black &> /dev/null; then
  echo "🔍 Running Black..."
  echo "\$LANGUAGE_FILES" | xargs black --check
  if [[ \$? -ne 0 ]]; then
    echo "⚠️  Black found formatting issues. Run 'black' to fix."
    EXIT_CODE=1
  fi
else
  echo "⚠️  Black not found. Install with: pip install black"
fi
EOF
      ;;
    pylint)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Check code with Pylint
if command -v pylint &> /dev/null; then
  echo "🔍 Running Pylint..."
  echo "\$LANGUAGE_FILES" | xargs pylint
  if [[ \$? -ne 0 ]]; then
    echo "❌ Pylint found issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  Pylint not found. Install with: pip install pylint"
fi
EOF
      ;;
    gofmt)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Format code with gofmt
if command -v gofmt &> /dev/null; then
  echo "🔍 Running gofmt..."
  echo "\$LANGUAGE_FILES" | xargs gofmt -l
  if [[ \$? -ne 0 ]]; then
    echo "❌ gofmt found issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  gofmt not found. It should be included with your Go installation."
fi
EOF
      ;;
    golint)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Check code with golint
if command -v golint &> /dev/null; then
  echo "🔍 Running golint..."
  echo "\$LANGUAGE_FILES" | xargs golint
  if [[ \$? -ne 0 ]]; then
    echo "❌ golint found issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  golint not found. Install with: go get -u golang.org/x/lint/golint"
fi
EOF
      ;;
    shellcheck)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Check shell scripts with ShellCheck
if command -v shellcheck &> /dev/null; then
  echo "🔍 Running ShellCheck..."
  echo "\$LANGUAGE_FILES" | xargs shellcheck
  if [[ \$? -ne 0 ]]; then
    echo "❌ ShellCheck found issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  ShellCheck not found. Install from https://github.com/koalaman/shellcheck"
fi
EOF
      ;;
    shfmt)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Format shell scripts with shfmt
if command -v shfmt &> /dev/null; then
  echo "🔍 Running shfmt..."
  echo "\$LANGUAGE_FILES" | xargs shfmt -d
  if [[ \$? -ne 0 ]]; then
    echo "❌ shfmt found formatting issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  shfmt not found. Install with: go get -u mvdan.cc/sh/cmd/shfmt"
fi
EOF
      ;;
    "clang-format")
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Format code with clang-format
if command -v clang-format &> /dev/null; then
  echo "🔍 Running clang-format..."
  for file in \$LANGUAGE_FILES; do
    clang-format -style=file -output-replacements-xml \$file | grep -q "<replacement "
    if [[ \$? -eq 0 ]]; then
      echo "❌ \$file needs formatting."
      EXIT_CODE=1
    fi
  done
else
  echo "⚠️  clang-format not found. Install from your package manager."
fi
EOF
      ;;
    cppcheck)
      cat >> "$PRE_COMMIT_HOOK" <<EOF

# Check code with cppcheck
if command -v cppcheck &> /dev/null; then
  echo "🔍 Running cppcheck..."
  echo "\$LANGUAGE_FILES" | xargs cppcheck --error-exitcode=1
  if [[ \$? -ne 0 ]]; then
    echo "❌ cppcheck found issues."
    EXIT_CODE=1
  fi
else
  echo "⚠️  cppcheck not found. Install from your package manager."
fi
EOF
      ;;
  esac
done

# Finish the pre-commit hook
cat >> "$PRE_COMMIT_HOOK" <<EOF

# Exit with accumulated status
if [[ \$EXIT_CODE -eq 0 ]]; then
  echo "✅ All checks passed!"
else
  echo "❌ Some checks failed. Fix the issues or use 'git commit --no-verify' to bypass."
fi

exit \$EXIT_CODE
EOF

# Make the hook executable
chmod +x "$PRE_COMMIT_HOOK"
echo "✅ Created pre-commit hook."

# Create commit-msg hook
echo "📝 Creating commit-msg hook..."
COMMIT_MSG_HOOK="$HOOKS_DIR/commit-msg"

cat > "$COMMIT_MSG_HOOK" <<EOF
#!/bin/zsh

# Commit message hook for $LANGUAGE repository
# Created by git-setup-hooks.sh on $(date)

echo "🔍 Checking commit message format..."

# Get the commit message file
COMMIT_MSG_FILE=\$1
COMMIT_MSG=\$(cat \$COMMIT_MSG_FILE)

# Define patterns for conventional commits
# Format: <type>(<scope>): <subject>
# Example: feat(auth): add user authentication

# Conventional commit types
TYPES="feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"

# Check if the commit message follows the conventional format
if ! grep -qE "^($TYPES)(\([a-z0-9_-]+\))?: .+" "\$COMMIT_MSG_FILE"; then
  echo "❌ Commit message does not follow conventional format."
  echo "   Expected format: <type>(<scope>): <subject>"
  echo "   Types: $TYPES"
  echo "   Example: feat(auth): add user authentication"
  echo ""
  echo "   Your commit message: \$(head -n1 \$COMMIT_MSG_FILE)"
  echo ""
  echo "Commit message was not modified."
  echo "You can use 'git commit --no-verify' to bypass this check."
  exit 1
fi

echo "✅ Commit message format is valid."
exit 0
EOF

# Make the hook executable
chmod +x "$COMMIT_MSG_HOOK"
echo "✅ Created commit-msg hook."

# Create pre-push hook to prevent push to protected branches
echo "📝 Creating pre-push hook..."
PRE_PUSH_HOOK="$HOOKS_DIR/pre-push"

cat > "$PRE_PUSH_HOOK" <<EOF
#!/bin/zsh

# Pre-push hook for $LANGUAGE repository
# Created by git-setup-hooks.sh on $(date)

echo "🔍 Running pre-push checks..."

# Get the current branch
CURRENT_BRANCH=\$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

# Define protected branches
PROTECTED_BRANCHES="master main production release"

# Check if current branch is protected
if echo "\$PROTECTED_BRANCHES" | grep -q "\$CURRENT_BRANCH"; then
  echo "⚠️  You're about to push to a protected branch: \$CURRENT_BRANCH"
  echo "   Are you sure you want to do this?"
  read "confirm?Continue? (y/n): "
  
  if [[ ! "\$confirm" =~ ^[Yy]\$ ]]; then
    echo "❌ Push aborted."
    exit 1
  fi
fi

# Run additional checks before push
EXIT_CODE=0

# Check for tests if they exist
if [[ -d "test" || -d "spec" || -d "tests" ]]; then
  echo "🧪 Checking for failing tests..."
  
  # Choose the right test command based on language and available tools
  case "$LANGUAGE" in
    ruby)
      if [ -f "Rakefile" ] && grep -q "task.*test" "Rakefile"; then
        rake test
      elif [ -f "Rakefile" ] && grep -q "task.*spec" "Rakefile"; then
        rake spec
      elif command -v rspec &> /dev/null; then
        rspec
      else
        echo "⚠️  No test command found. Skipping tests."
      fi
      ;;
    javascript|typescript)
      if [ -f "package.json" ]; then
        if grep -q "test" "package.json"; then
          npm test
        else
          echo "⚠️  No test command found in package.json. Skipping tests."
        fi
      else
        echo "⚠️  No package.json found. Skipping tests."
      fi
      ;;
    python)
      if [ -f "pytest.ini" ]; then
        pytest
      elif [ -f "setup.py" ]; then
        python setup.py test
      elif [ -d "tests" ]; then
        python -m unittest discover
      else
        echo "⚠️  No test command found. Skipping tests."
      fi
      ;;
    go)
      go test ./...
      ;;
    *)
      echo "⚠️  No test command defined for $LANGUAGE. Skipping tests."
      ;;
  esac
  
  if [[ \$? -ne 0 ]]; then
    echo "❌ Tests failed."
    EXIT_CODE=1
  fi
else
  echo "⚠️  No test directory found. Skipping tests."
fi

if [[ \$EXIT_CODE -eq 0 ]]; then
  echo "✅ All pre-push checks passed!"
else
  echo "❌ Some pre-push checks failed. Fix the issues or use 'git push --no-verify' to bypass."
fi

exit \$EXIT_CODE
EOF

# Make the hook executable
chmod +x "$PRE_PUSH_HOOK"
echo "✅ Created pre-push hook."

# Create a commit template
echo "📝 Creating commit message template..."
TEMPLATE_FILE="$ROOT_DIR/.gitmessage"

cat > "$TEMPLATE_FILE" <<EOF
# <type>(<scope>): <subject>
# |<----  Using a Maximum Of 50 Characters  ---->|

# <body>
# |<----   Try To Limit Each Line to a Maximum Of 72 Characters   ---->|

# <footer>

# --- COMMIT END ---
# Type can be 
#    feat     (new feature)
#    fix      (bug fix)
#    docs     (changes to documentation)
#    style    (formatting, missing semi colons, etc; no code change)
#    refactor (refactoring production code)
#    test     (adding missing tests, refactoring tests; no production code change)
#    chore    (updating grunt tasks etc; no production code change)
# --------------------
# Scope is optional and could be anything specifying place of the commit change.
# Remember to:
#    Capitalize the subject line
#    Use the imperative mood in the subject line
#    Do not end the subject line with a period
#    Separate subject from body with a blank line
#    Use the body to explain what and why vs. how
#    Separate each paragraph/bullet with a blank line
# --------------------
EOF

# Configure git to use the template
git config --local commit.template .gitmessage
echo "✅ Created commit message template and configured git to use it."

# Set up global hooks configuration
echo "📝 Setting up global hooks configuration..."
GLOBAL_CONFIG_DIR="$ROOT_DIR/.githooks"
mkdir -p "$GLOBAL_CONFIG_DIR"

# Create a configuration file for the hooks
cat > "$GLOBAL_CONFIG_DIR/config.json" <<EOF
{
  "version": "1.0.0",
  "language": "$LANGUAGE",
  "tools": [
    $(printf '"%s"' "${SELECTED_TOOLS[0]}")$(printf ', "%s"' "${SELECTED_TOOLS[@]:1}")
  ],
  "protected_branches": [
    "master",
    "main",
    "production",
    "release"
  ],
  "installed_at": "$(date)"
}
EOF

echo "✅ Created hooks configuration."

# Final instructions
echo ""
echo "✨ Git hooks have been successfully set up!"
echo ""
echo "The following hooks have been installed:"
echo "   - pre-commit: Runs linters and formatters on staged files"
echo "   - commit-msg: Ensures commit messages follow conventional format"
echo "   - pre-push: Prevents accidental pushes to protected branches and runs tests"
echo ""
echo "A commit message template has been configured."
echo ""
echo "To bypass hooks temporarily, you can use:"
echo "   git commit --no-verify"
echo "   git push --no-verify"
echo ""
echo "To update or remove hooks, edit or remove files in:"
echo "   $HOOKS_DIR"
echo ""
echo "To customize hook configuration, edit:"
echo "   $GLOBAL_CONFIG_DIR/config.json"
echo ""
echo "✨ All done!"