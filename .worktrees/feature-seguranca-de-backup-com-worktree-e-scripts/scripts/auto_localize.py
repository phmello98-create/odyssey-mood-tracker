#!/usr/bin/env python3
"""
Auto-localization script for Flutter app.
Extracts hardcoded strings and converts them to use AppLocalizations.
"""

import os
import re
import json
import hashlib
from pathlib import Path
from typing import Dict, List, Tuple, Set

# Paths
PROJECT_ROOT = Path(__file__).parent.parent
LIB_PATH = PROJECT_ROOT / "lib" / "src"
ARB_PT_PATH = PROJECT_ROOT / "lib" / "src" / "localization" / "app_pt.arb"
ARB_EN_PATH = PROJECT_ROOT / "lib" / "src" / "localization" / "app_en.arb"

# Translations PT -> EN (comprehensive dictionary)
TRANSLATIONS = {
    # Common actions
    "Abrir": "Open",
    "Abrir Configurações": "Open Settings",
    "Adicionar": "Add",
    "Adicionar aos Favoritos": "Add to Favorites",
    "Adicionar Artigo": "Add Article",
    "Adicionar Tarefa": "Add Task",
    "Alterações não salvas": "Unsaved changes",
    "Apagar": "Delete",
    "Apagar Categoria?": "Delete Category?",
    "Apagar Projeto?": "Delete Project?",
    "Atualizar": "Update",
    "Atualizar Progresso": "Update Progress",
    "Busca em desenvolvimento": "Search in development",
    "Câmera": "Camera",
    "Cancelar": "Cancel",
    "Compartilhar": "Share",
    "Configurar": "Configure",
    "Copiar": "Copy",
    "Copiar Token": "Copy Token",
    "Criar": "Create",
    "Desconectar": "Disconnect",
    "Detalhes": "Details",
    "Edit": "Edit",
    "Editar": "Edit",
    "Editar Categoria": "Edit Category",
    "Editar perfil": "Edit profile",
    "Editar Perfil": "Edit Profile",
    "Editar Projeto": "Edit Project",
    "Editar registro": "Edit record",
    "Encerrar": "End",
    "Excluir": "Delete",
    "Fechar": "Close",
    "Galeria": "Gallery",
    "Importar": "Import",
    "Importar Backup": "Import Backup",
    "Limpar": "Clear",
    "Limpar filtros": "Clear filters",
    "Minimizar": "Minimize",
    "Ordenar por": "Sort by",
    "Remover": "Remove",
    "Restaurar": "Restore",
    "Restaurar Backup": "Restore Backup",
    "Sair": "Exit",
    "Salvar": "Save",
    "Salvar Artigo": "Save Article",
    "Salvar Frase": "Save Quote",
    "Salvar na Biblioteca": "Save to Library",
    "Salvar Nota": "Save Note",
    "Tentar Novamente": "Try Again",
    "Ver detalhes": "View details",
    "Ver Detalhes": "View Details",
    "Ver todas": "View all",
    
    # Confirmations and questions
    "Deseja apagar a categoria": "Do you want to delete the category",
    "Deseja excluir": "Do you want to delete",
    "Deseja sair da conta Google?": "Do you want to sign out of Google?",
    "Excluir frase?": "Delete quote?",
    "Excluir hábito?": "Delete habit?",
    "Excluir Livro?": "Delete Book?",
    "Excluir nota?": "Delete note?",
    "Excluir projeto": "Delete project",
    "Excluir tarefa?": "Delete task?",
    "Limpar dados?": "Clear data?",
    "Sair do Pomodoro?": "Exit Pomodoro?",
    "Tem certeza que deseja excluir": "Are you sure you want to delete",
    "Esta ação irá apagar todos os seus registros permanentemente.": "This action will permanently delete all your records.",
    "Esta ação não pode ser desfeita.": "This action cannot be undone.",
    "Você tem alterações não salvas. Deseja salvá-las?": "You have unsaved changes. Do you want to save them?",
    "O timer será pausado, mas seu progresso será mantido.": "The timer will be paused, but your progress will be kept.",
    
    # Success messages
    "Dados limpos com sucesso": "Data cleared successfully",
    "Frase salva com sucesso!": "Quote saved successfully!",
    "Nota salva com sucesso!": "Note saved successfully!",
    "Tarefa adicionada com sucesso!": "Task added successfully!",
    "Notificação enviada!": "Notification sent!",
    "Widgets restaurados para o padrão": "Widgets restored to default",
    
    # Labels and titles
    "Áreas de Desenvolvimento": "Development Areas",
    "Assinatura PRO Mensal": "Monthly PRO Subscription",
    "Atividade Semanal": "Weekly Activity",
    "Chave PIX": "PIX Key",
    "Citação do Dia": "Quote of the Day",
    "Compra PRO Vitalício": "Lifetime PRO Purchase",
    "conquistas desbloqueadas": "achievements unlocked",
    "Cor": "Color",
    "dias": "days",
    "Estatísticas de Leitura": "Reading Statistics",
    "FCM Token Debug": "FCM Token Debug",
    "Frase do Dia": "Quote of the Day",
    "Gênero Personalizado": "Custom Genre",
    "Habilidades": "Skills",
    "Hábitos do Dia": "Daily Habits",
    "Hierarquia de Maslow": "Maslow's Hierarchy",
    "Horário (opcional)": "Time (optional)",
    "Horários": "Schedules",
    "Ícone": "Icon",
    "Iniciar Timer": "Start Timer",
    "Leitura Atual": "Current Reading",
    "Lendo Agora": "Reading Now",
    "Livro não encontrado": "Book not found",
    "Marcar este livro como favorito": "Mark this book as favorite",
    "min": "min",
    "Missões Diárias": "Daily Missions",
    "Nenhuma nota ainda": "No notes yet",
    "Nenhuma tarefa para hoje!": "No tasks for today!",
    "Nenhum livro em leitura": "No book being read",
    "Nome": "Name",
    "Notas Rápidas": "Quick Notes",
    "Nova Categoria": "New Category",
    "Novo Projeto": "New Project",
    "Para Ler": "To Read",
    "Personalize a aparência do app": "Customize the app appearance",
    "Pomodoro": "Pomodoro",
    "PRO ATIVO": "PRO ACTIVE",
    "Renomear projeto": "Rename project",
    "Repetir em": "Repeat on",
    "Tarefas do Dia": "Daily Tasks",
    "Timer Demo": "Timer Demo",
    "Veja seus hábitos no calendário": "See your habits on calendar",
    "Widgets da Home": "Home Widgets",
    "Escolher Tema": "Choose Theme",
    "Ativar Teste": "Activate Test",
    "Filtrar por este projeto": "Filter by this project",
    
    # Error messages
    "Erro ao fazer login": "Login error",
    "Not enough data...": "Not enough data...",
    "Sem dados suficientes...": "Not enough data...",
    "Precisa de pelo menos 2 registros...": "Need at least 2 records...",
    
    # Other
    "Login com Facebook em breve! Use Google ou entre como visitante.": "Facebook login coming soon! Use Google or enter as guest.",
    "Seu companheiro de produtividade e bem-estar pessoal.": "Your personal productivity and wellness companion.",
    "Esta funcionalidade será integrada com a loja de apps. Por enquanto, você pode ativar o modo de teste.": "This feature will be integrated with the app store. For now, you can activate test mode.",
    "Copie a chave abaixo para fazer a transferência": "Copy the key below to make the transfer",
    "— Inspirado em Maslow": "— Inspired by Maslow",
    
    # Time periods
    "Week": "Week",
    "Month": "Month",
    "Year": "Year",
    "All": "All",
    "POPULAR": "POPULAR",
    
    # Emoji prefixed (keep emoji)
    "✅ Chave PIX copiada!": "✅ PIX Key copied!",
    "✅ Nota salva!": "✅ Note saved!",
    "✅ Token copiado para área de transferência!": "✅ Token copied to clipboard!",
    "🎉 PRO Mensal ativado! (modo teste - 30 dias)": "🎉 Monthly PRO activated! (test mode - 30 days)",
    "🎉 PRO Vitalício ativado! (modo teste)": "🎉 Lifetime PRO activated! (test mode)",
}

