#!/bin/zsh

# Script to run another script on all first-level subdirectories
# With support for saving and reusing user input across repositories
# Usage: ./run-on-all-repos.sh script_to_run.sh [--auto-respond] [--parent-dir]

# Parse arguments
AUTO_RESPOND=false
PARENT_DIR=false
SCRIPT_TO_RUN=""

for arg in "$@"; do
  if [[ "$arg" == "--auto-respond" ]]; then
    AUTO_RESPOND=true
  elif [[ "$arg" == "--parent-dir" ]]; then
    PARENT_DIR=true
  elif [[ "$arg" != --* ]]; then
    SCRIPT_TO_RUN="$arg"
  fi
done

# Check if script to run was provided
if [[ -z "$SCRIPT_TO_RUN" ]]; then
  echo "❌ Error: Missing script parameter."
  echo "Usage: ./run-on-all-repos.sh script_to_run.sh [--auto-respond] [--parent-dir]"
  exit 1
fi

# Check if the script exists
if [[ ! -f "$SCRIPT_TO_RUN" ]]; then
  echo "❌ Error: $SCRIPT_TO_RUN does not exist."
  exit 1
fi

# Check if the script is executable, if not make it executable
if [[ ! -x "$SCRIPT_TO_RUN" ]]; then
  echo "⚠️ Warning: $SCRIPT_TO_RUN is not executable."
  echo "🔧 Making script executable..."
  chmod +x "$SCRIPT_TO_RUN"
  
  # Verify chmod worked
  if [[ ! -x "$SCRIPT_TO_RUN" ]]; then
    echo "❌ Error: Failed to make script executable. Check permissions."
    exit 1
  else
    echo "✅ Script is now executable."
  fi
fi

# Get the absolute path of the script
SCRIPT_ABSOLUTE_PATH=$(realpath "$SCRIPT_TO_RUN")

# Create a temporary directory for saved responses
TEMP_DIR=$(mktemp -d)
RESPONSES_FILE="$TEMP_DIR/saved_responses.txt"
touch "$RESPONSES_FILE"

# Function to handle input with auto-response capability
auto_input() {
  local prompt="$1"
  local default_value="$2"
  local response=""
  
  # Check if we have a saved response for this prompt
  local saved_response=$(grep -F "PROMPT:$prompt:" "$RESPONSES_FILE" | head -n 1 | cut -d':' -f3-)
  
  if [[ -n "$saved_response" ]]; then
    # Use saved response
    echo "🔄 Using saved response for: $prompt"
    echo "$saved_response"
    return 0
  fi
  
  # If no saved response, prompt the user
  echo -n "$prompt "
  if [[ -n "$default_value" ]]; then
    echo -n "[$default_value] "
  fi
  read response
  
  # Use default if empty response
  if [[ -z "$response" && -n "$default_value" ]]; then
    response="$default_value"
  fi
  
  # Ask if this response should be saved for future prompts
  if [[ "$AUTO_RESPOND" == true ]]; then
    # Auto-save response when --auto-respond is specified
    echo "PROMPT:$prompt:$response" >> "$RESPONSES_FILE"
    echo "🔄 Saved response for future prompts."
  else
    echo -n "💾 Save this response for similar prompts in other repositories? (y/n) "
    local save_choice
    read save_choice
    
    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
      echo "PROMPT:$prompt:$response" >> "$RESPONSES_FILE"
      echo "🔄 Response saved for future prompts."
    fi
  fi
  
  echo "$response"
  return 0
}

# Create log directory if it doesn't exist
LOG_DIR="$HOME/repo_scripts_logs"
mkdir -p "$LOG_DIR"

# Create log file with timestamp
LOG_FILE="$LOG_DIR/repo_script_$(date +%Y%m%d_%H%M%S).log"
touch "$LOG_FILE"

echo "📋 Starting script execution on all repositories at $(date)" | tee -a "$LOG_FILE"
echo "🔄 Running: $SCRIPT_ABSOLUTE_PATH" | tee -a "$LOG_FILE"
echo "📝 Logging to: $LOG_FILE" | tee -a "$LOG_FILE"
echo "------------------------------------------------" | tee -a "$LOG_FILE"

