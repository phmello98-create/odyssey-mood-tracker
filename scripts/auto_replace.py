#!/usr/bin/env python3
"""
Auto-replace hardcoded strings with AppLocalizations calls.
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Tuple

PROJECT_ROOT = Path(__file__).parent.parent
LIB_PATH = PROJECT_ROOT / "lib" / "src"
ARB_PT_PATH = PROJECT_ROOT / "lib" / "src" / "localization" / "app_pt.arb"

def load_arb(path: Path) -> Dict:
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def build_value_to_key_map(arb: Dict) -> Dict[str, str]:
    """Build reverse mapping: value -> key"""
    return {v: k for k, v in arb.items() if not k.startswith('@') and not k.startswith('@@')}

def has_applocalization_import(content: str) -> bool:
    """Check if file has AppLocalizations import."""
    return 'flutter_gen/gen_l10n/app_localizations.dart' in content or \
           'AppLocalizations' in content

def add_import_if_needed(content: str) -> str:
    """Add AppLocalizations import if not present."""
    if has_applocalization_import(content):
        return content
    
    # Find the last import line
    lines = content.split('\n')
    last_import_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('import '):
            last_import_idx = i
    
    # Insert after last import
    import_line = "import 'package:flutter_gen/gen_l10n/app_localizations.dart';"
    lines.insert(last_import_idx + 1, import_line)
    
    return '\n'.join(lines)

def replace_hardcoded_strings(file_path: Path, value_to_key: Dict[str, str]) -> Tuple[bool, int]:
    """Replace hardcoded Text() strings with AppLocalizations calls."""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        original_content = f.read()
    
    content = original_content
    replacements = 0
    
    # Pattern for Text('string') or Text("string")
    pattern = r"Text\(\s*['\"]([^'\"]+)['\"]\s*([,\)])"
    
    def replace_match(match):
        nonlocal replacements
        text = match.group(1)
        suffix = match.group(2)
        
        # Skip if contains $ (interpolation)
        if '$' in text:
            return match.group(0)
        
        # Look up key
        if text in value_to_key:
            key = value_to_key[text]
            replacements += 1
            return f"Text(AppLocalizations.of(context)!.{key}{suffix}"
        
        return match.group(0)
    
    content = re.sub(pattern, replace_match, content)
    
    if replacements > 0:
        # Add import if needed
        content = add_import_if_needed(content)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True, replacements
    
    return False, 0

def main():
    print("🔄 Auto-replacing hardcoded strings...\n")
    
    # Load ARB and build reverse map
    arb_pt = load_arb(ARB_PT_PATH)
    value_to_key = build_value_to_key_map(arb_pt)
    
    print(f"📚 Loaded {len(value_to_key)} translation entries\n")
    
    # Find all dart files
    dart_files = list(LIB_PATH.rglob("*.dart"))
    
    total_replacements = 0
    files_modified = 0
    
    for dart_file in dart_files:
        # Skip generated files
        if '.g.dart' in str(dart_file) or '.freezed.dart' in str(dart_file):
            continue
        
        modified, count = replace_hardcoded_strings(dart_file, value_to_key)
        
        if modified:
            files_modified += 1
            total_replacements += count
            rel_path = dart_file.relative_to(PROJECT_ROOT)
            print(f"  ✅ {rel_path}: {count} replacements")
    
    print(f"\n📊 Summary:")
    print(f"   Files modified: {files_modified}")
    print(f"   Total replacements: {total_replacements}")
    print(f"\n💡 Run 'flutter gen-l10n' to regenerate localizations")

if __name__ == "__main__":
    main()