def generate_key(text: str) -> str:
    """Generate a camelCase key from text."""
    # Remove emojis and special chars
    clean = re.sub(r'[^\w\s]', '', text)
    clean = clean.strip()
    
    # Split into words
    words = clean.split()
    if not words:
        return f"str_{hashlib.md5(text.encode()).hexdigest()[:8]}"
    
    # Create camelCase
    key = words[0].lower()
    for word in words[1:]:
        key += word.capitalize()
    
    # Limit length
    if len(key) > 40:
        key = key[:40]
    
    return key

def load_arb(path: Path) -> Dict:
    """Load ARB file as dict."""
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_arb(path: Path, data: Dict):
    """Save dict to ARB file."""
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def find_hardcoded_strings(file_path: Path) -> List[Tuple[int, str, str]]:
    """Find Text() widgets with hardcoded strings."""
    results = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    # Pattern for Text('string') or Text("string")
    pattern = r"Text\(\s*['\"]([^'\"]+)['\"]"
    
    for i, line in enumerate(lines, 1):
        # Skip if already using AppLocalizations
        if 'AppLocalizations' in line or 'l10n.' in line:
            continue
        
        matches = re.findall(pattern, line)
        for match in matches:
            # Skip interpolated strings, single chars, numbers only
            if '$' in match or len(match) <= 1:
                continue
            if match.replace('.', '').replace(',', '').isdigit():
                continue
            # Skip if just emoji or symbols
            if re.match(r'^[\s\W]+$', match):
                continue
            
            results.append((i, match, line.strip()))
    
    return results

