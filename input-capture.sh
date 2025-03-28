#!/bin/zsh

# This script creates a custom version of run-on-all-repos.sh that handles input capture
# It modifies the script execution environment to capture and save user inputs

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
RESPONSES_FILE="$TEMP_DIR/responses.txt"
touch "$RESPONSES_FILE"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}      Input Capture for run-on-all-repos.sh      ${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Get script to run
echo -e "${YELLOW}Enter the script you want to run:${NC}"
read SCRIPT_TO_RUN

if [[ ! -f "$SCRIPT_TO_RUN" ]]; then
  echo -e "${RED}Error: Script $SCRIPT_TO_RUN does not exist${NC}"
  exit 1
fi

# Make script executable if it's not
if [[ ! -x "$SCRIPT_TO_RUN" ]]; then
  chmod +x "$SCRIPT_TO_RUN"
  echo -e "${GREEN}Made script executable${NC}"
fi

# Function to handle standard input and save responses
capture_input() {
  local prompt="$1"
  local response=""
  
  # Check if we have this prompt saved already
  if grep -q "PROMPT:$prompt:" "$RESPONSES_FILE"; then
    response=$(grep "PROMPT:$prompt:" "$RESPONSES_FILE" | head -1 | cut -d':' -f3-)
    echo -e "${BLUE}Using saved response for '$prompt': $response${NC}"
    echo "$response"
    return
  fi
  
  # Otherwise, get input from user
  echo -e "${YELLOW}$prompt${NC}"
  read response
  
  # Ask if they want to save this response
  echo -e "${YELLOW}Save this response for future occurrences? (y/n)${NC}"
  read save_choice
  
  if [[ "$save_choice" == "y" || "$save_choice" == "Y" ]]; then
    echo "PROMPT:$prompt:$response" >> "$RESPONSES_FILE"
    echo -e "${GREEN}Response saved${NC}"
  fi
  
  echo "$response"
}

# Create a wrapper script that will run the original script with input capture
WRAPPER_SCRIPT="$TEMP_DIR/wrapper.sh"
cat > "$WRAPPER_SCRIPT" <<EOF
#!/bin/zsh

# Script wrapper with input capture functionality
# This runs your script but intercepts read commands to capture responses

# Original script
SCRIPT="$SCRIPT_TO_RUN"
RESPONSES_FILE="$RESPONSES_FILE"

# Override read to capture inputs
read() {
  local prompt="\$1"
  local var_name="\$2"
  
  # Extract just the prompt text
  prompt=\${prompt%\?}
  
  # Get response with potential saving
  response=\$(capture_input "\$prompt")
  
  # Set the variable
  eval "\$var_name=\$response"
}

# Source the original script
. "\$SCRIPT"
EOF

chmod +x "$WRAPPER_SCRIPT"

# Run the wrapper script on all repos
echo -e "${GREEN}Running script on all repos with input capture...${NC}"
echo ""

# Find all directories
for dir in */; do
  if [[ -d "$dir" && -d "$dir/.git" ]]; then
    echo -e "${BLUE}Processing $dir...${NC}"
    
    # Change to the directory
    cd "$dir"
    
    # Run the wrapped script
    "$WRAPPER_SCRIPT"
    
    # Return to original directory
    cd ..
    
    echo -e "${GREEN}Completed $dir${NC}"
    echo ""
  fi
done

# Cleanup
rm -rf "$TEMP_DIR"

echo -e "${GREEN}All repositories processed!${NC}"
