#!/bin/bash

# Cloudflare R2 Upload Script for Eduktok Images
# This script uploads images from the local app-images directory to Cloudflare R2 bucket

set -e  # Exit on error

# Configuration
BUCKET_NAME="eduktok-assets"
LOCAL_BASE_DIR="./app-images"
R2_BASE_PATH="images"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}Error: wrangler CLI is not installed${NC}"
    echo "Install it with: npm install -g wrangler"
    echo "Then authenticate with: wrangler login"
    exit 1
fi

# Check if local directory exists
if [ ! -d "$LOCAL_BASE_DIR" ]; then
    echo -e "${RED}Error: Directory $LOCAL_BASE_DIR does not exist${NC}"
    exit 1
fi

echo -e "${GREEN}Starting upload to Cloudflare R2...${NC}"
echo "Bucket: $BUCKET_NAME"
echo "Local directory: $LOCAL_BASE_DIR"
echo ""

# Counter for uploaded files
UPLOADED=0
SKIPPED=0
FAILED=0

# Function to upload a file
upload_file() {
    local file="$1"
    local relative_path="${file#$LOCAL_BASE_DIR/}"
    local r2_path="$R2_BASE_PATH/$relative_path"
    
    # Skip README.md and .gitkeep files
    if [[ "$file" == *"README.md" ]] || [[ "$file" == *".gitkeep" ]]; then
        echo -e "${YELLOW}Skipping: $relative_path${NC}"
        ((SKIPPED++))
        return
    fi
    
    # Only process image files
    if [[ "$file" =~ \.(jpg|jpeg|png|gif|webp|svg)$ ]]; then
        echo "Uploading: $relative_path -> $r2_path"
        
        if wrangler r2 object put "$BUCKET_NAME/$r2_path" --file "$file" 2>/dev/null; then
            echo -e "${GREEN}✓ Uploaded: $relative_path${NC}"
            ((UPLOADED++))
        else
            echo -e "${RED}✗ Failed: $relative_path${NC}"
            ((FAILED++))
        fi
    else
        echo -e "${YELLOW}Skipping non-image: $relative_path${NC}"
        ((SKIPPED++))
    fi
}

# Find and upload all image files
while IFS= read -r -d '' file; do
    upload_file "$file"
done < <(find "$LOCAL_BASE_DIR" -type f -print0)

# Summary
echo ""
echo "================================================"
echo -e "${GREEN}Upload Complete!${NC}"
echo "Uploaded: $UPLOADED files"
echo "Skipped: $SKIPPED files"
echo "Failed: $FAILED files"
echo "================================================"

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Some uploads failed. Please check the errors above.${NC}"
    exit 1
fi

echo ""
echo "Your images are now available at:"
echo "https://assets.eduktok.com/$R2_BASE_PATH/{unit-folder}/{lesson-folder}/{image-name}"
echo ""
echo "Example URL format:"
echo "https://assets.eduktok.com/$R2_BASE_PATH/unit-01/lesson-01/apple-red.png"
