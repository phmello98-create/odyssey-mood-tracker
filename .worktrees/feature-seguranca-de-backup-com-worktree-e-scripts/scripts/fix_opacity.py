#!/usr/bin/env python3
"""
Script para substituir .withOpacity() por .withValues(alpha:) em arquivos Dart
Converte de API deprecated para API moderna do Flutter 3.27+
"""

import re
import sys
from pathlib import Path

def fix_opacity_in_file(filepath):
    """Substitui withOpacity por withValues(alpha:) em um arquivo"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Pattern: .withOpacity(0.5) -> .withValues(alpha: 0.5)
        # Captura números decimais e variáveis
        pattern = r'\.withOpacity\(([^)]+)\)'
        replacement = r'.withValues(alpha: \1)'
        
        content = re.sub(pattern, replacement, content)
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Erro ao processar {filepath}: {e}", file=sys.stderr)
        return False

def main():
    """Processa todos os arquivos .dart no projeto"""
    lib_path = Path(__file__).parent.parent / 'lib'
    
    if not lib_path.exists():
        print(f"Erro: Diretório {lib_path} não encontrado", file=sys.stderr)
        sys.exit(1)
    
    dart_files = list(lib_path.rglob('*.dart'))
    fixed_count = 0
    
    print(f"Processando {len(dart_files)} arquivos...")
    
    for dart_file in dart_files:
        if fix_opacity_in_file(dart_file):
            fixed_count += 1
            print(f"✓ {dart_file.relative_to(lib_path.parent)}")
    
    print(f"\n✅ {fixed_count} arquivos atualizados")
    print(f"📁 {len(dart_files) - fixed_count} arquivos sem alterações")

if __name__ == '__main__':
    main()
