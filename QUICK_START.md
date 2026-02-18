# 🚀 Quick Start Guide - Eduktok Content Creation

This guide will help you quickly start creating content for Eduktok's next version.

---

## 📋 Prerequisites

### 1. Tools Installation

```bash
# Install Wrangler CLI (for Cloudflare R2)
npm install -g wrangler

# Install Firebase CLI (for database import)
npm install -g firebase-tools

# Verify installations
wrangler --version
firebase --version
python3 --version  # Should be 3.6+
```

### 2. Authentication

```bash
# Authenticate with Cloudflare
wrangler login

# Authenticate with Firebase
firebase login

# Verify
wrangler whoami
firebase projects:list
```

### 3. Cloudflare R2 Setup

```bash
# Create R2 bucket (first time only)
wrangler r2 bucket create eduktok-assets

# Verify bucket exists
wrangler r2 bucket list
```

---

## 🎨 Creating Your First Unit

### Step 1: Plan Your Unit

Review the content structure:
```bash
cat CONTENT_STRUCTURE.md  # See all 30 units outline
cat examples/unit-01-detailed.md  # See detailed example
```

Choose a unit and plan:
- Unit theme (e.g., "Basic Colors", "Numbers", "Family")
- 15 lessons breakdown
- Mix of lesson types: ~7 Listening, ~6 Speaking, ~2 ListeningFour
- Required vocabulary and images

### Step 2: Generate Lesson Structure

Edit `scripts/generate-content.py` with your unit data:

```python
UNIT_TEMPLATE = {
    "unit": 1,
    "title": {
        "en": "Your Unit Title",
        "es": "Título en Español"
    },
    "lessons": [
        {
            "lesson_number": 1,
            "type": "Listening",
            "topic": "Your Topic",
            "items": [
                {
                    "question": {"en": "Question?", "es": "¿Pregunta?"},
                    "image_file": "image-name.png",
                    "answers": [
                        {
                            "text": {"en": "Answer", "es": "Respuesta"},
                            "image_file": "answer-image.png",
                            "is_correct": True
                        }
                    ]
                }
            ]
        }
    ]
}
```

Run the generator:
```bash
./scripts/generate-content.py
```

Output will be in `content-output/` directory.

### Step 3: Create Images

Create images according to your lesson plan:

**Directory Structure**:
```
app-images/
└── unit-01/
    ├── unit-cover.png (main unit image)
    ├── lesson-01/
    │   ├── apple-red.png
    │   ├── car-red.png
    │   └── color-red.png
    ├── lesson-02/
    │   ├── red-apple-closeup.png
    │   └── red-car.png
    └── lesson-03/
        └── ...
```

**Image Guidelines**:
- Format: PNG (with transparency) or JPG
- Size: 1024x1024px (recommended)
- Quality: High, but optimized (< 500KB if possible)
- Style: Consistent across all images
- Content: Must EXACTLY match the lesson text

**Image Naming**:
- Use descriptive, lowercase names
- Separate words with hyphens
- Include color/concept: `apple-red.png`, `car-blue.png`
- Be consistent: if you use `apple-red.png`, use `apple-green.png` not `green-apple.png`

**Tools for Creating Images**:
- AI generation: Midjourney, DALL-E, Stable Diffusion
- Stock photos: Unsplash, Pexels (check licenses)
- Graphic design: Canva, Figma, Adobe Illustrator
- Photo editing: Photoshop, GIMP, Photopea

### Step 4: Upload Images to R2

Once images are ready:

```bash
# Upload all images from app-images directory
./scripts/upload-to-r2.sh
```

This will:
- Find all image files
- Upload to Cloudflare R2
- Maintain directory structure
- Provide upload summary

**Verify Upload**:
Images should be accessible at:
```
https://assets.eduktok.com/images/unit-01/lesson-01/apple-red.png
```

### Step 5: Update JSON with Image URLs

The generated JSON already includes correct R2 URLs following pattern:
```
https://assets.eduktok.com/images/unit-XX/lesson-YY/image-name.png
```

**Verify** that:
- Image file names in JSON match actual uploaded files
- URLs are correctly formatted
- All required images are referenced

### Step 6: Import to Firebase

```bash
cd content-output

# Import units
firebase firestore:import . \
  --collection unitsNew \
  --project your-project-id

# Import lessons
firebase firestore:import . \
  --collection lessonsNew \
  --project your-project-id
```

**Alternative**: Use Firebase Console
1. Go to Firebase Console → Firestore
2. Select collection (`unitsNew` or `lessonsNew`)
3. Click "Import"
4. Upload JSON files

### Step 7: Test in App

1. Open Eduktok project in Xcode
2. Run app on simulator or device
3. Navigate to your new unit
4. Test each lesson:
   - Images load correctly ✓
   - Text matches images ✓
   - Audio works (if applicable) ✓
   - Answer validation correct ✓
   - No crashes or errors ✓

### Step 8: Iterate

Based on testing:
- Fix any mismatched images
- Adjust lesson difficulty if needed
- Re-upload modified images
- Update Firebase documents
- Retest

---

## 📊 Production Workflow (Batch Creation)

For creating all 30 units efficiently:

### Week 1-2: Planning & Asset Creation
- Plan all 30 units (use CONTENT_STRUCTURE.md)
- Create master spreadsheet with all vocabulary
- Identify required images (estimate: ~1,350 images)
- Source/create images in batches

### Week 3-4: Image Preparation
- Organize images in app-images/ folder
- Optimize for size and quality
- Ensure consistent style
- Review image-text coherence

