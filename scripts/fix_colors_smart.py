#!/usr/bin/env python3
"""
Script inteligente para corrigir cores hardcoded em Flutter/Dart.
Analisa o contexto antes de substituir.
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple

# Arquivos que não devem ser alterados
SKIP_FILES = [
    'app_theme.dart',
    'app_themes.dart', 
    'constants.dart',
    'login_screen.dart',  # Tem fundo escuro fixo com imagem
    'splash_screen.dart',  # Tem fundo escuro fixo
]

# Contextos onde Colors.white é aceitável (dentro de elementos com fundo colorido)
ACCEPTABLE_WHITE_CONTEXTS = [
    r'gradient[: ]',  # Dentro de gradientes coloridos
    r'backgroundColor:\s*[A-Za-z]+Colors\.',  # Em botões com cor de fundo
    r'color:\s*(Colors\.(purple|blue|red|green|amber|orange|cyan|pink|teal|indigo)|UltravioletColors)',
    r'FloatingActionButton',
    r'ElevatedButton\.styleFrom',
    r'foregroundColor.*primary',
]

def process_file(filepath: Path) -> Tuple[str, int]:
    """Processa um arquivo e retorna o conteúdo corrigido e número de mudanças."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    changes = 0
    
    # Substituições simples que sempre são seguras
    replacements = [
        # Substituições seguras para todos os contextos
        (r'Colors\.black12', 'Theme.of(context).colorScheme.outline.withOpacity(0.12)'),
        (r'Colors\.black26', 'Theme.of(context).colorScheme.outline.withOpacity(0.26)'),
        
        # Cores de texto que devem adaptar
        (r'color: Colors\.black87(?!,)', 'color: Theme.of(context).colorScheme.onSurface'),
        (r'color: Colors\.black54(?!,)', 'color: Theme.of(context).colorScheme.onSurfaceVariant'),
        
        # Grey em backgrounds
        (r'Colors\.grey\[(\d+)\]', 'Theme.of(context).colorScheme.surfaceContainerHighest'),
        (r'backgroundColor: Colors\.grey(?!\[)', 'backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest'),
    ]
    
    for pattern, replacement in replacements:
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            changes += len(re.findall(pattern, content))
            content = new_content
    
    return content, changes


def process_home_screen(filepath: Path) -> Tuple[str, int]:
    """Processamento especial para home_screen.dart"""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    changes = 0
    new_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        modified = False
        
        # Verificar se está em um contexto onde white é aceitável
        context_start = max(0, i - 5)
        context = ''.join(lines[context_start:i+1])
        
        is_in_gradient = 'LinearGradient' in context or 'RadialGradient' in context
        is_in_colored_container = re.search(r'color: (Colors\.(purple|blue|red|green)|UltravioletColors)', context)
        is_in_quote_widget = '_buildDailyQuoteWidget' in context
        
        # Se não estiver em contexto especial, substituir
        if not (is_in_gradient or is_in_colored_container or is_in_quote_widget):
            # Colors.white70 -> onSurface com opacidade
            if 'Colors.white70' in line:
                line = line.replace('Colors.white70', 'Theme.of(context).colorScheme.onSurface.withOpacity(0.7)')
                changes += 1
                modified = True
            
            # Colors.white54 -> onSurfaceVariant
            if 'Colors.white54' in line:
                line = line.replace('Colors.white54', 'Theme.of(context).colorScheme.onSurfaceVariant')
                changes += 1
                modified = True
            
            # Colors.white38 -> onSurfaceVariant com opacidade  
            if 'Colors.white38' in line:
                line = line.replace('Colors.white38', 'Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)')
                changes += 1
                modified = True
            
            # Colors.white24 -> outline com opacidade
            if 'Colors.white24' in line:
                line = line.replace('Colors.white24', 'Theme.of(context).colorScheme.outline.withOpacity(0.4)')
                changes += 1
                modified = True
        
        new_lines.append(line)
        i += 1
    
    return ''.join(new_lines), changes


def main():
    if len(sys.argv) < 2:
        print("Uso: python fix_colors_smart.py <diretório> [--fix]")
        sys.exit(1)
    
    directory = sys.argv[1]
    dry_run = '--fix' not in sys.argv
    
    print(f"{'=== ANÁLISE ===' if dry_run else '=== APLICANDO ==='}\n")
    
    # Encontrar arquivos
    dart_files = []
    for root, dirs, files in os.walk(directory):
        dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'build', '.git']]
        for f in files:
            if f.endswith('.dart') and f not in SKIP_FILES:
                dart_files.append(Path(root) / f)
    
    total_changes = 0
    
    for filepath in dart_files:
        # Usar processamento especial para home_screen
        if filepath.name == 'home_screen.dart':
            new_content, changes = process_home_screen(filepath)
        else:
            new_content, changes = process_file(filepath)
        
        if changes > 0:
            rel_path = filepath.relative_to(directory)
            print(f"📄 {rel_path}: {changes} correções")
            total_changes += changes
            
            if not dry_run:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
    
    print(f"\n{'='*40}")
    print(f"Total: {total_changes} correções {'(simuladas)' if dry_run else 'aplicadas'}")
    
    if dry_run:
        print("\n💡 Use --fix para aplicar")


if __name__ == '__main__':
    main()
