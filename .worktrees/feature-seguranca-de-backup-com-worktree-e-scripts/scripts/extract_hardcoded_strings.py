#!/usr/bin/env python3
"""
Script para extrair strings hardcoded e adicionar aos ARB files
Uso: python3 extract_hardcoded_strings.py
"""

import os
import re
import json
from typing import Dict, List, Tuple, Set
from collections import defaultdict

# Padrões de strings hardcoded em português
PT_PATTERNS = [
    (r'Text\s*\(\s*["\']([^"\']*(?:ã|õ|ç|á|é|í|ó|ú|â|ê|ô|À|Á|Ã|Ç|É|Í|Ó|Ú)[^"\']*)["\']', 'Text'),
    (r'title:\s*["\']([^"\']*(?:ã|õ|ç|á|é|í|ó|ú|â|ê|ô|À|Á|Ã|Ç|É|Í|Ó|Ú)[^"\']*)["\']', 'title'),
    (r'label:\s*["\']([^"\']*(?:ã|õ|ç|á|é|í|ó|ú|â|ê|ô|À|Á|Ã|Ç|É|Í|Ó|Ú)[^"\']*)["\']', 'label'),
    (r'hintText:\s*["\']([^"\']*(?:ã|õ|ç|á|é|í|ó|ú|â|ê|ô|À|Á|Ã|Ç|É|Í|Ó|Ú)[^"\']*)["\']', 'hintText'),
    (r'errorText:\s*["\']([^"\']*(?:ã|õ|ç|á|é|í|ó|ú|â|ê|ô|À|Á|Ã|Ç|É|Í|Ó|Ú)[^"\']*)["\']', 'errorText'),
    (r'helperText:\s*["\']([^"\']*(?:ã|õ|ç|á|é|í|ó|ú|â|ê|ô|À|Á|Ã|Ç|É|Í|Ó|Ú)[^"\']*)["\']', 'helperText'),
    (r'message:\s*["\']([^"\']*(?:ã|õ|ç|á|é|í|ó|ú|â|ê|ô|À|Á|Ã|Ç|É|Í|Ó|Ú)[^"\']*)["\']', 'message'),
]

# Dicionário de traduções PT -> EN
TRANSLATIONS = {
    # Comum
    "Adicionar": "Add",
    "Editar": "Edit",
    "Excluir": "Delete",
    "Salvar": "Save",
    "Cancelar": "Cancel",
    "Confirmar": "Confirm",
    "Continuar": "Continue",
    "Voltar": "Back",
    "Próximo": "Next",
    "Anterior": "Previous",
    "Concluir": "Complete",
    "Buscar": "Search",
    "Filtrar": "Filter",
    "Ordenar": "Sort",
    "Configurações": "Settings",
    "Estatísticas": "Statistics",
    
    # Diary/Diário
    "Diário": "Diary",
    "entrada": "entry",
    "entradas": "entries",
    "Título": "Title",
    "opcional": "optional",
    "Como você está se sentindo": "How are you feeling",
    "Descartar alterações": "Discard changes",
    "Você tem alterações não salvas": "You have unsaved changes",
    "Entrada excluída": "Entry deleted",
    "Tem certeza que deseja excluir": "Are you sure you want to delete",
    "Esta ação não pode ser desfeita": "This action cannot be undone",
    "Toque para começar a escrever": "Tap to start writing",
    "Buscar no Diário": "Search in Diary",
    "Distribuição de Sentimentos": "Feeling Distribution",
    "Frequência de Escrita": "Writing Frequency",
    "Visão Geral": "Overview",
    "Média Palavras": "Average Words",
    "Seu Diário": "Your Diary",
    "Ordem alfabética": "Alphabetical order",
    "Calendário": "Calendar",
    "Dicas para começar": "Tips to get started",
    
    # Hábitos
    "Hábitos": "Habits",
    "Calendário de Hábitos": "Habits Calendar",
    "Nenhum hábito completado": "No habits completed",
    "Comece sua Jornada de Hábitos": "Start Your Habits Journey",
    "Este mês": "This month",
    "Criar hábito": "Create habit",
    "Nenhum hábito para este dia": "No habits for this day",
    
    # Home
    "concluídas": "completed",
    "Nível": "Level",
    "Horário": "Time",
    "Ver histórico": "View history",
    "Como você está": "How are you",
    "Ações Rápidas": "Quick Actions",
    "Nota Rápida": "Quick Note",
    "Escreva uma nota rápida": "Write a quick note",
    "Sessões de Foco": "Focus Sessions",
    
    # Auth
    "Não se preocupe": "Don't worry",
    "Digite seu email": "Enter your email",
    "Enviamos um link": "We sent a link",
    "Preencha os dados": "Fill in the data",
    "Mínimo 6 caracteres": "Minimum 6 characters",
    "Erro ao verificar": "Error verifying",
    "Por favor, não feche o aplicativo": "Please don't close the app",
    "Faça login": "Log in",
    "Sincronização indisponível": "Sync unavailable",
    
    # Analytics
    "Próxima conquista": "Next achievement",
    "sessões": "sessions",
    "Dias difíceis": "Difficult days",
    "mais produtivo": "more productive",
    "bom humor": "good mood",
    
    # Outros
    "O que você esteve fazendo": "What have you been doing",
    "Seus Dados": "Your Data",
    "Última atualização": "Last updated",
    "Inspiração do dia": "Inspiration of the day",
    "Formato legível": "Readable format",
    "áreas": "areas",
    "Nível Médio": "Average Level",
    "Nível máximo": "Max level",
    "Você alcançou o nível": "You reached level",
    "Novo título desbloqueado": "New title unlocked",
}