### Week 5: Upload & Configuration
- Batch upload all images to R2
- Generate JSON for all units
- Update all JSON with verified R2 URLs
- Prepare Firebase import

### Week 6: Import & Testing
- Import all units to Firebase
- Comprehensive testing
- Fix any issues
- User testing with sample group

### Week 7: Refinement
- Iterate based on feedback
- Final quality assurance
- Prepare for App Store submission

---

## 🛠 Common Tasks

### Add New Lesson to Existing Unit

1. Determine lesson number
2. Create images in `app-images/unit-XX/lesson-YY/`
3. Upload: `./scripts/upload-to-r2.sh`
4. Generate JSON or manually create
5. Import to Firebase
6. Test

### Replace an Image

1. Update image in `app-images/unit-XX/lesson-YY/`
2. Re-upload: `./scripts/upload-to-r2.sh`
3. R2 will overwrite old image (same URL)
4. No Firebase update needed
5. Clear app cache and test

### Add Audio File

1. Record audio in required languages
2. Upload to R2 (similar to images)
3. Update lesson JSON `audioUrlDict`:
```json
"audioUrlDict": {
  "en": {
    "question": "https://assets.eduktok.com/audio/unit-01/lesson-01/question-en.mp3"
  },
  "es": {
    "question": "https://assets.eduktok.com/audio/unit-01/lesson-01/question-es.mp3"
  }
}
```
4. Update Firebase document
5. Test audio playback

### Fix Incorrect Answer

1. Update JSON in `content-output/`
2. Modify `isCorrect` field
3. Re-import to Firebase (will overwrite)
4. Test in app

---

## 🐛 Troubleshooting

### Images Not Loading

**Problem**: Images return 404 or don't display  
**Solutions**:
- Verify image uploaded to R2: `wrangler r2 object list eduktok-assets`
- Check URL matches exactly (case-sensitive)
- Verify R2 bucket is public or has correct CORS
- Clear app cache: Delete app → Reinstall

### Upload Script Fails

**Problem**: `wrangler r2 object put` fails  
**Solutions**:
- Re-authenticate: `wrangler login`
- Check bucket exists: `wrangler r2 bucket list`
- Verify file path is correct
- Check network connection
- Try uploading single file manually to test

### Firebase Import Errors

**Problem**: JSON import fails or shows errors  
**Solutions**:
- Validate JSON syntax: `python3 -m json.tool file.json`
- Check field types match Firestore schema
- Verify you have write permissions
- Try importing smaller batch
- Check Firebase quotas

### App Crashes on Lesson Load

**Problem**: App crashes when opening specific lesson  
**Solutions**:
- Check Xcode console for error messages
- Verify lesson JSON structure matches model
- Test with breakpoints in LessonViewModel
- Check for nil values in required fields
- Verify image URLs are valid

---

## 📚 Key Documents Reference

- **[claude.md](claude.md)** - Complete project context and architecture
- **[CONTENT_STRUCTURE.md](CONTENT_STRUCTURE.md)** - All 30 units outline
- **[examples/unit-01-detailed.md](examples/unit-01-detailed.md)** - Detailed example unit
- **[app-images/README.md](app-images/README.md)** - Image guidelines
- **[scripts/README.md](scripts/README.md)** - Script documentation

---

## ✅ Quality Checklist

Before marking a unit as complete:

- [ ] All 15 lessons created
- [ ] Lesson type distribution correct (~7 Listening, ~6 Speaking, ~2 ListeningFour)
- [ ] All images created and uploaded
- [ ] Images match text descriptions exactly
- [ ] Images are high quality and consistent style
- [ ] JSON structure valid and complete
- [ ] Imported to Firebase successfully
- [ ] All lessons tested in app
- [ ] No crashes or errors
- [ ] Audio files included (if applicable)
- [ ] Multilingual text provided (en, es minimum)
- [ ] Progression makes sense (easy → harder)
- [ ] User tested with sample audience

---

## 🎯 Success Metrics

Track your progress:

**Content Creation**:
- Units completed: __ / 30
- Lessons completed: __ / 450
- Images created: __ / ~1,350

**Quality**:
- Image-text coherence: 100% ✓
- No broken images: 100% ✓
- No crashes: 100% ✓
- User satisfaction: > 80% ✓

**Performance**:
- Image load time: < 2 seconds
- Lesson load time: < 1 second
- App size: < 100MB

---

## 🚀 Next Steps

1. **Start Small**: Create Unit 1 completely (use examples/unit-01-detailed.md)
2. **Test Thoroughly**: Ensure everything works before scaling
3. **Optimize Workflow**: Find most efficient tools and processes
4. **Batch Production**: Once workflow is solid, create remaining 29 units
5. **Iterate**: Continuously improve based on testing and feedback

---

## 💡 Pro Tips

1. **Reuse Assets**: If same image works in multiple lessons, reuse it
2. **Batch Processing**: Create similar images together (all red objects, etc.)
3. **Template**: Create image templates for consistency
4. **Naming Convention**: Stick to one naming pattern throughout
5. **Version Control**: Commit regularly as you complete units
6. **Backup**: Keep original high-res images separate from optimized versions
7. **Documentation**: Document decisions for future reference
8. **User Feedback**: Test with real users early and often

---

**Ready to start? Begin with:**
```bash
# 1. Read the detailed example
cat examples/unit-01-detailed.md

# 2. Plan your first unit
# 3. Generate structure
./scripts/generate-content.py

# 4. Create images
# 5. Upload
./scripts/upload-to-r2.sh

# 6. Import to Firebase
# 7. Test in app
# 8. 🎉 Celebrate!
```

Good luck! 🚀
