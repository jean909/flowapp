#!/usr/bin/env python3
"""
Script to generate recipes using Gemini 3.0 Pro and create images with Nano Banana Pro.
Recipes include comprehensive nutritional data for supplement tracking.

Usage:
    python generate_recipes.py --recipe "High Protein Breakfast Bowl"
    python generate_recipes.py --count 10  # Generate 10 random recipes
    python generate_recipes.py --meal-type breakfast --count 5
    python generate_recipes.py --from-list  # Generate all recipes from european_recipes_list.json

Requirements:
    pip install replicate supabase pillow requests openai
"""

import os
import sys
import time
import json
import argparse
import requests
from typing import Optional, Dict, Any, List
from pathlib import Path
from io import BytesIO
import random

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
GEMINI_MODEL = "google/gemini-3-pro"
NANO_BANANA_MODEL = "google/nano-banana-pro"
STORAGE_BUCKET = "recipe_images"
MAX_IMAGE_SIZE = 1920  # HD
JPEG_QUALITY = 85
DELAY_BETWEEN_REQUESTS = 2  # seconds
REPLICATE_API_TIMEOUT = 300  # 5 minutes for API requests
REPLICATE_PREDICTION_TIMEOUT = 600  # 10 minutes max wait for prediction completion


class RecipeGenerator:
    def __init__(self):
        """Initialize the generator with API clients."""
        os.environ["REPLICATE_API_TOKEN"] = REPLICATE_API_TOKEN
        
        # Initialize Supabase client
        self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Initialize Replicate client
        self.replicate_client = replicate.Client(api_token=REPLICATE_API_TOKEN)
        
        print("[OK] Initialized Recipe Generator")
        print(f"  - Supabase URL: {SUPABASE_URL}")
        print(f"  - Gemini Model: {GEMINI_MODEL}")
        print(f"  - Nano Banana Model: {NANO_BANANA_MODEL}")
        print(f"  - Storage Bucket: {STORAGE_BUCKET}\n")

    def _fix_incomplete_json(self, json_str: str) -> str:
        """Try to fix incomplete JSON by closing brackets and braces."""
        json_str = json_str.strip()
        
        # Count brackets and braces
        open_braces = json_str.count('{')
        close_braces = json_str.count('}')
        open_brackets = json_str.count('[')
        close_brackets = json_str.count(']')
        
        # Close missing braces
        if open_braces > close_braces:
            # Find the last incomplete object
            last_brace = json_str.rfind('{')
            if last_brace != -1:
                # Check if it's in a string (don't close if it is)
                before_brace = json_str[:last_brace]
                quotes_before = before_brace.count('"') - before_brace.count('\\"')
                if quotes_before % 2 == 0:  # Not in a string
                    # Try to close the object properly
                    if not json_str.rstrip().endswith('}'):
                        # Find last comma and close
                        last_comma = json_str.rfind(',')
                        if last_comma > last_brace:
                            json_str = json_str[:last_comma] + '}' * (open_braces - close_braces)
                        else:
                            json_str += '}' * (open_braces - close_braces)
        
        # Close missing brackets
        if open_brackets > close_brackets:
            json_str += ']' * (open_brackets - close_brackets)
        
        # Close missing braces at the end
        if open_braces > close_braces:
            json_str += '}' * (open_braces - close_braces)
        
        return json_str
    
    def _validate_recipe_data(self, recipe_data: Dict[str, Any]) -> bool:
        """Validate that recipe has all required fields."""
        required_fields = [
            'title_en', 'title_de', 'prep_time_minutes', 'total_time_minutes',
            'servings', 'recommended_meal_type', 'cuisine_type', 'ingredients',
            'instructions_en', 'instructions_de', 'nutrition_per_serving'
        ]
        
        print(f"[DEBUG] Validating recipe data...")
        print(f"[DEBUG] Recipe data type: {type(recipe_data)}")
        print(f"[DEBUG] Recipe data keys: {list(recipe_data.keys()) if isinstance(recipe_data, dict) else 'NOT A DICT'}")
        
        for field in required_fields:
            if field not in recipe_data:
                print(f"[WARNING] Missing required field: {field}")
                print(f"[DEBUG] Available fields: {list(recipe_data.keys())}")
                return False
            else:
                print(f"[DEBUG] ✓ Field '{field}' present: {type(recipe_data[field])}")
        
        # Validate nutrition_per_serving
        nutrition = recipe_data.get('nutrition_per_serving', {})
        if not isinstance(nutrition, dict):
            print(f"[WARNING] nutrition_per_serving is not a dict: {type(nutrition)}")
            return False
        
        required_nutrients = ['calories', 'protein', 'carbs', 'fat']
        for nutrient in required_nutrients:
            if nutrient not in nutrition:
                print(f"[WARNING] Missing required nutrient: {nutrient}")
                print(f"[DEBUG] Available nutrients: {list(nutrition.keys())}")
                return False
            else:
                print(f"[DEBUG] ✓ Nutrient '{nutrient}' present: {nutrition[nutrient]}")
        
        print(f"[DEBUG] Validation passed!")
        return True

    def generate_recipe_with_gemini(self, recipe_name: Optional[str] = None, meal_type: Optional[str] = None, cuisine_type: Optional[str] = None, retry_count: int = 0) -> Dict[str, Any]:
        """Generate a complete recipe using Gemini 3.0 Pro."""
        print(f"Generating recipe with Gemini 3.0 Pro...")
        
        # Build prompt for comprehensive recipe generation
        cuisine_context = f"\nCuisine type: {cuisine_type}. Make sure the recipe is authentic to {cuisine_type} cuisine, using traditional ingredients and cooking methods." if cuisine_type else ""
        
        # System instruction to guide the model's behavior
        system_instruction = """You are an expert nutritionist and chef. Your task is to generate complete, detailed recipes with accurate nutritional information. 
You must always return valid, complete JSON with all required fields. Calculate nutritional values accurately based on ingredients.
Never truncate or omit any fields. Always ensure the JSON is properly closed with all brackets and braces."""
        
        prompt = f"""Generate a complete, detailed recipe in JSON format. 
        
        Recipe name: {recipe_name if recipe_name else 'a healthy, nutritious recipe'}
        Recommended meal type: {meal_type if meal_type else 'any appropriate meal type'}{cuisine_context}
        
        IMPORTANT: You must return a valid JSON object with the following structure:
        {{
            "title_en": "Recipe name in English",
            "title_de": "Recipe name in German",
            "description_en": "Brief description in English",
            "description_de": "Brief description in German",
            "prep_time_minutes": 15,
            "cook_time_minutes": 20,
            "total_time_minutes": 35,
            "servings": 2,
            "recommended_meal_type": "BREAKFAST|LUNCH|DINNER|SNACK",
            "diet_type": "vegetarian|vegan|pescetarian|keto|paleo|gluten-free|none",
            "cuisine_type": "Italian|French|Spanish|Greek|German|British|Mediterranean|European",
            "ingredients": [
                {{"name_en": "Ingredient name", "name_de": "German name", "amount": 100, "unit": "g"}}
            ],
            "instructions_en": [
                "Step 1 instruction",
                "Step 2 instruction"
            ],
            "instructions_de": [
                "Schritt 1 Anleitung",
                "Schritt 2 Anleitung"
            ],
            "nutrition_per_serving": {{
                "calories": 350.0,
                "protein": 25.0,
                "carbs": 30.0,
                "fat": 12.0,
                "fiber": 5.0,
                "sugar": 8.0,
                "saturated_fat": 3.0,
                "omega3": 0.5,
                "omega6": 1.2,
                "vitamin_a": 50.0,
                "vitamin_c": 60.0,
                "vitamin_d": 2.0,
                "vitamin_e": 3.0,
                "vitamin_k": 30.0,
                "vitamin_b1_thiamine": 0.5,
                "vitamin_b2_riboflavin": 0.4,
                "vitamin_b3_niacin": 5.0,
                "vitamin_b5_pantothenic_acid": 1.0,
                "vitamin_b6": 0.6,
                "vitamin_b7_biotin": 10.0,
                "vitamin_b9_folate": 100.0,
                "vitamin_b12": 2.0,
                "calcium": 200.0,
                "iron": 5.0,
                "magnesium": 50.0,
                "phosphorus": 150.0,
                "potassium": 400.0,
                "sodium": 500.0,
                "zinc": 3.0,
                "copper": 0.3,
                "manganese": 1.0,
                "selenium": 20.0,
                "chromium": 5.0,
                "molybdenum": 10.0,
                "iodine": 50.0,
                "water": 50.0,
                "caffeine": 0.0,
                "creatine": 0.0,
                "taurine": 0.0,
                "beta_alanine": 0.0,
                "l_carnitine": 0.0,
                "glutamine": 0.0,
                "bcaa": 0.0,
                "leucine": 2.0,
                "isoleucine": 1.0,
                "valine": 1.5,
                "lysine": 2.5,
                "methionine": 0.8,
                "phenylalanine": 1.2,
                "threonine": 1.0,
                "tryptophan": 0.3,
                "histidine": 0.8,
                "arginine": 1.5,
                "tyrosine": 1.0,
                "cysteine": 0.5,
                "alanine": 1.2,
                "aspartic_acid": 1.5,
                "glutamic_acid": 2.0,
                "serine": 1.0,
                "proline": 1.2,
                "glycine": 1.0
            }},
            "tags": ["high-protein", "quick", "healthy"]
        }}
        
        CRITICAL REQUIREMENTS:
        1. Calculate ALL nutritional values accurately based on ingredients - be thorough and detailed
        2. Include ALL vitamins, minerals, amino acids, and specialized nutrients with precise values
        3. Values should be realistic and based on actual food composition - research typical values for each ingredient
        4. If a nutrient is not present or negligible, set it to 0.0
        5. Ensure instructions are clear, detailed, and step-by-step - include cooking tips and techniques
        6. Make the recipe appealing and practical - add helpful notes about preparation
        7. Provide detailed descriptions in both English and German - make them informative and appetizing
        8. List ALL ingredients with accurate amounts - be comprehensive
        9. Include cooking tips, serving suggestions, and storage advice if relevant
        10. Return ONLY valid JSON, no markdown, no code blocks - ensure the JSON is complete and well-formatted
        11. IMPORTANT: The JSON must be COMPLETE - all brackets and braces must be closed
        12. Make sure the nutrition_per_serving object includes ALL nutrients listed in the example above
        13. The response must be a valid, parseable JSON object - test it before returning
        14. CRITICAL: You MUST include the complete nutrition_per_serving object with ALL nutrients - do not truncate or omit any fields
        15. Ensure the JSON response is fully complete before returning - count all opening and closing brackets/braces
        16. The nutrition_per_serving object must contain ALL 50+ nutrient fields shown in the example - calories, protein, carbs, fat, fiber, sugar, saturated_fat, omega3, omega6, all vitamins (A, C, D, E, K, B1-B12), all minerals (calcium, iron, magnesium, etc.), water, caffeine, creatine, taurine, beta_alanine, l_carnitine, glutamine, bcaa, and ALL amino acids (leucine, isoleucine, valine, lysine, methionine, phenylalanine, threonine, tryptophan, histidine, arginine, tyrosine, cysteine, alanine, aspartic_acid, glutamic_acid, serine, proline, glycine)"""
        
        try:
            # Get model version
            model_url = f"https://api.replicate.com/v1/models/{GEMINI_MODEL}"
            model_response = requests.get(
                model_url,
                headers={
                    'Authorization': f'Token {REPLICATE_API_TOKEN}',
                    'Content-Type': 'application/json',
                },
                timeout=REPLICATE_API_TIMEOUT,
            )
            
            if model_response.status_code != 200:
                raise Exception(f'Failed to get model: {model_response.status_code}')
            
            model_data = model_response.json()
            latest_version = model_data.get('latest_version', {})
            version_id = latest_version.get('id')
            
            if not version_id:
                raise Exception('No version found for model')
            
            # Create prediction
            prediction_url = "https://api.replicate.com/v1/predictions"
            prediction_response = requests.post(
                prediction_url,
                headers={
                    'Authorization': f'Token {REPLICATE_API_TOKEN}',
                    'Content-Type': 'application/json',
                },
                json={
                    'version': version_id,
                    'input': {
                        'prompt': prompt,
                        'system_instruction': system_instruction,
                        'temperature': 0.7,
                        'top_p': 0.95,
                        'max_output_tokens': 20000,  # Increased for complete responses (max is 65535)
                        'thinking_level': 'high',  # High thinking level for better reasoning and complete responses
                    }
                },
                timeout=REPLICATE_API_TIMEOUT,
            )
            
            if prediction_response.status_code != 201:
                raise Exception(f'Failed to create prediction: {prediction_response.status_code} - {prediction_response.text}')
            
            prediction = prediction_response.json()
            prediction_id = prediction['id']
            
            # Wait for completion
            print(f"  Waiting for Gemini response (prediction: {prediction_id})...")
            start_time = time.time()
            last_output_length = 0
            stable_count = 0
            
            while True:
                # Check timeout
                elapsed_time = time.time() - start_time
                if elapsed_time > REPLICATE_PREDICTION_TIMEOUT:
                    raise Exception(f"Prediction timeout after {REPLICATE_PREDICTION_TIMEOUT} seconds")
                
                status_response = requests.get(
                    f"{prediction_url}/{prediction_id}",
                    headers={'Authorization': f'Token {REPLICATE_API_TOKEN}'},
                    timeout=REPLICATE_API_TIMEOUT,
                )
                status_data = status_response.json()
                
                # Debug: print status and available keys
                if status_data['status'] == 'processing':
                    # Check if output is growing (streaming)
                    current_output = status_data.get('output', '')
                    if isinstance(current_output, str):
                        current_length = len(current_output)
                        if current_length > last_output_length:
                            print(f"  Status: {status_data['status']}... (output: {current_length} chars)", end='\r')
                            last_output_length = current_length
                            stable_count = 0
                        else:
                            stable_count += 1
                            if stable_count > 3:  # Output hasn't grown in 3 checks
                                print(f"  Status: {status_data['status']}... (output stable at {current_length} chars)", end='\r')
                    else:
                        print(f"  Status: {status_data['status']}...", end='\r')
                    time.sleep(2)
                    continue
                
                if status_data['status'] == 'succeeded':
                    print(f"\n[DEBUG] Prediction succeeded")
                    print(f"[DEBUG] Status data keys: {list(status_data.keys())}")
                    
                    # Check for output in different possible locations
                    output = status_data.get('output')
                    
                    # Handle different output formats from Replicate
                    # Replicate returns output as a list of string chunks that need to be concatenated
                    print(f"[DEBUG] Raw output type: {type(output)}")
                    
                    if isinstance(output, list):
                        # Output is a list of chunks - concatenate them
                        if len(output) > 0:
                            print(f"[DEBUG] Output is a list with {len(output)} chunks")
                            print(f"[DEBUG] First chunk preview: {str(output[0])[:100]}...")
                            print(f"[DEBUG] Last chunk preview: ...{str(output[-1])[-100:]}")
                            
                            if all(isinstance(item, str) for item in output):
                                # Concatenate all string chunks
                                output = ''.join(output)
                                print(f"[DEBUG] ✓ Concatenated {len(status_data.get('output', []))} output chunks")
                                print(f"[DEBUG] ✓ Total concatenated length: {len(output)} characters")
                            else:
                                # If list contains non-strings, try to convert
                                output_strs = [str(item) for item in output]
                                output = ''.join(output_strs)
                                print(f"[DEBUG] ✓ Converted and concatenated {len(output_strs)} output items")
                                print(f"[DEBUG] ✓ Total concatenated length: {len(output)} characters")
                        else:
                            raise Exception("Empty output list")
                    elif isinstance(output, str):
                        print(f"[DEBUG] Output is already a string (length: {len(output)})")
                    else:
                        print(f"[WARNING] Unexpected output type: {type(output)}, value: {output}")
                        raise Exception(f"Unexpected output format: {type(output)}")
                    
                    # If output is still too short, check if there's more data elsewhere
                    if isinstance(output, str) and len(output) < 500:
                        print(f"[WARNING] Output is very short ({len(output)} chars) - checking for more data...")
                        # Check if there's a 'urls' field with output
                        urls = status_data.get('urls', {})
                        if 'get' in urls:
                            print(f"[DEBUG] Found 'get' URL, trying to fetch complete output...")
                            try:
                                complete_response = requests.get(urls['get'], timeout=REPLICATE_API_TIMEOUT)
                                if complete_response.status_code == 200:
                                    complete_data = complete_response.json()
                                    complete_output = complete_data.get('output')
                                    if complete_output and len(str(complete_output)) > len(output):
                                        output = complete_output
                                        print(f"[DEBUG] Got complete output from URL (length: {len(str(output))})")
                            except Exception as url_error:
                                print(f"[DEBUG] Could not fetch from URL: {url_error}")
                    
                    # Parse JSON response
                    if isinstance(output, str):
                        print(f"[DEBUG] Raw output length: {len(output)}")
                        print(f"[DEBUG] Raw output preview (first 200 chars): {output[:200]}")
                        
                        # Try to extract JSON from markdown code blocks
                        if '```json' in output:
                            output = output.split('```json')[1].split('```')[0].strip()
                            print(f"[DEBUG] Extracted JSON from markdown code block")
                        elif '```' in output:
                            output = output.split('```')[1].split('```')[0].strip()
                            print(f"[DEBUG] Extracted JSON from code block")
                        
                        # Check if output is too short (likely truncated)
                        if len(output) < 500:
                            print(f"[WARNING] Output seems too short ({len(output)} chars) - might be truncated")
                            print(f"[DEBUG] Full output: {output}")
                        
                        # Try to fix incomplete JSON
                        output = self._fix_incomplete_json(output)
                        
                        try:
                            recipe_data = json.loads(output)
                            print(f"[DEBUG] JSON parsed successfully")
                            print(f"[DEBUG] Recipe keys: {list(recipe_data.keys())}")
                            # Validate required fields
                            if not self._validate_recipe_data(recipe_data):
                                print(f"[ERROR] Validation failed - recipe data:")
                                print(f"[ERROR] {json.dumps(recipe_data, indent=2, default=str)[:500]}")
                                raise Exception("Recipe data missing required fields")
                            print(f"[OK] Recipe generated: {recipe_data.get('title_en', 'Unknown')}")
                            return recipe_data
                        except json.JSONDecodeError as e:
                            print(f"[ERROR] JSON decode error: {e}")
                            print(f"[DEBUG] Output length: {len(output)}")
                            print(f"[DEBUG] Full output: {output}")
                            print(f"[DEBUG] Last 500 chars: {output[-500:]}")
                            raise Exception(f"Invalid JSON response: {e}")
                    else:
                        print(f"[ERROR] Unexpected output type: {type(output)}")
                        print(f"[ERROR] Output value: {output}")
                        raise Exception(f"Unexpected output format: {type(output)}")
                elif status_data['status'] == 'failed':
                    raise Exception(f"Prediction failed: {status_data.get('error', 'Unknown error')}")
                
                time.sleep(2)
                
        except Exception as e:
            print(f"[ERROR] Error generating recipe: {e}")
            # Retry logic
            if retry_count < 2:
                print(f"[RETRY] Retrying... ({retry_count + 1}/2)")
                time.sleep(5)
                return self.generate_recipe_with_gemini(recipe_name, meal_type, cuisine_type, retry_count + 1)
            raise

    def generate_recipe_image(self, recipe_title: str, description: str) -> Optional[str]:
        """Generate a beautiful, cozy recipe image using Nano Banana Pro."""
        print(f"  Generating image for recipe: {recipe_title}...")
        
        prompt = f"""A beautiful, cozy, appetizing food photography of {recipe_title}. 
        Professional food styling, warm lighting, rustic background, 
        high quality, Instagram-worthy, makes you want to cook and eat it immediately.
        {description}
        Style: cozy, inviting, professional food photography"""
        
        try:
            output = self.replicate_client.run(
                NANO_BANANA_MODEL,
                input={
                    "prompt": prompt,
                    "resolution": "1K",
                    "aspect_ratio": "16:9",
                    "output_format": "jpg",
                    "safety_filter_level": "block_only_high"
                }
            )
            
            # Handle FileOutput object
            if hasattr(output, 'url'):
                image_url = output.url
            elif isinstance(output, str):
                image_url = output
            elif isinstance(output, list) and len(output) > 0:
                image_url = output[0] if isinstance(output[0], str) else str(output[0])
            else:
                raise Exception(f"Unexpected output format: {type(output)}")
            
            print(f"[OK] Image generated: {image_url}")
            return image_url
            
        except Exception as e:
            print(f"[ERROR] Error generating image: {e}")
            return None

    def download_and_compress_image(self, image_url: str) -> Optional[BytesIO]:
        """Download and compress image for Supabase upload."""
        try:
            print(f"  Downloading image from {image_url}...")
            response = requests.get(image_url, timeout=30)
            response.raise_for_status()
            
            # Open and compress
            img = Image.open(BytesIO(response.content))
            
            # Resize if needed
            if img.width > MAX_IMAGE_SIZE or img.height > MAX_IMAGE_SIZE:
                img.thumbnail((MAX_IMAGE_SIZE, MAX_IMAGE_SIZE), Image.Resampling.LANCZOS)
            
            # Convert to RGB if needed
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Compress
            output = BytesIO()
            img.save(output, format='JPEG', quality=JPEG_QUALITY, optimize=True)
            output.seek(0)
            
            print(f"[OK] Image compressed: {img.width}x{img.height}")
            return output
            
        except Exception as e:
            print(f"[ERROR] Error processing image: {e}")
            return None

    def upload_image_to_supabase(self, image_data: BytesIO, recipe_id: str) -> Optional[str]:
        """Upload compressed image to Supabase Storage."""
        try:
            file_path = f"{recipe_id}.jpg"
            
            print(f"  Uploading image to Supabase Storage...")
            result = self.supabase.storage.from_(STORAGE_BUCKET).upload(
                file_path,
                image_data.getvalue(),
                file_options={"content-type": "image/jpeg", "upsert": "true"}
            )
            
            # Get public URL
            public_url = self.supabase.storage.from_(STORAGE_BUCKET).get_public_url(file_path)
            print(f"[OK] Image uploaded: {public_url}")
            return public_url
            
        except Exception as e:
            print(f"[ERROR] Error uploading image: {e}")
            return None

    def recipe_exists(self, recipe_name: str) -> bool:
        """Check if a recipe with the given name already exists in Supabase."""
        try:
            # Search for recipe by title_en (case-insensitive partial match)
            result = self.supabase.table('recipes').select('id, title_en').ilike('title_en', f'%{recipe_name}%').limit(1).execute()
            
            if result.data and len(result.data) > 0:
                existing_title = result.data[0].get('title_en', '')
                # Check if it's a close match (normalize both for comparison)
                recipe_name_lower = recipe_name.lower().strip()
                existing_title_lower = existing_title.lower().strip()
                
                # If the recipe name is contained in the existing title or vice versa
                if recipe_name_lower in existing_title_lower or existing_title_lower in recipe_name_lower:
                    print(f"[SKIP] Recipe already exists: {existing_title}")
                    return True
            
            return False
        except Exception as e:
            print(f"[WARNING] Error checking if recipe exists: {e}")
            # If check fails, assume it doesn't exist to avoid skipping
            return False

    def save_recipe_to_database(self, recipe_data: Dict[str, Any], image_url: Optional[str] = None) -> Optional[str]:
        """Save recipe to Supabase database."""
        try:
            print(f"[DEBUG] Preparing to save recipe: {recipe_data.get('title_en', 'Unknown')}")
            nutrition = recipe_data.get('nutrition_per_serving', {})
            
            if not nutrition:
                print("[ERROR] nutrition_per_serving is missing!")
                return None
            
            # Prepare recipe record
            recipe_record = {
                'title_en': recipe_data.get('title_en'),
                'title_de': recipe_data.get('title_de'),
                'description_en': recipe_data.get('description_en') or '',
                'description_de': recipe_data.get('description_de') or '',
                'prep_time_minutes': recipe_data.get('prep_time_minutes', 0),
                'cook_time_minutes': recipe_data.get('cook_time_minutes') or 0,
                'total_time_minutes': recipe_data.get('total_time_minutes') or (recipe_data.get('prep_time_minutes', 0) + (recipe_data.get('cook_time_minutes') or 0)),
                'servings': recipe_data.get('servings', 1),
                'recommended_meal_type': recipe_data.get('recommended_meal_type') or 'DINNER',
                'diet_type': recipe_data.get('diet_type') or 'none',
                'cuisine_type': recipe_data.get('cuisine_type') or 'European',
                'ingredients': json.dumps(recipe_data.get('ingredients', [])),
                'instructions_en': json.dumps(recipe_data.get('instructions_en', [])),
                'instructions_de': json.dumps(recipe_data.get('instructions_de', [])),
                'image_url': image_url,
                'source': 'ai_generated',
                'is_public': True,
                'is_featured': False,
                # Nutritional data - all fields
                'calories': nutrition.get('calories', 0),
                'protein': nutrition.get('protein', 0),
                'carbs': nutrition.get('carbs', 0),
                'fat': nutrition.get('fat', 0),
                'fiber': nutrition.get('fiber', 0),
                'sugar': nutrition.get('sugar', 0),
                'saturated_fat': nutrition.get('saturated_fat', 0),
                'omega3': nutrition.get('omega3', 0),
                'omega6': nutrition.get('omega6', 0),
                'vitamin_a': nutrition.get('vitamin_a', 0),
                'vitamin_c': nutrition.get('vitamin_c', 0),
                'vitamin_d': nutrition.get('vitamin_d', 0),
                'vitamin_e': nutrition.get('vitamin_e', 0),
                'vitamin_k': nutrition.get('vitamin_k', 0),
                'vitamin_b1_thiamine': nutrition.get('vitamin_b1_thiamine', 0),
                'vitamin_b2_riboflavin': nutrition.get('vitamin_b2_riboflavin', 0),
                'vitamin_b3_niacin': nutrition.get('vitamin_b3_niacin', 0),
                'vitamin_b5_pantothenic_acid': nutrition.get('vitamin_b5_pantothenic_acid', 0),
                'vitamin_b6': nutrition.get('vitamin_b6', 0),
                'vitamin_b7_biotin': nutrition.get('vitamin_b7_biotin', 0),
                'vitamin_b9_folate': nutrition.get('vitamin_b9_folate', 0),
                'vitamin_b12': nutrition.get('vitamin_b12', 0),
                'calcium': nutrition.get('calcium', 0),
                'iron': nutrition.get('iron', 0),
                'magnesium': nutrition.get('magnesium', 0),
                'phosphorus': nutrition.get('phosphorus', 0),
                'potassium': nutrition.get('potassium', 0),
                'sodium': nutrition.get('sodium', 0),
                'zinc': nutrition.get('zinc', 0),
                'copper': nutrition.get('copper', 0),
                'manganese': nutrition.get('manganese', 0),
                'selenium': nutrition.get('selenium', 0),
                'chromium': nutrition.get('chromium', 0),
                'molybdenum': nutrition.get('molybdenum', 0),
                'iodine': nutrition.get('iodine', 0),
                'water': nutrition.get('water', 0),
                'caffeine': nutrition.get('caffeine', 0),
                'creatine': nutrition.get('creatine', 0),
                'taurine': nutrition.get('taurine', 0),
                'beta_alanine': nutrition.get('beta_alanine', 0),
                'l_carnitine': nutrition.get('l_carnitine', 0),
                'glutamine': nutrition.get('glutamine', 0),
                'bcaa': nutrition.get('bcaa', 0),
                'leucine': nutrition.get('leucine', 0),
                'isoleucine': nutrition.get('isoleucine', 0),
                'valine': nutrition.get('valine', 0),
                'lysine': nutrition.get('lysine', 0),
                'methionine': nutrition.get('methionine', 0),
                'phenylalanine': nutrition.get('phenylalanine', 0),
                'threonine': nutrition.get('threonine', 0),
                'tryptophan': nutrition.get('tryptophan', 0),
                'histidine': nutrition.get('histidine', 0),
                'arginine': nutrition.get('arginine', 0),
                'tyrosine': nutrition.get('tyrosine', 0),
                'cysteine': nutrition.get('cysteine', 0),
                'alanine': nutrition.get('alanine', 0),
                'aspartic_acid': nutrition.get('aspartic_acid', 0),
                'glutamic_acid': nutrition.get('glutamic_acid', 0),
                'serine': nutrition.get('serine', 0),
                'proline': nutrition.get('proline', 0),
                'glycine': nutrition.get('glycine', 0),
            }
            
            # Insert recipe
            print(f"[DEBUG] Inserting recipe into database...")
            print(f"[DEBUG] Recipe record keys: {list(recipe_record.keys())}")
            print(f"[DEBUG] Title EN: {recipe_record.get('title_en')}")
            print(f"[DEBUG] Cuisine: {recipe_record.get('cuisine_type')}")
            print(f"[DEBUG] Calories: {recipe_record.get('calories')}")
            
            # Remove None values to avoid database errors
            recipe_record_clean = {k: v for k, v in recipe_record.items() if v is not None}
            
            # Define boolean fields that should never be converted
            boolean_fields = ['is_public', 'is_featured']
            time_fields = ['prep_time_minutes', 'cook_time_minutes', 'total_time_minutes', 'servings']
            
            # Convert all numeric values to proper types (float for decimals, int for integers)
            # But preserve boolean fields and time fields
            for key, value in recipe_record_clean.items():
                if key in boolean_fields:
                    # Ensure boolean fields are actual booleans
                    if isinstance(value, bool):
                        recipe_record_clean[key] = value
                    elif isinstance(value, str):
                        recipe_record_clean[key] = value.lower() in ('true', '1', 'yes')
                    elif isinstance(value, (int, float)):
                        recipe_record_clean[key] = bool(value)
                    # Keep as is if already boolean
                elif key in time_fields:
                    recipe_record_clean[key] = int(value) if value else 0
                elif isinstance(value, (int, float)):
                    recipe_record_clean[key] = float(value)
                # Keep other types (strings, etc.) as is
            
            print(f"[DEBUG] Recipe record cleaned, {len(recipe_record_clean)} fields")
            print(f"[DEBUG] Sample fields: title_en={recipe_record_clean.get('title_en')}, calories={recipe_record_clean.get('calories')}, protein={recipe_record_clean.get('protein')}")
            
            try:
                result = self.supabase.table('recipes').insert(recipe_record_clean).execute()
                print(f"[DEBUG] Insert executed successfully")
            except Exception as insert_error:
                print(f"[ERROR] Insert failed: {insert_error}")
                print(f"[ERROR] Error type: {type(insert_error)}")
                import traceback
                print(f"[ERROR] Traceback: {traceback.format_exc()}")
                raise
            
            print(f"[DEBUG] Insert result type: {type(result)}")
            print(f"[DEBUG] Insert result: {result}")
            
            # Check different possible response formats
            recipe_id = None
            if hasattr(result, 'data') and result.data:
                if isinstance(result.data, list) and len(result.data) > 0:
                    recipe_id = result.data[0].get('id')
                elif isinstance(result.data, dict):
                    recipe_id = result.data.get('id')
            elif hasattr(result, 'json') and result.json:
                data = result.json() if callable(result.json) else result.json
                if isinstance(data, list) and len(data) > 0:
                    recipe_id = data[0].get('id')
                elif isinstance(data, dict):
                    recipe_id = data.get('id')
            
            if recipe_id:
                print(f"[OK] Recipe saved to database: {recipe_id}")
                
                # Add tags
                tags = recipe_data.get('tags', [])
                if tags:
                    try:
                        tag_records = [{'recipe_id': recipe_id, 'tag': tag} for tag in tags]
                        self.supabase.table('recipe_tags').insert(tag_records).execute()
                        print(f"[OK] Added {len(tags)} tags")
                    except Exception as tag_error:
                        print(f"[WARNING] Error adding tags: {tag_error}")
                
                return recipe_id
            else:
                error_msg = "No data returned from insert"
                if hasattr(result, 'error'):
                    error_msg = f"{error_msg} - Error: {result.error}"
                if hasattr(result, 'status_code'):
                    error_msg = f"{error_msg} - Status: {result.status_code}"
                
                # Try to get more info from result
                try:
                    if hasattr(result, '__dict__'):
                        print(f"[DEBUG] Result attributes: {result.__dict__}")
                    if hasattr(result, 'data'):
                        print(f"[DEBUG] Result.data: {result.data}")
                    if hasattr(result, 'error'):
                        print(f"[DEBUG] Result.error: {result.error}")
                except:
                    pass
                
                print(f"[ERROR] {error_msg}")
                print(f"[DEBUG] Full result object: {result}")
                print(f"[DEBUG] Recipe record that failed: {json.dumps(recipe_record_clean, indent=2, default=str)}")
                raise Exception(error_msg)
                
        except Exception as e:
            print(f"[ERROR] Error saving recipe: {e}")
            import traceback
            print(f"[ERROR] Traceback: {traceback.format_exc()}")
            return None

    def generate_complete_recipe(self, recipe_name: Optional[str] = None, meal_type: Optional[str] = None, cuisine_type: Optional[str] = None) -> bool:
        """
        Generate a complete recipe with image.
        Flow: Check if exists -> Generate recipe -> Save to Supabase -> Generate image -> Upload image -> Update recipe.
        If any step fails, returns False and stops.
        """
        try:
            # Step 0: Check if recipe already exists
            if recipe_name:
                print(f"[STEP 0] Checking if recipe already exists: {recipe_name}...")
                if self.recipe_exists(recipe_name):
                    print(f"[SKIP] Recipe '{recipe_name}' already exists in database - skipping generation")
                    return True  # Return True because we're skipping, not failing
                print(f"[STEP 0 OK] Recipe '{recipe_name}' not found - will generate new")
            
            # Step 1: Generate recipe with Gemini
            print(f"[STEP 1] Generating recipe data with Gemini...")
            recipe_data = self.generate_recipe_with_gemini(recipe_name, meal_type, cuisine_type)
            
            if not recipe_data:
                print("[ERROR] Step 1 FAILED: Failed to generate recipe data")
                return False
            
            print(f"[STEP 1 OK] Recipe data generated: {recipe_data.get('title_en', 'Unknown')}")
            print(f"[DEBUG] Recipe has nutrition_per_serving: {bool(recipe_data.get('nutrition_per_serving'))}")
            
            # Step 2: Save recipe to Supabase (without image first)
            print(f"[STEP 2] Saving recipe to Supabase database...")
            try:
                recipe_id = self.save_recipe_to_database(recipe_data)
            except Exception as save_error:
                print(f"[ERROR] Step 2 FAILED: Exception during save: {save_error}")
                import traceback
                print(f"[ERROR] Traceback: {traceback.format_exc()}")
                return False
            
            if not recipe_id:
                print("[ERROR] Step 2 FAILED: Failed to save recipe to database - recipe_id is None")
                return False
            
            print(f"[STEP 2 OK] Recipe saved to Supabase with ID: {recipe_id}")
            
            # Step 3: Generate image
            print(f"[STEP 3] Generating image...")
            image_url = self.generate_recipe_image(
                recipe_data.get('title_en', 'Recipe'),
                recipe_data.get('description_en', '')
            )
            
            if not image_url:
                print("[ERROR] Step 3 FAILED: Could not generate image")
                print("[ERROR] Stopping - recipe saved but without image")
                return False
            
            print(f"[STEP 3 OK] Image generated: {image_url}")
            
            # Step 4: Download and compress image
            print(f"[STEP 4] Downloading and compressing image...")
            image_data = self.download_and_compress_image(image_url)
            
            if not image_data:
                print("[ERROR] Step 4 FAILED: Could not download/compress image")
                print("[ERROR] Stopping - recipe saved but without image")
                return False
            
            print(f"[STEP 4 OK] Image downloaded and compressed")
            
            # Step 5: Upload image to Supabase Storage
            print(f"[STEP 5] Uploading image to Supabase Storage...")
            final_image_url = self.upload_image_to_supabase(image_data, recipe_id)
            
            if not final_image_url:
                print("[ERROR] Step 5 FAILED: Could not upload image to Supabase")
                print("[ERROR] Stopping - recipe saved but without image")
                return False
            
            print(f"[STEP 5 OK] Image uploaded: {final_image_url}")
            
            # Step 6: Update recipe with image URL
            print(f"[STEP 6] Updating recipe with image URL...")
            try:
                update_result = self.supabase.table('recipes').update({'image_url': final_image_url}).eq('id', recipe_id).execute()
                if not update_result.data:
                    print("[ERROR] Step 6 FAILED: Could not update recipe with image URL")
                    return False
                print(f"[STEP 6 OK] Recipe updated with image URL")
            except Exception as update_error:
                print(f"[ERROR] Step 6 FAILED: Exception updating recipe: {update_error}")
                import traceback
                print(f"[ERROR] Traceback: {traceback.format_exc()}")
                return False
            
            print(f"[SUCCESS] Recipe generation complete! ID: {recipe_id}, Image: {final_image_url}\n")
            time.sleep(DELAY_BETWEEN_REQUESTS)
            return True
            
        except Exception as e:
            print(f"[ERROR] CRITICAL ERROR: Failed to generate recipe: {e}\n")
            import traceback
            print(f"[ERROR] Traceback: {traceback.format_exc()}\n")
            return False


