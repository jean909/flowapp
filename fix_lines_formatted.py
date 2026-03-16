import os
import re

def fix_file_formatting(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Detect if there are strings like "class" without proper line breaks
    if '{' in content and '}' in content:
        # Add line breaks after {, }, and ;
        content = re.sub(r'([{};])\s*', r'\1\n', content)
        
        # Add line breaks at class and method declarations
        content = re.sub(r'(class\s+\w+|[a-zA-Z_]\w*\s+[a-zA-Z_]\w*\s*\([^)]*\))\s*{', r'\1 {\n', content)
        
        # Clean up multiple consecutive empty lines
        content = re.sub(r'\n\s*\n', '\n\n', content)
        
        # Save the fixed content
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

def main():
    # Path to the main_navigation.dart file
    file_path = os.path.join('lib', 'core', 'widgets', 'main_navigation.dart')
    
    if os.path.exists(file_path):
        if fix_file_formatting(file_path):
            print(f"Fixed formatting in {file_path}")
        else:
            print(f"No formatting issues found in {file_path}")
    else:
        print(f"File not found: {file_path}")

if __name__ == "__main__":
    main()