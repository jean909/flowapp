#!/usr/bin/env python3
"""
Script to generate exercise images using Replicate Nano Banana Pro
and upload them to Supabase Storage.

Usage:
    python generate_exercise_images.py

Requirements:
    pip install replicate supabase pillow requests
"""

import os
import sys
import time
import json
import requests
from typing import Optional, Dict, Any
from pathlib import Path
from io import BytesIO

try:
    import replicate
    from supabase import create_client, Client
    from PIL import Image
except ImportError as e:
    print(f"Missing required package: {e}")
    print("Install with: pip install replicate supabase pillow requests")
    sys.exit(1)

# Configuration - set env vars or replace placeholders locally (do not commit secrets)
REPLICATE_API_TOKEN = os.environ.get("REPLICATE_API_TOKEN", "")
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://zoaeypxhumpllhpasgun.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")
MODEL_NAME = "google/nano-banana-pro"
STORAGE_BUCKET = "exercise_images"
MAX_IMAGE_SIZE = 1920  # HD max width/height
JPEG_QUALITY = 85
DELAY_BETWEEN_REQUESTS = 2  # seconds to avoid rate limiting


class ExerciseImageGenerator:
    def __init__(self):
        """Initialize the generator with API clients."""
        # Set Replicate API token
        os.environ["REPLICATE_API_TOKEN"] = REPLICATE_API_TOKEN
        
        # Initialize Supabase client
        self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Initialize Replicate client
        self.replicate_client = replicate.Client(api_token=REPLICATE_API_TOKEN)
        
        print("[OK] Initialized Exercise Image Generator")
        print(f"  - Supabase URL: {SUPABASE_URL}")
        print(f"  - Model: {MODEL_NAME}")
        print(f"  - Storage Bucket: {STORAGE_BUCKET}\n")

    def get_all_exercises(self) -> list[Dict[str, Any]]:
        """Fetch all exercises from Supabase."""
        print("Fetching exercises from database...")
        try:
            response = self.supabase.table("exercises").select("*").execute()
            exercises = response.data
            print(f"[OK] Found {len(exercises)} exercises\n")
            return exercises
        except Exception as e:
            print(f"[ERROR] Error fetching exercises: {e}")
            sys.exit(1)

    def generate_prompt_for_exercise(self, exercise: Dict[str, Any]) -> str:
        """Generate a detailed prompt for image generation based on exercise data."""
        name_en = exercise.get("name_en", "")
        name_de = exercise.get("name_de", "")
        muscle_group = exercise.get("muscle_group", "")
        equipment = exercise.get("equipment", "None")
        difficulty = exercise.get("difficulty", "Beginner")
        instructions_en = exercise.get("instructions_en", "")
        
        # Build equipment description
        equipment_desc = ""
        if equipment == "None":
            equipment_desc = "bodyweight exercise, no equipment needed"
        elif equipment == "Dumbbells":
            equipment_desc = "using dumbbells"
        elif equipment == "Pull-up Bar":
            equipment_desc = "using a pull-up bar"
        elif equipment == "Resistance Band":
            equipment_desc = "using a resistance band"
        elif equipment == "Jump Rope":
            equipment_desc = "using a jump rope"
        else:
            equipment_desc = f"using {equipment.lower()}"
        
        # Build prompt
        prompt = f"""Professional fitness exercise illustration: {name_en} ({name_de}).

A clear, detailed, and anatomically accurate illustration showing proper form for the {name_en} exercise. 
This is a {difficulty.lower()} level {muscle_group.lower()} exercise, {equipment_desc}.

Key visual elements:
- Person performing the exercise with correct form and posture
- Clear demonstration of the movement and body positioning
- Professional fitness/gym aesthetic
- Clean, modern illustration style
- Focus on exercise technique and form
- Neutral background, exercise-focused composition

The illustration should be educational and suitable for a fitness app, showing users how to perform this exercise correctly."""

        return prompt

    def generate_image(self, prompt: str, max_retries: int = 3) -> Optional[str]:
        """Generate image using Replicate Nano Banana Pro."""
        for attempt in range(max_retries):
            try:
                if attempt > 0:
                    print(f"  Retry attempt {attempt + 1}/{max_retries}...")
                    time.sleep(5)  # Wait before retry
                else:
                    print(f"  Generating image...")
                
                # Create prediction
                output = self.replicate_client.run(
                    MODEL_NAME,
                    input={
                        "prompt": prompt,
                        "resolution": "1K",  # HD resolution (not 2K or 4K)
                        "aspect_ratio": "1:1",  # Square format for exercise images
                        "output_format": "jpg",
                        "safety_filter_level": "block_only_high",
                        "image_input": [],  # No input images, pure generation
                    }
                )
                
                # Handle different output formats
                # Replicate can return: str, list, or FileOutput object
                if isinstance(output, str):
                    return output
                elif isinstance(output, list):
                    if len(output) > 0:
                        # If list contains FileOutput objects, get URL from first
                        item = output[0]
                        if hasattr(item, 'url'):
                            return item.url
                        elif isinstance(item, str):
                            return item
                elif hasattr(output, 'url'):
                    # FileOutput object has .url attribute
                    return output.url
                elif hasattr(output, '__str__'):
                    # Try to convert to string
                    url_str = str(output)
                    if url_str.startswith('http'):
                        return url_str
                
                print(f"  [ERROR] Unexpected output format: {type(output)}, value: {output}")
                if attempt < max_retries - 1:
                    continue
                return None
                
            except Exception as e:
                print(f"  [ERROR] Error generating image (attempt {attempt + 1}/{max_retries}): {e}")
                if attempt < max_retries - 1:
                    continue
                return None
        
        return None

    def download_image(self, url: str) -> Optional[bytes]:
        """Download image from URL."""
        try:
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            return response.content
        except Exception as e:
            print(f"  [ERROR] Error downloading image: {e}")
            return None

    def compress_image(self, image_data: bytes) -> Optional[bytes]:
        """Compress and resize image to HD quality."""
        try:
            # Open image
            img = Image.open(BytesIO(image_data))
            
            # Convert to RGB if necessary (for JPEG)
            if img.mode in ('RGBA', 'LA', 'P'):
                background = Image.new('RGB', img.size, (255, 255, 255))
                if img.mode == 'P':
                    img = img.convert('RGBA')
                background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                img = background
            
            # Resize if too large (maintain aspect ratio)
            width, height = img.size
            if width > MAX_IMAGE_SIZE or height > MAX_IMAGE_SIZE:
                ratio = min(MAX_IMAGE_SIZE / width, MAX_IMAGE_SIZE / height)
                new_width = int(width * ratio)
                new_height = int(height * ratio)
                img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
                print(f"  Resized from {width}x{height} to {new_width}x{new_height}")
            
            # Compress to JPEG
            output = BytesIO()
            img.save(output, format='JPEG', quality=JPEG_QUALITY, optimize=True)
            compressed_data = output.getvalue()
            
            original_size = len(image_data)
            compressed_size = len(compressed_data)
            compression_ratio = (1 - compressed_size / original_size) * 100
            
            print(f"  Compressed: {original_size // 1024}KB -> {compressed_size // 1024}KB ({compression_ratio:.1f}% reduction)")
            
            return compressed_data
            
        except Exception as e:
            print(f"  [ERROR] Error compressing image: {e}")
            return None

    def upload_to_supabase(self, image_data: bytes, exercise_id: str, exercise_name: str) -> Optional[str]:
        """Upload compressed image to Supabase Storage."""
        try:
            # Sanitize exercise name for filename
            safe_name = "".join(c if c.isalnum() or c in ('-', '_') else '_' for c in exercise_name)
            filename = f"{safe_name}_{exercise_id[:8]}.jpg"
            file_path = f"{filename}"
            
            print(f"  Uploading to Supabase Storage...")
            
            # Upload file (Supabase Python client accepts bytes directly)
            self.supabase.storage.from_(STORAGE_BUCKET).upload(
                file_path,
                image_data,
                file_options={"content-type": "image/jpeg", "upsert": "true"}
            )
            
            # Get public URL
            public_url = self.supabase.storage.from_(STORAGE_BUCKET).get_public_url(file_path)
            
            print(f"  [OK] Uploaded: {filename}")
            return public_url
            
        except Exception as e:
            print(f"  [ERROR] Error uploading to Supabase: {e}")
            # Check if bucket exists
            if "Bucket not found" in str(e) or "does not exist" in str(e):
                print(f"  [WARNING] Storage bucket '{STORAGE_BUCKET}' doesn't exist!")
                print(f"  Create it in Supabase Dashboard → Storage → New Bucket")
                print(f"  Make it public for read access")
            return None

    def update_exercise_image_url(self, exercise_id: str, image_url: str) -> bool:
        """Update exercise record with image URL."""
        try:
            # Try to use image_url column first, fallback to video_url
            update_data = {}
            
            # Check if image_url column exists by trying to update it
            # If it fails, we'll use video_url
            try:
                # Try updating image_url first
                self.supabase.table("exercises").update({
                    "image_url": image_url
                }).eq("id", exercise_id).execute()
                print(f"  [OK] Updated exercise record (image_url)")
                return True
            except Exception:
                # Fallback to video_url if image_url column doesn't exist
                self.supabase.table("exercises").update({
                    "video_url": image_url
                }).eq("id", exercise_id).execute()
                print(f"  [OK] Updated exercise record (video_url)")
                return True
                
        except Exception as e:
            print(f"  [ERROR] Error updating exercise: {e}")
            return False

    def process_exercise(self, exercise: Dict[str, Any], index: int, total: int) -> bool:
        """Process a single exercise: generate, compress, upload, update."""
        exercise_id = exercise.get("id")
        exercise_name = exercise.get("name_en", "Unknown")
        existing_image_url = exercise.get("image_url")
        existing_video_url = exercise.get("video_url")
        
        print(f"\n[{index + 1}/{total}] Processing: {exercise_name}")
        print(f"  ID: {exercise_id}")
        
        # Skip if already has image (check both image_url and video_url)
        existing_url = existing_image_url or existing_video_url
        if existing_url and ("exercise_images" in existing_url or "storage" in existing_url):
            print(f"  [SKIP] Skipping (already has image)")
            return True
        
        # Generate prompt
        prompt = self.generate_prompt_for_exercise(exercise)
        
        # Generate image
        image_url = self.generate_image(prompt)
        if not image_url:
            return False
        
        # Download image
        image_data = self.download_image(image_url)
        if not image_data:
            return False
        
        # Compress image
        compressed_data = self.compress_image(image_data)
        if not compressed_data:
            return False
        
        # Upload to Supabase
        public_url = self.upload_to_supabase(compressed_data, exercise_id, exercise_name)
        if not public_url:
            return False
        
        # Update exercise record
        # Note: We're using video_url field. If you want a separate image_url column,
        # you'll need to add it to the exercises table first
        success = self.update_exercise_image_url(exercise_id, public_url)
        
        if success:
            print(f"  [OK] Successfully processed {exercise_name}")
        else:
            print(f"  [ERROR] Failed to update {exercise_name}")
        
        # Delay to avoid rate limiting
        if index < total - 1:
            print(f"  Waiting {DELAY_BETWEEN_REQUESTS}s before next exercise...")
            time.sleep(DELAY_BETWEEN_REQUESTS)
        
        return success

    def run(self, limit: Optional[int] = None, start_from: int = 0):
        """Main execution method."""
        print("=" * 60)
        print("Exercise Image Generator")
        print("=" * 60)
        print()
        
        # Get all exercises
        exercises = self.get_all_exercises()
        
        if limit:
            exercises = exercises[start_from:start_from + limit]
        else:
            exercises = exercises[start_from:]
        
        total = len(exercises)
        if total == 0:
            print("No exercises to process.")
            return
        
        print(f"Processing {total} exercises...")
        print()
        
        successful = 0
        failed = 0
        
        for i, exercise in enumerate(exercises):
            try:
                if self.process_exercise(exercise, i, total):
                    successful += 1
                else:
                    failed += 1
                    # Continue even if one fails
                    print(f"  [INFO] Continuing to next exercise...")
            except KeyboardInterrupt:
                print("\n\n[WARNING] Interrupted by user")
                print(f"Processed: {i}/{total}")
                print(f"Successful: {successful}, Failed: {failed}")
                print(f"\nTo resume, run: python generate_exercise_images.py --start-from {i}")
                sys.exit(0)
            except Exception as e:
                print(f"\n[ERROR] Unexpected error for {exercise.get('name_en', 'Unknown')}: {e}")
                print(f"  [INFO] Continuing to next exercise...")
                failed += 1
                # Add delay even on error to avoid rate limiting
                if i < total - 1:
                    time.sleep(DELAY_BETWEEN_REQUESTS)
                continue
        
        print("\n" + "=" * 60)
        print("Summary")
        print("=" * 60)
        print(f"Total exercises: {total}")
        print(f"Successful: {successful}")
        print(f"Failed: {failed}")
        print(f"Success rate: {(successful / total * 100):.1f}%")
        print()


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Generate exercise images using Replicate Nano Banana Pro"
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Limit number of exercises to process (for testing)",
    )
    parser.add_argument(
        "--start-from",
        type=int,
        default=0,
        help="Start from exercise index (for resuming)",
    )
    
    args = parser.parse_args()
    
    generator = ExerciseImageGenerator()
    generator.run(limit=args.limit, start_from=args.start_from)


if __name__ == "__main__":
    main()

