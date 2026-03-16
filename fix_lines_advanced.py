import os
import re

def fix_file_advanced(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Advanced logic: add newlines after common end-of-line markers in Dart
    # but only if followed by a space or another keyword
    
    # 1. After semicolons
    processed = content.replace('; ', ';\n')
    
    # 2. After closing braces if followed by certain keywords
    processed = re.sub(r'} (class|Widget|final|bool|int|String|Map|List|DateTime|void|override|@|Future|case|default|if|else|return|switch|for|while)', r'}\n\1', processed)
    
    # 3. After closing braces if at the end of a block
    processed = processed.replace('} }', '}\n}')
    processed = processed.replace(') { ', ') {\n')
    
    # 4. Specific known mess in this file
    processed = processed.replace('intl.dart; ', 'intl.dart;\n\n')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(processed)

files = [
    "c:/Users/Administrator/Downloads/Ongoing projects/Flow/flow_app/lib/features/trackers/pages/menstruation_tracker_page.dart",
    "c:/Users/Administrator/Downloads/Ongoing projects/Flow/flow_app/lib/features/ai_coach/pages/coach_page.dart",
    "c:/Users/Administrator/Downloads/Ongoing projects/Flow/flow_app/lib/features/profile/pages/profile_page.dart",
    "c:/Users/Administrator/Downloads/Ongoing projects/Flow/flow_app/lib/features/marketplace/pages/marketplace_page.dart"
]

for path in files:
    if os.path.exists(path):
        fix_file_advanced(path)
        print(f"Fixed {os.path.basename(path)}")
