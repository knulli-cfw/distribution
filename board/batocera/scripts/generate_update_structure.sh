#!/bin/bash
set -e 

BASEPATH="/opt/edata/knulli/distribution/"

# Base paths
SOURCE_BASE="${BASEPATH}/board/batocera/allwinner/h700"
OUTPUT_BASE="${BASEPATH}/output/h700/updates/partitions"

# List of board folders
BOARDS=(
    "rg28xx"
    "rg34xx"
    "rg34xx-sp"
    "rg35xx-h"
    "rg35xx-plus"
    "rg35xx-pro"
    "rg35xx-sp"
    "rg40xx-h"
    "rg40xx-v"
    "rg-cubexx"
)

echo "Starting partition copy process..."

# Process each board
for board in "${BOARDS[@]}"; do
    SOURCE_DIR="${SOURCE_BASE}/${board}/partitions"
    DEST_DIR="${OUTPUT_BASE}/${board}/alpha"
    
    echo "Processing board: ${board}"
    
    # Check if source partition directory exists
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "  Warning: Source directory not found: $SOURCE_DIR"
        continue
    fi
    
    # Check if source directory has any files
    if [ -z "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]; then
        echo "  Warning: Source directory is empty: $SOURCE_DIR"
        continue
    fi
    
    # Create destination directory if it doesn't exist
    echo "  Creating destination: $DEST_DIR"
    mkdir -p "$DEST_DIR"
    
    # Copy all contents from source partitions folder to destination
    echo "  Copying files from $SOURCE_DIR to $DEST_DIR"
    cp -r "$SOURCE_DIR"/* "$DEST_DIR/" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Successfully copied partition files for ${board}"
        # Show what was copied
        file_count=$(find "$DEST_DIR" -type f | wc -l)
        echo "    Files copied: $file_count"
    else
        echo "  ✗ Failed to copy files for ${board}"
    fi
    
    echo ""
done

echo "Partition copy process completed!"
echo ""
echo "Output structure created under: ${OUTPUT_BASE}/"

