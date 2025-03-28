#!/bin/zsh

# Create the destination directory if it doesn't exist
mkdir -p current_files

# Find all files in the current directory and its subdirectories
# and move them to the current_files directory
find . -type f -not -path "./current_files/*" | while read file; do
  # Extract just the filename without the path
  filename=$(basename "$file")
  
  # If a file with the same name already exists in current_files,
  # append a unique identifier to prevent overwriting
  if [[ -f "./current_files/$filename" ]]; then
    # Create a unique name by appending a timestamp and random number
    unique_filename="${filename}_$(date +%s)_$RANDOM"
    mv "$file" "./current_files/$unique_filename"
  else
    mv "$file" "./current_files/$filename"
  fi
done

echo "Files have been moved to current_files directory"
