# App Images Directory

This directory contains all interactive images for the Eduktok language learning app.

## Structure

Images are organized by unit and lesson:
```
app-images/
├── unit-01/
│   ├── lesson-01/
│   │   ├── image-01.png
│   │   ├── image-02.png
│   │   └── ...
│   ├── lesson-02/
│   └── ...
├── unit-02/
└── ...
```

## Guidelines

1. **Naming Convention**: Use descriptive names that match the lesson content
   - Format: `{concept}-{variation}.png`
   - Example: `apple-red.png`, `car-blue.png`

2. **Image Requirements**:
   - Format: PNG or JPG
   - Recommended size: 1024x1024px for main images
   - Keep file sizes optimized (< 500KB when possible)
   - Use transparent backgrounds for PNG images when appropriate

3. **Content Guidelines**:
   - Images must clearly represent the text/concept they illustrate
   - Use consistent style across all images
   - Ensure cultural sensitivity and inclusivity
   - Avoid copyrighted or licensed content

4. **Workflow**:
   - Create images and place them in appropriate unit/lesson folders
   - Upload to Cloudflare R2 bucket using the deployment script
   - Update lesson data with R2 URLs
   - Test images in app before deploying to production

## Cloudflare R2 Upload

Images will be uploaded to Cloudflare R2 bucket for CDN delivery:
- Bucket name: eduktok-assets
- Base URL: https://assets.eduktok.com/
- Path structure mirrors this directory

## Notes

- This folder is tracked in git for version control
- Original high-quality images should be kept here
- Optimized versions will be created during upload to R2
