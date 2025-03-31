#!/bin/zsh

# Script to create full backups of git repositories
# Usage: ./git-backup-repo.sh [backup-dir] [--upload]

echo "💾 Starting git repository backup script..."

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
BACKUP_DIR=${1:-"$HOME/git-backups"}
UPLOAD_MODE=false
if [[ "$2" == "--upload" ]]; then
  UPLOAD_MODE=true
  echo "⚠️  UPLOAD MODE ENABLED: Backup will be uploaded after creation"
fi

# Check if backup directory exists and create if needed
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "📁 Backup directory does not exist: $BACKUP_DIR"
  read "create_dir?Create this directory? (y/n): "
  
  if [[ "$create_dir" =~ ^[Yy]$ ]]; then
    mkdir -p "$BACKUP_DIR"
    if [[ $? -eq 0 ]]; then
      echo "✅ Created backup directory: $BACKUP_DIR"
    else
      echo "❌ Error: Failed to create backup directory. Check permissions."
      exit 1
    fi
  else
    echo "❌ Error: $BACKUP_DIR does not exist."
    exit 1
  fi
else
  echo "📁 Backup directory: $BACKUP_DIR"
fi

# Create timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/${REPO_NAME}_${TIMESTAMP}.git.tar.gz"

# Check for existing backups
EXISTING_BACKUPS=$(find "$BACKUP_DIR" -name "${REPO_NAME}_*.git.tar.gz" | wc -l)
if [[ $EXISTING_BACKUPS -gt 0 ]]; then
  echo "ℹ️  Found $EXISTING_BACKUPS existing backups for this repository."
  LATEST_BACKUP=$(find "$BACKUP_DIR" -name "${REPO_NAME}_*.git.tar.gz" | sort | tail -n 1)
  LATEST_DATE=$(basename "$LATEST_BACKUP" | grep -o '[0-9]\{8\}_[0-9]\{6\}')
  echo "   Latest backup: $LATEST_DATE"
  
  # Ask about incremental backup
  echo ""
  echo "Would you like to:"
  echo "   1. Create a full backup (default)"
  echo "   2. Create an incremental backup since last backup"
  read "choice?Choose an option (1/2): "
  
  case $choice in
    2)
      echo "🔄 Creating incremental backup since $LATEST_DATE..."
      INCREMENTAL=true
      INCREMENTAL_FILE="$BACKUP_DIR/${REPO_NAME}_${TIMESTAMP}_incremental.git.patch"
      
      # Extract last backup commit
      echo "📦 Extracting last backup state..."
      TEMP_DIR=$(mktemp -d)
      tar -xzf "$LATEST_BACKUP" -C "$TEMP_DIR"
      
      # Get the latest commit from the previous backup
      cd "$TEMP_DIR"
      LAST_BACKUP_COMMIT=$(git rev-parse HEAD)
      cd "$ROOT_DIR"
      
      # Create patch of changes since last backup
      git format-patch $LAST_BACKUP_COMMIT..HEAD --stdout > "$INCREMENTAL_FILE"
      
      echo "✅ Incremental backup created: $INCREMENTAL_FILE"
      echo "   Size: $(du -h "$INCREMENTAL_FILE" | cut -f1)"
      
      # Clean up
      rm -rf "$TEMP_DIR"
      
      # Set backup file to the incremental file for potential upload
      BACKUP_FILE="$INCREMENTAL_FILE"
      ;;
    *)
      echo "🔄 Creating full backup..."
      INCREMENTAL=false
      ;;
  esac
else
  echo "ℹ️  No existing backups found for this repository. Creating first backup."
  INCREMENTAL=false
fi

if [[ "$INCREMENTAL" == false ]]; then
  # Create a bundle of all branches first
  BUNDLE_FILE="$BACKUP_DIR/${REPO_NAME}_${TIMESTAMP}.bundle"
  echo "📦 Creating bundle of all branches..."
  git bundle create "$BUNDLE_FILE" --all
  
  # Create tar archive of the entire repository
  echo "🔄 Creating compressed archive of the repository..."
  git clone --mirror "$ROOT_DIR" "$BACKUP_DIR/temp_repo.git"
  tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" "temp_repo.git"
  rm -rf "$BACKUP_DIR/temp_repo.git"
  
  # Add repository metadata to the archive
  echo "📝 Adding metadata..."
  METADATA_FILE="$BACKUP_DIR/metadata.txt"
  {
    echo "Repository: $REPO_NAME"
    echo "Backup Date: $(date)"
    echo "Current Branch: $(git branch --show-current)"
    echo "Remote URLs:"
    git remote -v
    echo ""
    echo "Branches:"
    git branch -a
    echo ""
    echo "Tags:"
    git tag
    echo ""
    echo "Last 10 Commits:"
    git log -n 10 --pretty=format:"%h - %an, %ar : %s"
  } > "$METADATA_FILE"
  
  # Append metadata to the archive
  tar -rf "$BACKUP_FILE" -C "$BACKUP_DIR" "metadata.txt"
  rm "$METADATA_FILE"
  
  echo "✅ Full backup created: $BACKUP_FILE"
  echo "   Size: $(du -h "$BACKUP_FILE" | cut -f1)"
  echo "   Bundle: $BUNDLE_FILE"
  echo "   Bundle Size: $(du -h "$BUNDLE_FILE" | cut -f1)"