def generate_key_from_text(text: str) -> str:
    """Gera uma key camelCase a partir do texto"""
    # Remove pontuação
    text = re.sub(r'[^\w\s]', '', text)
    # Split em palavras
    words = text.split()
    if not words:
        return ""
    # Primeira palavra lowercase, resto capitalize
    key = words[0].lower()
    for word in words[1:]:
        key += word.capitalize()
    return key

def translate_to_english(pt_text: str) -> str:
    """Traduz texto PT para EN"""
    en_text = pt_text
    for pt, en in TRANSLATIONS.items():
        en_text = en_text.replace(pt, en)
    return en_text

def extract_hardcoded_strings() -> Dict[str, List[Tuple[str, str]]]:
    """Extrai strings hardcoded de arquivos Dart"""
    results = defaultdict(list)
    
    for root, dirs, files in os.walk('lib'):
        # Ignorar arquivos gerados
        if any(skip in root for skip in ['generated', '.freezed.', '.g.', 'localization']):
            continue
            
        for file in files:
            if not file.endswith('.dart'):
                continue
                
            filepath = os.path.join(root, file)
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Procurar por cada padrão
                for pattern, context in PT_PATTERNS:
                    matches = re.findall(pattern, content)
                    for match in matches:
                        if len(match) > 2:  # Ignorar strings muito curtas
                            results[filepath].append((match, context))
                            
            except Exception as e:
                print(f"Erro ao ler {filepath}: {e}")
    
    return results

def main():
    print("🔍 EXTRAINDO STRINGS HARDCODED...\n")
    
    # Extrair strings
    hardcoded = extract_hardcoded_strings()
    
    if not hardcoded:
        print("✅ Nenhuma string hardcoded encontrada!")
        return
    
    # Ler ARB files
    with open('lib/src/localization/app_pt.arb', 'r', encoding='utf-8') as f:
        pt_data = json.load(f)
    with open('lib/src/localization/app_en.arb', 'r', encoding='utf-8') as f:
        en_data = json.load(f)
    
    pt_keys = {k for k in pt_data.keys() if not k.startswith('@')}
    
    # Coletar todas as strings únicas
    all_strings = set()
    for strings in hardcoded.values():
        for string, _ in strings:
            all_strings.add(string)
    
    print(f"📊 Encontradas {len(all_strings)} strings únicas em {len(hardcoded)} arquivos")
    print(f"\n🔹 Primeiras 20 strings:\n")
    
    new_translations = {}
    
    for i, string in enumerate(sorted(list(all_strings))[:20], 1):
        # Verificar se já existe nos ARBs
        if string in pt_data.values():
            print(f"{i}. ✅ \"{string[:50]}\" (já existe)")
            continue
        
        # Gerar key e tradução
        key = generate_key_from_text(string)
        if not key or key in pt_keys:
            # Adicionar sufixo se key já existe
            key = f"{key}Hardcoded{i}"
        
        en_translation = translate_to_english(string)
        
        new_translations[key] = {
            'pt': string,
            'en': en_translation
        }
        
        print(f"{i}. 🆕 \"{string[:40]}\"")
        print(f"   Key: {key}")
        print(f"   EN: \"{en_translation[:40]}\"")
    
    if len(all_strings) > 20:
        print(f"\n... e mais {len(all_strings) - 20} strings")
    
    # Salvar relatório detalhado
    with open('/tmp/hardcoded_report_detailed.txt', 'w', encoding='utf-8') as f:
        f.write("RELATÓRIO DETALHADO - STRINGS HARDCODED\n")
        f.write("=" * 70 + "\n\n")
        
        for filepath, strings in sorted(hardcoded.items()):
            f.write(f"\n📄 {filepath}\n")
            for string, context in strings:
                f.write(f"   [{context}] {string}\n")
        
        f.write(f"\n\n" + "=" * 70 + "\n")
        f.write(f"TOTAL: {len(all_strings)} strings únicas\n")
    
    print(f"\n✅ Relatório salvo em /tmp/hardcoded_report_detailed.txt")
    print(f"\n⚠️  RECOMENDAÇÃO:")
    print(f"   1. Revisar manualmente as traduções geradas")
    print(f"   2. Adicionar aos ARB files")
    print(f"   3. Substituir strings hardcoded por AppLocalizations.of(context)")

if __name__ == '__main__':
    main()
