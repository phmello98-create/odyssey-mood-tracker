#!/usr/bin/env python3
"""
Script para substituir strings hardcoded por chamadas AppLocalizations
"""
import re
import os
import json

# Carrega o mapeamento de strings extraídas
with open('scripts/extracted_strings.json', 'r', encoding='utf-8') as f:
    extracted = json.load(f)

# Cria mapeamento: texto -> chave
text_to_key = {}
for key, data in extracted['portuguese'].items():
    # Ignora chaves problemáticas
    if any(bad in key for bad in ['_all', '_duration', '_getfiltered', 'Minutes', 'erroAo']):
        continue
    text_to_key[data['text']] = key

for key, data in extracted['english'].items():
    # Ignora chaves problemáticas
    if any(bad in key for bad in ['_all', '_duration', '_getfiltered', 'Minutes', 'erroAo']):
        continue
    text_to_key[data['text']] = key

def add_import_if_needed(content, filepath):
    """Adiciona import do AppLocalizations se necessário"""
    import_line = "import 'package:odyssey/src/localization/app_localizations.dart';"
    
    # Verifica se já tem o import
    if 'app_localizations.dart' in content:
        return content
    
    # Procura a última linha de import
    lines = content.split('\n')
    last_import_idx = -1
    
    for i, line in enumerate(lines):
        if line.strip().startswith("import '") or line.strip().startswith('import "'):
            last_import_idx = i
    
    if last_import_idx >= 0:
        # Insere após o último import
        lines.insert(last_import_idx + 1, import_line)
        return '\n'.join(lines)
    
    # Se não encontrou imports, adiciona no início após package declaration
    if lines and lines[0].strip().startswith('//'):
        lines.insert(1, import_line)
    else:
        lines.insert(0, import_line)
    
    return '\n'.join(lines)

def replace_in_file(filepath, text_to_key):
    """Substitui strings hardcoded em um arquivo"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"  ⚠️ Erro lendo {filepath}: {e}")
        return 0
    
    original_content = content
    replacements = 0
    
    # Para cada string que encontramos
    for text, key in text_to_key.items():
        # Escape caracteres especiais para regex
        escaped_text = re.escape(text)
        
        # Padrões de substituição
        patterns = [
            (f"Text\\('{escaped_text}'\\)", f"Text(AppLocalizations.of(context)!.{key})"),
            (f'Text\\("{escaped_text}"\\)', f"Text(AppLocalizations.of(context)!.{key})"),
            (f"title:\\s*Text\\('{escaped_text}'\\)", f"title: Text(AppLocalizations.of(context)!.{key})"),
            (f'title:\\s*Text\\("{escaped_text}"\\)', f"title: Text(AppLocalizations.of(context)!.{key})"),
            (f"content:\\s*Text\\('{escaped_text}'\\)", f"content: Text(AppLocalizations.of(context)!.{key})"),
            (f'content:\\s*Text\\("{escaped_text}"\\)', f"content: Text(AppLocalizations.of(context)!.{key})"),
            (f"label:\\s*Text\\('{escaped_text}'\\)", f"label: Text(AppLocalizations.of(context)!.{key})"),
            (f'label:\\s*Text\\("{escaped_text}"\\)', f"label: Text(AppLocalizations.of(context)!.{key})"),
            (f"const Text\\('{escaped_text}'\\)", f"Text(AppLocalizations.of(context)!.{key})"),
            (f'const Text\\("{escaped_text}"\\)', f"Text(AppLocalizations.of(context)!.{key})"),
        ]
        
        for pattern, replacement in patterns:
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                replacements += content.count(pattern)
                content = new_content
    
    # Se houve mudanças, adiciona import e salva
    if content != original_content:
        content = add_import_if_needed(content, filepath)
        
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return replacements
        except Exception as e:
            print(f"  ⚠️ Erro escrevendo {filepath}: {e}")
            return 0
    
    return 0

def main():
    print("🔄 Substituindo strings hardcoded por AppLocalizations...\n")
    
    total_replacements = 0
    files_changed = 0
    
    # Processa cada arquivo mencionado no extracted_strings.json
    all_files = set()
    for category in extracted.values():
        for data in category.values():
            all_files.update(data['files'])
    
    for filepath in sorted(all_files):
        if not os.path.exists(filepath):
            continue
        
        replacements = replace_in_file(filepath, text_to_key)
        if replacements > 0:
            print(f"  ✅ {filepath}: {replacements} substituições")
            total_replacements += replacements
            files_changed += 1
    
    print(f"\n📊 Total: {total_replacements} substituições em {files_changed} arquivos")
    print("🎯 Próximo passo: /home/agyspc1/flutter/bin/flutter analyze")

if __name__ == "__main__":
    main()
