#!/bin/bash

# Firmware Signature Generator
# This script generates MD5 signatures for firmware components during build


# BOARD_DIR = board specific dir
# BINARIES_DIR = images dir 
# BATOCERA_BINARIES_DIR = batocera binaries sub directory

BOARD_DIR=$1
BINARIES_DIR=$2
ARCH_DIR=$(basename "$(dirname "$BINARIES_DIR")")

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIRMWARE_DIR="${BOARD_DIR}" 
SIGNATURE_FILE="${BINARIES_DIR}/firmware.sig"

log_info() {
    echo -e "[INFO] $1"
}

log_warn() {
    echo -e "[WARN] $1"
}

log_error() {
    echo -e "[ERROR] $1"
}

# Function to calculate MD5 of a file
calculate_md5() {
    local file="$1"
    if [[ -f "$file" ]]; then
        md5sum "$file" | cut -d' ' -f1
    else
        echo "MISSING"
    fi
}

# Function to get file size
get_file_size() {
    local file="$1"
    if [[ -f "$file" ]]; then
        stat -c%s "$file"
    else
        echo "0"
    fi
}

# Main signature generation function
generate_signature() {
    log_info "Generating firmware signature..."
    
    # Create temporary directory for boot partition extraction
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    VERSION=$(cat "${BINARIES_DIR}/../target/usr/share/batocera/batocera.version")

    # Start signature file
    cat > "$SIGNATURE_FILE" << EOF
# Firmware Signature File
# Generated on: $(date)

[metadata]
version="$VERSION"
board=$(basename "$BOARD_DIR")
timestamp=$(date +%s)
build_date=$(date -Iseconds)

[partitions]
EOF

    # Calculate signatures for partition files (valid for h700 and a133 boards)
    local partition_files=(
        "${FIRMWARE_DIR}/partitions/boot0.img"
        "${FIRMWARE_DIR}/partitions/boot_package.fex"
        "${FIRMWARE_DIR}/partitions/boot.img"
        "${FIRMWARE_DIR}/partitions/env.img"
        "${BINARIES_DIR}/rootfs.squashfs"
    )

    for file in "${partition_files[@]}"; do
        local md5=$(calculate_md5 "$file")
        local size=$(get_file_size "$file")
        local basename=$(basename "$file")
        
        echo "${basename}_md5=$md5" >> "$SIGNATURE_FILE"
        echo "${basename}_size=$size" >> "$SIGNATURE_FILE"
        
        if [[ "$md5" == "MISSING" ]]; then
            log_warn "File missing: $file"
        else
            log_info "Signed: $file (MD5: ${md5:0:8}..., Size: $size bytes)"
        fi
    done
    
    log_info "Firmware signature generated: $SIGNATURE_FILE"
}

# Check if signature file exists
if [[ -f "$SIGNATURE_FILE" ]]; then
    rm "$SIGNATURE_FILE" 
fi

# Run signature generation
generate_signature

log_info "Signature generation complete!"

exit 0
