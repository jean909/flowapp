import os

def fix_file_formatting(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if the file has proper line breaks
    if len(content.splitlines()) < 20 and len(content) > 1000:
        print(f"Reformatting {file_path}...")
        
        # Rewrite the file with line breaks after each declaration/statement
        formatted_content = []
        imports = []
        current_line = ""
        
        # Extract the imports
        import_section = content.split("class")[0]
        for line in import_section.split(";"):
            if "import " in line:
                imports.append(line.strip() + ";")
        
        # Extract the class content
        class_section = "class" + content.split("class", 1)[1]
        
        # Create a nicely formatted class file
        formatted_content.extend(imports)
        formatted_content.append("")
        
        # Format the class content by splitting on common delimiters
        in_string = False
        result = []
        current_line = ""
        indent_level = 0
        
        for char in class_section:
            if char == '"' or char == "'":
                in_string = not in_string
                
            if not in_string:
                # Process code structure
                if char == '{':
                    indent_level += 1
                    current_line += " {"
                    result.append(current_line)
                    current_line = "  " * indent_level
                elif char == '}':
                    indent_level -= 1
                    if current_line.strip():
                        result.append(current_line)
                    current_line = "  " * indent_level + "}"
                    result.append(current_line)
                    current_line = "  " * indent_level
                elif char == ';':
                    current_line += ";"
                    result.append(current_line)
                    current_line = "  " * indent_level
                elif char in ('(', '[', ',', '?', ':'):
                    current_line += char + " "
                elif char in (')', ']'):
                    current_line += " " + char
                else:
                    current_line += char
            else:
                # Inside a string, keep everything as is
                current_line += char
        
        # Add any remaining content
        if current_line.strip():
            result.append(current_line)
        
        # Save the fixed content
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write("\n".join(formatted_content + result))
        return True
    return False

def main():
    # Path to the main_navigation.dart file
    file_path = os.path.join('lib', 'core', 'widgets', 'main_navigation.dart')
    
    if os.path.exists(file_path):
        if fix_file_formatting(file_path):
            print(f"Successfully fixed formatting in {file_path}")
        else:
            print(f"No formatting issues found in {file_path}")
    else:
        print(f"File not found: {file_path}")

if __name__ == "__main__":
    main()