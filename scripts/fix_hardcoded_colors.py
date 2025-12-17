#!/usr/bin/env python3
"""
Script para encontrar e sugerir substituições de cores hardcoded em Dart/Flutter.
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# Mapeamento de cores hardcoded para substituições usando Theme
COLOR_REPLACEMENTS = {
    # Cores que devem usar o tema
    r'Colors\.white(?!\d)': 'Theme.of(context).colorScheme.onPrimary',
    r'Colors\.white70': 'Theme.of(context).colorScheme.onSurface.withOpacity(0.7)',
    r'Colors\.white60': 'Theme.of(context).colorScheme.onSurface.withOpacity(0.6)',
    r'Colors\.white54': 'Theme.of(context).colorScheme.onSurfaceVariant',
    r'Colors\.white38': 'Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)',
    r'Colors\.white24': 'Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)',
    r'Colors\.white12': 'Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2)',
    r'Colors\.white10': 'Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.15)',
    r'Colors\.black(?!\d)': 'Theme.of(context).colorScheme.onSurface',
    r'Colors\.black87': 'Theme.of(context).colorScheme.onSurface.withOpacity(0.87)',
    r'Colors\.black54': 'Theme.of(context).colorScheme.onSurfaceVariant',
    r'Colors\.black38': 'Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)',
    r'Colors\.black26': 'Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)',
    r'Colors\.black12': 'Theme.of(context).colorScheme.outline.withOpacity(0.2)',
    r'Colors\.grey': 'Theme.of(context).colorScheme.outline',
    r'Colors\.grey\[(\d+)\]': 'Theme.of(context).colorScheme.surfaceContainerHighest',
}

# Padrões a IGNORAR (onde cores absolutas são aceitáveis)
IGNORE_PATTERNS = [
    r'// ignore-hardcode',  # Comentário para ignorar
    r'\.withOpacity\(',  # Já está usando withOpacity em sequência
    r'LinearGradient\(',  # Gradientes com cores específicas
    r'RadialGradient\(',
    r'BoxShadow\(',  # Sombras geralmente usam preto
    r'color:\s*Colors\.(orange|green|red|blue|amber|cyan|purple|pink|teal)',  # Cores semânticas
]

# Arquivos específicos a ignorar
IGNORE_FILES = [
    'app_theme.dart',
    'app_themes.dart',
    'constants.dart',
]


def find_dart_files(directory: str) -> List[Path]:
    """Encontra todos os arquivos .dart no diretório."""
    dart_files = []
    for root, dirs, files in os.walk(directory):
        # Ignorar diretórios de build e gerados
        dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'build', '.git', 'generated']]
        for file in files:
            if file.endswith('.dart') and file not in IGNORE_FILES:
                dart_files.append(Path(root) / file)
    return dart_files


def should_ignore_line(line: str) -> bool:
    """Verifica se a linha deve ser ignorada."""
    for pattern in IGNORE_PATTERNS:
        if re.search(pattern, line):
            return True
    return False


def find_hardcoded_colors(file_path: Path) -> List[Tuple[int, str, str]]:
    """Encontra cores hardcoded em um arquivo."""
    issues = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        for i, line in enumerate(lines, 1):
            # Ignorar linhas com padrões aceitáveis
            if should_ignore_line(line):
                continue
            
            for pattern in COLOR_REPLACEMENTS.keys():
                if re.search(pattern, line):
                    issues.append((i, line.strip(), pattern))
    except Exception as e:
        print(f"Erro ao ler {file_path}: {e}")
    
    return issues


def replace_colors_in_file(file_path: Path, dry_run: bool = True) -> int:
    """Substitui cores hardcoded em um arquivo."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        replacements_made = 0
        
        for pattern, replacement in COLOR_REPLACEMENTS.items():
            # Contar substituições
            matches = re.findall(pattern, content)
            if matches:
                replacements_made += len(matches)
                if not dry_run:
                    content = re.sub(pattern, replacement, content)
        
        if replacements_made > 0 and not dry_run:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
        
        return replacements_made
    except Exception as e:
        print(f"Erro ao processar {file_path}: {e}")
        return 0


def main():
    if len(sys.argv) < 2:
        print("Uso: python fix_hardcoded_colors.py <diretório> [--fix]")
        print("  --fix: Aplica as correções (sem isso, apenas mostra o que seria alterado)")
        sys.exit(1)
    
    directory = sys.argv[1]
    dry_run = '--fix' not in sys.argv
    
    if dry_run:
        print("=== MODO DE ANÁLISE (use --fix para aplicar) ===\n")
    else:
        print("=== APLICANDO CORREÇÕES ===\n")
    
    dart_files = find_dart_files(directory)
    print(f"Encontrados {len(dart_files)} arquivos .dart\n")
    
    total_issues = 0
    files_with_issues = 0
    
    for file_path in dart_files:
        issues = find_hardcoded_colors(file_path)
        if issues:
            files_with_issues += 1
            total_issues += len(issues)
            
            rel_path = file_path.relative_to(directory)
            print(f"\n📄 {rel_path} ({len(issues)} problemas)")
            
            for line_num, line_content, pattern in issues[:5]:  # Mostrar primeiros 5
                print(f"  L{line_num}: {line_content[:80]}...")
            
            if len(issues) > 5:
                print(f"  ... e mais {len(issues) - 5} problemas")
            
            if not dry_run:
                replaced = replace_colors_in_file(file_path, dry_run=False)
                print(f"  ✅ {replaced} substituições aplicadas")
    
    print(f"\n{'='*50}")
    print(f"Total: {total_issues} cores hardcoded em {files_with_issues} arquivos")
    
    if dry_run and total_issues > 0:
        print("\n💡 Execute com --fix para aplicar as correções automaticamente")


if __name__ == '__main__':
    main()