def get_translation(pt_text: str) -> str:
    """Get English translation for Portuguese text."""
    if pt_text in TRANSLATIONS:
        return TRANSLATIONS[pt_text]
    
    # Check for partial matches with parameters
    for pt, en in TRANSLATIONS.items():
        if pt in pt_text:
            return pt_text.replace(pt, en)
    
    # If no translation found, return original (will need manual translation)
    return f"[TRANSLATE] {pt_text}"

def main():
    print("🔍 Scanning for hardcoded strings...\n")
    
    # Load existing ARBs
    arb_pt = load_arb(ARB_PT_PATH)
    arb_en = load_arb(ARB_EN_PATH)
    
    # Track existing keys
    existing_keys = set(arb_pt.keys())
    existing_values_pt = {v for k, v in arb_pt.items() if not k.startswith('@')}
    
    # Find all dart files
    dart_files = list(LIB_PATH.rglob("*.dart"))
    
    all_strings = []
    files_with_hardcoded = []
    
    for dart_file in dart_files:
        # Skip generated files
        if '.g.dart' in str(dart_file) or '.freezed.dart' in str(dart_file):
            continue
        
        found = find_hardcoded_strings(dart_file)
        if found:
            files_with_hardcoded.append((dart_file, found))
            all_strings.extend([(dart_file, *f) for f in found])
    
    print(f"📁 Found {len(files_with_hardcoded)} files with hardcoded strings")
    print(f"📝 Total hardcoded strings: {len(all_strings)}\n")
    
    # Deduplicate strings
    unique_strings = {}
    for file_path, line_num, text, full_line in all_strings:
        if text not in unique_strings:
            unique_strings[text] = []
        unique_strings[text].append((file_path, line_num))
    
    print(f"🔤 Unique strings to translate: {len(unique_strings)}\n")
    
    # Generate new ARB entries
    new_entries_pt = {}
    new_entries_en = {}
    key_mapping = {}
    
    for text in unique_strings:
        # Skip if already in ARB
        if text in existing_values_pt:
            # Find existing key
            for k, v in arb_pt.items():
                if v == text and not k.startswith('@'):
                    key_mapping[text] = k
                    break
            continue
        
        # Generate key
        key = generate_key(text)
        
        # Ensure unique key
        original_key = key
        counter = 1
        while key in existing_keys or key in new_entries_pt:
            key = f"{original_key}{counter}"
            counter += 1
        
        # Get translation
        en_text = get_translation(text)
        
        new_entries_pt[key] = text
        new_entries_en[key] = en_text
        key_mapping[text] = key
        
        print(f"  ➕ {key}: \"{text[:50]}...\"" if len(text) > 50 else f"  ➕ {key}: \"{text}\"")
    
    print(f"\n📊 New entries to add: {len(new_entries_pt)}")
    
    if new_entries_pt:
        # Update ARB files
        arb_pt.update(new_entries_pt)
        arb_en.update(new_entries_en)
        
        save_arb(ARB_PT_PATH, arb_pt)
        save_arb(ARB_EN_PATH, arb_en)
        
        print(f"✅ Updated ARB files")
    
    # Generate replacement script
    print("\n📝 Generating replacement commands...\n")
    
    replacements_file = PROJECT_ROOT / "scripts" / "replacements.txt"
    with open(replacements_file, 'w', encoding='utf-8') as f:
        for text, locations in unique_strings.items():
            if text in key_mapping:
                key = key_mapping[text]
                f.write(f"# {text}\n")
                f.write(f"# Key: {key}\n")
                f.write(f"# Locations: {len(locations)}\n")
                for loc in locations:
                    f.write(f"#   {loc[0].relative_to(PROJECT_ROOT)}:{loc[1]}\n")
                f.write(f"OLD: Text('{text}')\n")
                f.write(f"NEW: Text(AppLocalizations.of(context)!.{key})\n\n")
    
    print(f"📄 Replacement guide saved to: {replacements_file}")
    
    # Summary by file
    print("\n📁 Files needing updates:")
    for file_path, found in sorted(files_with_hardcoded, key=lambda x: len(x[1]), reverse=True)[:20]:
        rel_path = file_path.relative_to(PROJECT_ROOT)
        print(f"  {len(found):3d} strings: {rel_path}")

if __name__ == "__main__":
    main()