fi

# Backup retention policy
echo "🧹 Applying backup retention policy..."
echo "   Keeping:"
echo "   - All backups from the last 7 days"
echo "   - Weekly backups for the last month"
echo "   - Monthly backups beyond that"

# Find backups older than 7 days
OLDER_BACKUPS=$(find "$BACKUP_DIR" -name "${REPO_NAME}_*.git.tar.gz" -mtime +7)
DELETED_COUNT=0

for BACKUP in $OLDER_BACKUPS; do
  BACKUP_DATE=$(basename "$BACKUP" | grep -o '[0-9]\{8\}')
  
  # Keep weekly backups for the last month (day of week = 1, Monday)
  if [[ $(date -d "${BACKUP_DATE:0:4}-${BACKUP_DATE:4:2}-${BACKUP_DATE:6:2}" +%u) -eq 1 && $(date -d "${BACKUP_DATE:0:4}-${BACKUP_DATE:4:2}-${BACKUP_DATE:6:2} -30 days" +%s) -lt $(date +%s) ]]; then
    continue
  fi
  
  # Keep monthly backups (1st of the month)
  if [[ "${BACKUP_DATE:6:2}" -eq 01 ]]; then
    continue
  fi
  
  # Delete other old backups
  rm "$BACKUP"
  ((DELETED_COUNT++))
done

echo "   Cleaned up $DELETED_COUNT old backups."

# Upload if requested
if [[ "$UPLOAD_MODE" == true ]]; then
  echo "🌐 Uploading backup to remote storage..."
  
  # Check for different upload methods
  if command -v rclone &> /dev/null; then
    # Ask for rclone remote
    echo "Upload options:"
    echo "   1. Use rclone"
    echo "   2. Use SCP"
    echo "   3. Skip upload"
    read "upload_method?Choose upload method (1/2/3): "
    
    case $upload_method in
      1)
        # List available rclone remotes
        echo "Available rclone remotes:"
        rclone listremotes | nl
        read "remote_num?Choose remote number: "
        REMOTE=$(rclone listremotes | sed -n "${remote_num}p")
        
        if [[ -z "$REMOTE" ]]; then
          echo "❌ Invalid remote selection. Skipping upload."
        else
          REMOTE_PATH="${REMOTE}git-backups/"
          echo "📤 Uploading to $REMOTE_PATH..."
          rclone copy "$BACKUP_FILE" "$REMOTE_PATH"
          
          if [[ "$INCREMENTAL" == false ]]; then
            rclone copy "$BUNDLE_FILE" "$REMOTE_PATH"
          fi
          
          echo "✅ Upload complete."
        fi
        ;;
      2)
        # Use SCP
        read "scp_target?Enter SCP target (user@host:path): "
        
        if [[ -z "$scp_target" ]]; then
          echo "❌ Invalid SCP target. Skipping upload."
        else
          echo "📤 Uploading to $scp_target..."
          scp "$BACKUP_FILE" "$scp_target"
          
          if [[ "$INCREMENTAL" == false ]]; then
            scp "$BUNDLE_FILE" "$scp_target"
          fi
          
          echo "✅ Upload complete."
        fi
        ;;
      *)
        echo "ℹ️  Skipping upload."
        ;;
    esac
  else
    echo "⚠️  rclone not found. Installing or configuring rclone is recommended for cloud uploads."
    echo "   See: https://rclone.org/install/"
    
    # Offer SCP as alternative
    read "use_scp?Use SCP for upload instead? (y/n): "
    
    if [[ "$use_scp" =~ ^[Yy]$ ]]; then
      read "scp_target?Enter SCP target (user@host:path): "
      
      if [[ -z "$scp_target" ]]; then
        echo "❌ Invalid SCP target. Skipping upload."
      else
        echo "📤 Uploading to $scp_target..."
        scp "$BACKUP_FILE" "$scp_target"
        
        if [[ "$INCREMENTAL" == false ]]; then
          scp "$BUNDLE_FILE" "$scp_target"
        fi
        
        echo "✅ Upload complete."
      fi
    else
      echo "ℹ️  Skipping upload."
    fi
  fi
fi

echo "✨ All done!"
echo "📂 Backup location: $BACKUP_FILE"
