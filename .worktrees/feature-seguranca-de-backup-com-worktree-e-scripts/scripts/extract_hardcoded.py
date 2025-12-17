#!/usr/bin/env python3
"""
Script para extrair strings hardcoded e gerar chaves para ARB
"""
import re
import os
import json
from pathlib import Path
from collections import defaultdict

# Diretórios a processar
TARGET_DIRS = [
    'lib/src/features',
    'lib/src/utils',
]

def normalize_key(text):
    """Converte texto em uma chave camelCase válida"""
    # Remove emojis e caracteres especiais
    text = re.sub(r'[^\w\s\-áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ]', '', text)
    # Remove acentos
    replacements = {
        'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a',
        'é': 'e', 'ê': 'e',
        'í': 'i',
        'ó': 'o', 'ô': 'o', 'õ': 'o',
        'ú': 'u', 'ü': 'u',
        'ç': 'c',
        'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A',
        'É': 'E', 'Ê': 'E',
        'Í': 'I',
        'Ó': 'O', 'Ô': 'O', 'Õ': 'O',
        'Ú': 'U', 'Ü': 'U',
        'Ç': 'C',
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    
    # Divide em palavras
    words = text.strip().split()
    if not words:
        return None
    
    # camelCase
    key = words[0].lower()
    for word in words[1:]:
        if word:
            key += word.capitalize()
    
    return key

def is_portuguese(text):
    """Detecta se o texto é português (heurística simples)"""
    pt_chars = 'áàâãéêíóôõúçÁÀÂÃÉÊÍÓÔÕÚÇ'
    pt_words = ['de', 'da', 'do', 'em', 'para', 'com', 'sem', 'você', 'não', 'está', 'são']
    
    # Se tem caracteres portugueses, é PT
    if any(c in text for c in pt_chars):
        return True
    
    # Se tem palavras portuguesas comuns
    text_lower = text.lower()
    if any(word in text_lower for word in pt_words):
        return True
    
    return False

def extract_strings_from_file(filepath):
    """Extrai strings de um arquivo Dart"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"  ⚠️ Erro lendo {filepath}: {e}")
        return []
    
    # Ignora arquivos que já usam AppLocalizations
    if 'AppLocalizations.of(context)' in content:
        return []
    
    strings = []
    
    # Padrões para encontrar strings em Text()
    patterns = [
        r"Text\('([^']+)'\)",  # Text('...')
        r'Text\("([^"]+)"\)',  # Text("...")
        r"text:\s*'([^']+)'",  # text: '...'
        r'text:\s*"([^"]+)"',  # text: "..."
        r"title:\s*Text\('([^']+)'\)",  # title: Text('...')
        r'title:\s*Text\("([^"]+)"\)',  # title: Text("...")
        r"content:\s*Text\('([^']+)'\)",  # content: Text('...')
        r'content:\s*Text\("([^"]+)"\)',  # content: Text("...")
        r"label:\s*Text\('([^']+)'\)",  # label: Text('...')
        r'label:\s*Text\("([^"]+)"\)',  # label: Text("...")
    ]
    
    for pattern in patterns:
        matches = re.finditer(pattern, content)
        for match in matches:
            text = match.group(1)
            # Ignora strings vazias, variáveis, números, etc
            if not text or text.startswith('$') or text.isdigit() or len(text) < 2:
                continue
            # Ignora strings que são apenas símbolos
            if all(c in '.,!?;:-+=/\\|@#$%&*()[]{}' for c in text):
                continue
            strings.append(text)
    
    return strings

def main():
    print("🔍 Extraindo strings hardcoded...\n")
    
    all_strings = defaultdict(set)  # {string: {file1, file2, ...}}
    
    for target_dir in TARGET_DIRS:
        if not os.path.exists(target_dir):
            continue
        
        for root, dirs, files in os.walk(target_dir):
            for file in files:
                if file.endswith('.dart'):
                    filepath = os.path.join(root, file)
                    strings = extract_strings_from_file(filepath)
                    for s in strings:
                        all_strings[s].add(filepath)
    
    # Separa em PT e EN
    pt_strings = {}
    en_strings = {}
    
    for text, files in all_strings.items():
        key = normalize_key(text)
        if not key:
            continue
        
        # Evita colisões de chave
        original_key = key
        counter = 1
        while key in pt_strings or key in en_strings:
            key = f"{original_key}{counter}"
            counter += 1
        
        if is_portuguese(text):
            pt_strings[key] = {
                'text': text,
                'files': list(files)
            }
        else:
            en_strings[key] = {
                'text': text,
                'files': list(files)
            }
    
    # Salva resultado
    output = {
        'portuguese': pt_strings,
        'english': en_strings
    }
    
    with open('scripts/extracted_strings.json', 'w', encoding='utf-8') as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    
    print(f"✅ {len(pt_strings)} strings em português encontradas")
    print(f"✅ {len(en_strings)} strings em inglês encontradas")
    print(f"\n📄 Resultado salvo em: scripts/extracted_strings.json")
    
    # Mostra algumas amostras
    print("\n📝 Amostras de strings em português:")
    for i, (key, data) in enumerate(list(pt_strings.items())[:10]):
        print(f"  '{key}': '{data['text']}'")
    
    print("\n📝 Amostras de strings em inglês:")
    for i, (key, data) in enumerate(list(en_strings.items())[:10]):
        print(f"  '{key}': '{data['text']}'")

if __name__ == "__main__":
    main()
