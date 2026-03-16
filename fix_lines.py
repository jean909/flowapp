import os

def fix_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Simple heuristic to split lines
    new_content = content.replace('; ', ';\n').replace('} ', '}\n').replace('{ ', '{\n')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(new_content)

files = [
    "c:/Users/Administrator/Downloads/Ongoing projects/Flow/flow_app/lib/features/trackers/pages/menstruation_tracker_page.dart",
    "c:/Users/Administrator/Downloads/Ongoing projects/Flow/flow_app/lib/features/profile/pages/profile_page.dart",
    "c:/Users/Administrator/Downloads/Ongoing projects/Flow/flow_app/lib/features/ai_coach/pages/coach_page.dart",
    "c:/Users/Administrator/Downloads/Ongoing projects/Flow/flow_app/lib/features/trackers/widgets/menstruation_onboarding_dialog.dart"
]

for f in files:
    if os.path.exists(f):
        fix_file(f)
        print(f"Fixed {f}")
    else:
        print(f"File not found: {f}")