# Set the target directory (current or parent)
TARGET_DIR="."
if [[ "$PARENT_DIR" == true ]]; then
  TARGET_DIR=".."
  echo "🔍 Looking for repositories in parent directory" | tee -a "$LOG_FILE"
else
  echo "🔍 Looking for repositories in current directory" | tee -a "$LOG_FILE"
fi

# Counter for tracking progress
TOTAL_DIRS=0
PROCESSED_DIRS=0
SUCCESS_DIRS=0
FAILED_DIRS=0

# Count total first-level directories
for dir in "$TARGET_DIR"/*/; do
  if [[ -d "$dir" ]]; then
    ((TOTAL_DIRS++))
  fi
done

# Run the script on each first-level directory
for dir in "$TARGET_DIR"/*/; do
  if [[ -d "$dir" ]]; then
    dir=${dir%/}  # Remove trailing slash
    ((PROCESSED_DIRS++))
    
    echo "" | tee -a "$LOG_FILE"
    echo "🔍 Processing ($PROCESSED_DIRS/$TOTAL_DIRS): $dir" | tee -a "$LOG_FILE"
    echo "------------------------------------------------" | tee -a "$LOG_FILE"
    
    # Check if it's a git repository
    if [[ -d "$dir/.git" ]]; then
      echo "✅ $dir is a git repository" | tee -a "$LOG_FILE"
      
      # Enter the directory and run the script with input handling
      (
        echo "📂 Entering directory: $dir" | tee -a "$LOG_FILE"
        cd "$dir" || exit 1
        
        echo "🚀 Running script in $dir..." | tee -a "$LOG_FILE"
        
        # Check if the script has any read commands
        if grep -q "read" "$SCRIPT_ABSOLUTE_PATH"; then
          echo "ℹ️  Script may require input. Input will be captured for potential reuse." | tee -a "$LOG_FILE"
          
          # Process the script with the input handler
          WRAPPER_SCRIPT="$TEMP_DIR/wrapped_script.sh"
          
          # Create a simplified wrapper that uses expect to handle the script
          cat > "$WRAPPER_SCRIPT" <<EOF
#!/bin/zsh
# Automatically generated wrapper script for input handling

# Import the auto_input function
$(declare -f auto_input)

# Define saved responses file
RESPONSES_FILE="$RESPONSES_FILE"

# Export functions and variables to make them available to the script
export -f auto_input
export RESPONSES_FILE

# Run the script with potential input handling
"$SCRIPT_ABSOLUTE_PATH"
EOF
          
          chmod +x "$WRAPPER_SCRIPT"
          
          # Run the wrapper script
          "$WRAPPER_SCRIPT" 2>&1 | tee -a "$LOG_FILE"
        else
          # Run normally if no read commands are found
          "$SCRIPT_ABSOLUTE_PATH" 2>&1 | tee -a "$LOG_FILE"
        fi
        
        SCRIPT_EXIT_CODE=${PIPESTATUS[0]}
        if [[ $SCRIPT_EXIT_CODE -eq 0 ]]; then
          echo "✨ Script execution successful in $dir" | tee -a "$LOG_FILE"
          ((SUCCESS_DIRS++))
        else
          echo "❌ Script execution failed in $dir (Exit code: $SCRIPT_EXIT_CODE)" | tee -a "$LOG_FILE"
          ((FAILED_DIRS++))
        fi
      )
    else
      echo "⚠️  Skipping $dir - not a git repository" | tee -a "$LOG_FILE"
    fi
    
    echo "------------------------------------------------" | tee -a "$LOG_FILE"
  fi
done

# Summary
echo "" | tee -a "$LOG_FILE"
echo "📊 Summary:" | tee -a "$LOG_FILE"
echo "   🔢 Total repositories found: $TOTAL_DIRS" | tee -a "$LOG_FILE"
echo "   ✅ Successfully processed: $SUCCESS_DIRS" | tee -a "$LOG_FILE"
echo "   ❌ Failed: $FAILED_DIRS" | tee -a "$LOG_FILE"
echo "   ⚠️  Skipped: $((TOTAL_DIRS - SUCCESS_DIRS - FAILED_DIRS))" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "📝 Log file saved to: $LOG_FILE" | tee -a "$LOG_FILE"
echo "✨ All done at $(date)!" | tee -a "$LOG_FILE"

# Clean up
rm -rf "$TEMP_DIR"
