#!/usr/bin/env python3
"""Quick script to check exercise images status"""

from supabase import create_client

SUPABASE_URL = "https://zoaeypxhumpllhpasgun.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvYWV5cHhodW1wbGxocGFzZ3VuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTg2OTQ0MywiZXhwIjoyMDcxNDQ1NDQzfQ.YvUorZECgeLNGahHNfe4JfA1QODP3t5s1SEsebpxnR4"

client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Check exercises
print("Checking exercises...")
exercises = client.table("exercises").select("id, name_en, image_url, video_url").execute()
total = len(exercises.data)
with_images = sum(1 for e in exercises.data if e.get("image_url") or (e.get("video_url") and "exercise_images" in str(e.get("video_url", ""))))
print(f"Total exercises: {total}")
print(f"Exercises with images: {with_images}")
print(f"Exercises without images: {total - with_images}")

# Check storage bucket
print("\nChecking storage bucket...")
try:
    files = client.storage.from_("exercise_images").list()
    print(f"Files in bucket: {len(files)}")
    if len(files) > 0:
        print("First 10 files:")
        for f in files[:10]:
            print(f"  - {f.get('name', 'unknown')}")
except Exception as e:
    print(f"Error checking bucket: {e}")

# Show some exercises
print("\nSample exercises:")
for ex in exercises.data[:5]:
    img_url = ex.get("image_url") or ex.get("video_url", "")
    has_img = "exercise_images" in str(img_url) if img_url else False
    status = "[HAS IMAGE]" if has_img else "[NO IMAGE]"
    print(f"  {status} {ex['name_en']}")

