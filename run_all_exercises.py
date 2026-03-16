#!/usr/bin/env python3
"""Run exercise image generation for all missing exercises"""

import subprocess
import sys

print("Starting exercise image generation for all exercises...")
print("This will process 38 exercises without images.")
print("Estimated time: 3-5 minutes\n")

# Run the script
result = subprocess.run(
    [sys.executable, "generate_exercise_images.py"],
    capture_output=False,
    text=True
)

print(f"\nProcess completed with exit code: {result.returncode}")

