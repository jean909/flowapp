#!/usr/bin/env python3
"""Check which exercises are missing images"""

from supabase import create_client

SUPABASE_URL = "https://zoaeypxhumpllhpasgun.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpvYWV5cHhodW1wbGxocGFzZ3VuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTg2OTQ0MywiZXhwIjoyMDcxNDQ1NDQzfQ.YvUorZECgeLNGahHNfe4JfA1QODP3t5s1SEsebpxnR4"

client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Get all exercises
exercises = client.table("exercises").select("id, name_en, image_url, video_url").order("name_en").execute()

missing = []
for ex in exercises.data:
    img_url = ex.get("image_url") or ex.get("video_url", "")
    has_img = "exercise_images" in str(img_url) if img_url else False
    if not has_img:
        missing.append(ex)

print(f"Exercises missing images: {len(missing)}")
print("\nFirst 20 missing exercises:")
for i, ex in enumerate(missing[:20], 1):
    print(f"  {i}. {ex['name_en']} (ID: {ex['id'][:8]}...)")

