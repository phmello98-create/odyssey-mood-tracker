#!/usr/bin/env python3
"""
Remove unused imports from Dart files based on flutter analyze output
"""

import subprocess
import re
from pathlib import Path

def get_unused_imports():
    """Get list of unused imports from flutter analyze"""
    result = subprocess.run(
        ['flutter', 'analyze', '--no-pub'],
        capture_output=True,
        text=True,
        cwd=Path(__file__).parent.parent
    )
    
    unused = []
    for line in result.stdout.split('\n'):
        if 'unused_import' in line:
            # Parse: warning • Unused import: 'package:...' • file.dart:line:col • unused_import
            parts = line.split('•')
            if len(parts) >= 3:
                import_text = parts[1].strip()
                location = parts[2].strip()
                
                # Extract import statement
                import_match = re.search(r"Unused import: '([^']+)'", import_text)
                if import_match:
                    import_path = import_match.group(1)
                    
                    # Extract file and line number
                    loc_parts = location.split(':')
                    if len(loc_parts) >= 2:
                        file_path = loc_parts[0].strip()
                        line_num = int(loc_parts[1])
                        unused.append((file_path, line_num, import_path))
    
    return unused

def remove_unused_import(file_path, line_num, import_path):
    """Remove a specific import from a file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Line numbers are 1-based, list is 0-based
        target_line = lines[line_num - 1]
        
        # Verify this is actually an import line with the expected path
        if import_path in target_line and target_line.strip().startswith('import'):
            # Remove the line
            del lines[line_num - 1]
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(lines)
            return True
    except Exception as e:
        print(f"Error processing {file_path}:{line_num} - {e}")
    return False

def main():
    print("🔍 Analisando imports não utilizados...")
    
    unused = get_unused_imports()
    
    if not unused:
        print("✅ Nenhum import não utilizado encontrado!")
        return
    
    print(f"📋 Encontrados {len(unused)} imports não utilizados")
    
    # Group by file
    by_file = {}
    for file_path, line_num, import_path in unused:
        if file_path not in by_file:
            by_file[file_path] = []
        by_file[file_path].append((line_num, import_path))
    
    # Sort by line number descending to avoid shifting line numbers
    for file_path in by_file:
        by_file[file_path].sort(reverse=True)
    
    fixed_count = 0
    for file_path, imports in by_file.items():
        for line_num, import_path in imports:
            if remove_unused_import(file_path, line_num, import_path):
                fixed_count += 1
                print(f"✓ {file_path}:{line_num}")
    
    print(f"\n✅ {fixed_count} imports removidos com sucesso!")

if __name__ == '__main__':
    main()