def main():
    parser = argparse.ArgumentParser(description='Generate recipes with AI')
    parser.add_argument('--recipe', type=str, help='Specific recipe name to generate')
    parser.add_argument('--count', type=int, default=1, help='Number of recipes to generate')
    parser.add_argument('--meal-type', type=str, choices=['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'], help='Meal type')
    parser.add_argument('--from-list', action='store_true', help='Generate all recipes from european_recipes_list.json')
    
    args = parser.parse_args()
    
    generator = RecipeGenerator()
    
    # Load European recipes list
    recipes_list = []
    if args.from_list:
        try:
            with open('european_recipes_list.json', 'r', encoding='utf-8') as f:
                recipes_list = json.load(f)
            print(f"[OK] Loaded {len(recipes_list)} recipes from list\n")
        except FileNotFoundError:
            print("[ERROR] european_recipes_list.json not found!")
            return
        except json.JSONDecodeError as e:
            print(f"[ERROR] Invalid JSON in european_recipes_list.json: {e}")
            return
    
    # Recipe ideas if not specified
    recipe_ideas = [
        "High Protein Greek Yogurt Bowl",
        "Mediterranean Quinoa Salad",
        "Asian-Inspired Salmon Bowl",
        "Protein-Packed Smoothie Bowl",
        "Vegan Buddha Bowl",
        "Keto Chicken Caesar Salad",
        "Overnight Oats with Berries",
        "Grilled Chicken with Vegetables",
        "Plant-Based Power Bowl",
        "Low-Carb Zucchini Noodles",
    ]
    
    success_count = 0
    total_count = len(recipes_list) if args.from_list else args.count
    
    # Limit to 5 recipes for testing
    if args.from_list:
        total_count = min(5, len(recipes_list))
        print(f"[INFO] Limiting to {total_count} recipes for testing\n")
    
    # Filter out recipes that already exist
    recipes_to_generate = []
    if args.from_list:
        print(f"[INFO] Checking which recipes already exist in database...")
        for recipe_info in recipes_list:
            recipe_name = recipe_info['name']
            if not generator.recipe_exists(recipe_name):
                recipes_to_generate.append(recipe_info)
            else:
                print(f"[SKIP] '{recipe_name}' already exists - will skip")
        
        print(f"[INFO] Found {len(recipes_to_generate)} recipes to generate (skipping {len(recipes_list) - len(recipes_to_generate)} existing)\n")
        
        # Limit to 5 recipes for testing
        recipes_to_generate = recipes_to_generate[:5]
        total_count = len(recipes_to_generate)
    else:
        # For non-list mode, just use the original logic
        recipes_to_generate = [None] * total_count
    
    if not recipes_to_generate:
        print(f"[INFO] All recipes already exist in database. Nothing to generate!")
        return
    
    for i, recipe_info in enumerate(recipes_to_generate):
        if args.from_list:
            recipe_name = recipe_info['name']
            meal_type = recipe_info.get('meal_type')
            cuisine_type = recipe_info.get('cuisine')
        else:
            recipe_name = args.recipe if args.recipe else (recipe_ideas[i % len(recipe_ideas)] if i < len(recipe_ideas) else None)
            meal_type = args.meal_type
            cuisine_type = None
        
        print(f"\n{'='*60}")
        print(f"Generating recipe {i+1}/{total_count}")
        print(f"Recipe: {recipe_name}")
        if cuisine_type:
            print(f"Cuisine: {cuisine_type}")
        if meal_type:
            print(f"Meal Type: {meal_type}")
        print(f"{'='*60}\n")
        
        result = generator.generate_complete_recipe(recipe_name, meal_type, cuisine_type)
        if result:
            success_count += 1
            print(f"[SUCCESS] Recipe {i+1}/{total_count} completed successfully\n")
        else:
            print(f"[FAILED] Recipe {i+1}/{total_count} failed - stopping generation\n")
            print(f"[INFO] Successfully generated: {success_count}/{i+1} recipes before failure")
            break  # Stop if any recipe fails
    
    print(f"\n{'='*60}")
    print(f"Generation complete: {success_count}/{total_count} recipes generated successfully")
    if success_count < total_count:
        print(f"[WARNING] Generation stopped early due to failure")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()

