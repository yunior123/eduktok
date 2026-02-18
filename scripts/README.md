# Scripts Directory

This directory contains utility scripts for managing Eduktok content and assets.

## Available Scripts

### 1. `upload-to-r2.sh`

Uploads images from the local `app-images` directory to Cloudflare R2 bucket.

**Prerequisites:**
```bash
# Install Wrangler CLI
npm install -g wrangler

# Authenticate with Cloudflare
wrangler login

# Verify configuration
wrangler whoami
```

**Usage:**
```bash
# Upload all images
./scripts/upload-to-r2.sh

# The script will:
# - Check for wrangler installation
# - Find all image files in app-images/
# - Upload them to R2 with preserved directory structure
# - Provide a summary report
```

**Configuration:**
- Bucket name: `eduktok-assets`
- Base path: `images/`
- Supported formats: jpg, jpeg, png, gif, webp, svg

**Output:**
Images will be accessible at:
```
https://assets.eduktok.com/images/unit-XX/lesson-XX/image-name.png
```

---

### 2. `generate-content.py`

Generates JSON structure files for units and lessons to import into Firebase.

**Prerequisites:**
```bash
# Python 3.6+ required
python3 --version

# No additional packages needed (uses standard library)
```

**Usage:**
```bash
# Generate sample content
./scripts/generate-content.py

# Output will be saved to: content-output/
# Files created:
# - unit-XX.json (unit metadata)
# - unit-XX-lesson-YY.json (individual lessons)
```

**Customization:**
Edit the `UNIT_TEMPLATE` in the script to define your unit structure:

```python
UNIT_TEMPLATE = {
    "unit": 1,
    "title": {"en": "Unit Title", "es": "Título de Unidad"},
    "lessons": [
        {
            "lesson_number": 1,
            "type": "Listening",
            "items": [...]
        }
    ]
}
```

**Next Steps After Generation:**
1. Review generated JSON files in `content-output/`
2. Create corresponding images in `app-images/`
3. Upload images: `./scripts/upload-to-r2.sh`
4. Import JSON to Firebase Firestore

---

## Workflow Example

Complete workflow for adding a new unit:

```bash
# 1. Generate unit structure
./scripts/generate-content.py

# 2. Create images based on generated structure
# Manually create/source images and place them in:
# app-images/unit-01/lesson-01/image1.png
# app-images/unit-01/lesson-01/image2.png
# etc.

# 3. Upload images to R2
./scripts/upload-to-r2.sh

# 4. Update JSON files with R2 URLs
# The generated JSON already has the correct URL structure

# 5. Import to Firebase
# Use Firebase Console or Firebase CLI to import JSON files
firebase firestore:import content-output/

# 6. Test in app
# Launch app and verify new content appears correctly
```

---

## Cloudflare R2 Setup

### Initial Setup

1. **Create R2 Bucket:**
```bash
wrangler r2 bucket create eduktok-assets
```

2. **Configure CORS (if needed):**
Create `cors-config.json`:
```json
{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedMethods": ["GET"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3600
    }
  ]
}
```

Apply CORS:
```bash
wrangler r2 bucket cors set eduktok-assets --config cors-config.json
```

3. **Set up Custom Domain (optional):**
```bash
# In Cloudflare dashboard:
# R2 > eduktok-assets > Settings > Custom Domain
# Add: assets.eduktok.com
```

---

## Firebase Import

### Using Firebase CLI

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Import units
firebase firestore:import content-output/ \
  --collection unitsNew \
  --project your-project-id

# Import lessons
firebase firestore:import content-output/ \
  --collection lessonsNew \
  --project your-project-id
```

### Using Firebase Console

1. Go to Firebase Console
2. Select your project
3. Navigate to Firestore Database
4. Use "Import" button
5. Upload JSON files individually or in batch

---

## Troubleshooting

### Upload Script Issues

**Problem:** "wrangler: command not found"
```bash
# Solution: Install wrangler
npm install -g wrangler
```

**Problem:** "Authentication failed"
```bash
# Solution: Re-authenticate
wrangler login
```

**Problem:** "Bucket not found"
```bash
# Solution: Create bucket
wrangler r2 bucket create eduktok-assets
```

### Generate Script Issues

**Problem:** "Permission denied"
```bash
# Solution: Make script executable
chmod +x scripts/generate-content.py
```

**Problem:** Output directory already exists
```bash
# Solution: Remove old output
rm -rf content-output/
./scripts/generate-content.py
```

---

## Future Enhancements

Potential improvements to these scripts:

- [ ] Batch upload optimization (parallel uploads)
- [ ] Image optimization before upload (resize, compress)
- [ ] Automatic URL update in JSON after R2 upload
- [ ] Direct Firebase import from script
- [ ] Validation script to check image-text coherence
- [ ] Bulk content generation from CSV/spreadsheet
- [ ] Progress tracking for large uploads
- [ ] Rollback functionality
- [ ] Content versioning

---

## Support

For issues or questions:
1. Check this README
2. Review [claude.md](../claude.md) for project context
3. See [CONTENT_STRUCTURE.md](../CONTENT_STRUCTURE.md) for content guidelines
4. Check [app-images/README.md](../app-images/README.md) for image requirements

---

**Last Updated**: 2026-02-05
