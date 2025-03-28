#!/bin/zsh

# Helper script for run-on-all-repos.sh to handle script input
# This script is used to process a script and modify read commands to use auto_input

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <script_to_modify> <responses_file>"
  exit 1
fi

SCRIPT_TO_MODIFY=$1
RESPONSES_FILE=$2
OUTPUT_SCRIPT="${SCRIPT_TO_MODIFY}.processed"

# Create auto_input function definition
cat > "$OUTPUT_SCRIPT" <<'EOF'
#!/bin/zsh

# Function for handling input with response saving
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
  echo -n "💾 Save this response for similar prompts in other repositories? (y/n) "
  local save_choice
  read save_choice
  
  if [[ "$save_choice" =~ ^[Yy]$ ]]; then
    echo "PROMPT:$prompt:$response" >> "$RESPONSES_FILE"
    echo "🔄 Response saved for future prompts."
  fi
  
  echo "$response"
  return 0
}

# Set responses file path
RESPONSES_FILE="$RESPONSES_FILE"

EOF

# Process the script, replacing read commands with auto_input
sed -E 's/read\s+"([^"]+)\?(.*)"(.*)/response=$(auto_input "\1" "")\3/g; s/read\s+([^"?]+)(.*)/response=$(auto_input "Enter value:" "")\2/g' "$SCRIPT_TO_MODIFY" >> "$OUTPUT_SCRIPT"

# Make the output script executable
chmod +x "$OUTPUT_SCRIPT"

echo "Script processed. Run as: $OUTPUT_SCRIPT"
