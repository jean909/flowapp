# Exercise Images Generation Setup

This guide explains how to generate images for all exercises using Replicate's Nano Banana Pro model.

## Prerequisites

1. **Python 3.8+** installed
2. **Supabase Storage Bucket** created
3. **Replicate API Token** (already configured in script)

## Setup Steps

### 1. Install Python Dependencies

```bash
pip install -r requirements_exercise_images.txt
```

Or install individually:
```bash
pip install replicate supabase pillow requests
```

### 2. Create Supabase Storage Bucket

1. Go to **Supabase Dashboard** → **Storage**
2. Click **New Bucket**
3. Name: `exercise_images`
4. Make it **Public** (for public read access)
5. Click **Create Bucket**

### 3. Update Exercises Table (Optional)

If you want a separate `image_url` column instead of using `video_url`:

```sql
ALTER TABLE public.exercises 
ADD COLUMN IF NOT EXISTS image_url TEXT;
```

Or use the existing `video_url` field (script uses this by default).

### 4. Run the Script

#### Generate images for all exercises:
```bash
python generate_exercise_images.py
```

#### Generate images for first 5 exercises (testing):
```bash
python generate_exercise_images.py --limit 5
```

#### Resume from exercise 10:
```bash
python generate_exercise_images.py --start-from 10
```

#### Generate 20 exercises starting from index 50:
```bash
python generate_exercise_images.py --limit 20 --start-from 50
```

## How It Works

1. **Fetches all exercises** from Supabase `exercises` table
2. **Generates prompt** for each exercise based on:
   - Exercise name (EN/DE)
   - Muscle group
   - Equipment needed
   - Difficulty level
   - Instructions
3. **Calls Replicate API** with Nano Banana Pro model
   - Resolution: 1K (HD)
   - Aspect ratio: 1:1 (square)
   - Format: JPG
4. **Downloads** the generated image
5. **Compresses** the image:
   - Resizes if larger than 1920px
   - JPEG quality: 85%
   - Optimizes file size
6. **Uploads** to Supabase Storage bucket `exercise_images`
7. **Updates** exercise record with image URL

## Configuration

Edit these constants in `generate_exercise_images.py`:

```python
REPLICATE_API_TOKEN = "your_token"  # Already set
SUPABASE_URL = "your_url"           # Already set
SUPABASE_KEY = "your_key"           # Already set
STORAGE_BUCKET = "exercise_images"  # Change if different
MAX_IMAGE_SIZE = 1920               # HD max dimension
JPEG_QUALITY = 85                   # Compression quality (1-100)
DELAY_BETWEEN_REQUESTS = 2          # Seconds between API calls
```

## Expected Output

```
============================================================
Exercise Image Generator
============================================================

✓ Initialized Exercise Image Generator
  - Supabase URL: https://zoaeypxhumpllhpasgun.supabase.co
  - Model: google/nano-banana-pro
  - Storage Bucket: exercise_images

Fetching exercises from database...
✓ Found 100 exercises

Processing 100 exercises...

[1/100] Processing: Push-ups
  ID: abc123...
  Generating image...
  Resized from 2048x2048 to 1920x1920
  Compressed: 450KB → 180KB (60.0% reduction)
  Uploading to Supabase Storage...
  ✓ Uploaded: Push-ups_abc12345.jpg
  ✓ Updated exercise record
  ✓ Successfully processed Push-ups
  Waiting 2s before next exercise...

[2/100] Processing: Squats
  ...
```

## Troubleshooting

### Error: "Bucket not found"
- Create the `exercise_images` bucket in Supabase Dashboard
- Make sure it's public for read access

### Error: "Failed to create prediction"
- Check Replicate API token is valid
- Check you have credits in your Replicate account
- Try increasing `DELAY_BETWEEN_REQUESTS` to avoid rate limits

### Error: "Missing required package"
- Run: `pip install -r requirements_exercise_images.txt`

### Images not showing in app
- Check the `video_url` (or `image_url`) field is populated
- Verify storage bucket is public
- Check image URLs are accessible

### Rate Limiting
- Increase `DELAY_BETWEEN_REQUESTS` to 5-10 seconds
- Process in smaller batches using `--limit`

## Cost Estimation

- **Replicate Nano Banana Pro**: ~$0.01-0.02 per image
- **100 exercises**: ~$1-2 total
- **Supabase Storage**: Free tier includes 1GB

## Notes

- Script skips exercises that already have images (checks if URL contains "exercise_images")
- Images are compressed to reduce storage and bandwidth
- Square format (1:1) works best for exercise thumbnails
- Script includes error handling and progress tracking
- Can be interrupted (Ctrl+C) and resumed with `--start-from`

## Next Steps

After generating images:
1. Verify images in Supabase Storage
2. Check exercise records have image URLs
3. Update app UI to display exercise images
4. Consider adding image caching for better performance

