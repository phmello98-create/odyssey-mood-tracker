#!/usr/bin/env python3
"""
Script para substituir strings hardcoded por AppLocalizations
"""
import re
import os
import glob

# Mapeamento de strings PT -> chave l10n
REPLACEMENTS = {
    # Humor/Mood
    "'Como você está se sentindo?'": "AppLocalizations.of(context)!.howAreYouFeeling",
    "'Registrar Humor'": "AppLocalizations.of(context)!.recordMood",
    "'Registrar humor'": "AppLocalizations.of(context)!.recordMood",
    "'Humor não registrado'": "AppLocalizations.of(context)!.moodNotRecorded",
    "'Registrar Agora'": "AppLocalizations.of(context)!.recordNow",
    
    # Saudações
    "'Bom dia'": "AppLocalizations.of(context)!.goodMorning",
    "'Boa tarde'": "AppLocalizations.of(context)!.goodAfternoon",
    "'Boa noite'": "AppLocalizations.of(context)!.goodEvening",
    "'Bem-vindo de volta!'": "AppLocalizations.of(context)!.welcomeBack",
    
    # Navegação/Seções
    "'Biblioteca'": "AppLocalizations.of(context)!.library",
    "'Notas'": "AppLocalizations.of(context)!.notes",
    "'Tarefas'": "AppLocalizations.of(context)!.tasks",
    "'Hábitos'": "AppLocalizations.of(context)!.habits",
    "'Timer'": "AppLocalizations.of(context)!.timer",
    "'Calendário'": "AppLocalizations.of(context)!.calendar",
    "'Agenda'": "AppLocalizations.of(context)!.agenda",
    "'Configurações'": "AppLocalizations.of(context)!.settings",
    "'Notícias'": "AppLocalizations.of(context)!.news",
    "'Análises'": "AppLocalizations.of(context)!.analytics",
    "'Home'": "AppLocalizations.of(context)!.home",
    "'Perfil'": "AppLocalizations.of(context)!.profile",
    
    # Timer/Pomodoro
    "'Foco'": "AppLocalizations.of(context)!.focus",
    "'Pausa'": "AppLocalizations.of(context)!.breakTime",
    "'Pausa Curta'": "AppLocalizations.of(context)!.shortBreak",
    "'Pausa Longa'": "AppLocalizations.of(context)!.longBreak",
    "'Iniciar'": "AppLocalizations.of(context)!.start",
    "'Pausar'": "AppLocalizations.of(context)!.pause",
    "'Parar'": "AppLocalizations.of(context)!.stop",
    "'Reiniciar'": "AppLocalizations.of(context)!.reset",
    "'Retomar'": "AppLocalizations.of(context)!.resume",
    "'Timer Ativo'": "AppLocalizations.of(context)!.timerActive",
    "'em background'": "AppLocalizations.of(context)!.inBackground",
    "'Sessão'": "AppLocalizations.of(context)!.session",
    "'Sessões'": "AppLocalizations.of(context)!.sessions",
    
    # Tarefas
    "'Nova Tarefa'": "AppLocalizations.of(context)!.newTask",
    "'Editar Tarefa'": "AppLocalizations.of(context)!.editTask",
    "'Criar Tarefa'": "AppLocalizations.of(context)!.createTask",
    "'Minhas Tarefas'": "AppLocalizations.of(context)!.myTasks",
    "'O que você precisa fazer?'": "AppLocalizations.of(context)!.taskTitle",
    "'Nenhuma tarefa pendente'": "AppLocalizations.of(context)!.noTasksPending",
    "'Nenhuma tarefa concluída'": "AppLocalizations.of(context)!.noTasksCompleted",
    "'Adicione uma nova tarefa para começar'": "AppLocalizations.of(context)!.addTaskToStart",
    "'Complete suas tarefas para vê-las aqui'": "AppLocalizations.of(context)!.completeTasksToSee",
    "'Prioridade'": "AppLocalizations.of(context)!.priority",
    "'Alta'": "AppLocalizations.of(context)!.priorityHigh",
    "'Média'": "AppLocalizations.of(context)!.priorityMedium",
    "'Baixa'": "AppLocalizations.of(context)!.priorityLow",
    "'Categoria'": "AppLocalizations.of(context)!.category",
    "'Todas'": "AppLocalizations.of(context)!.all",
    "'Hoje'": "AppLocalizations.of(context)!.today",
    "'Esta Semana'": "AppLocalizations.of(context)!.thisWeek",
    "'Atrasadas'": "AppLocalizations.of(context)!.overdue",
    "'Pendentes'": "AppLocalizations.of(context)!.pending",
    "'Concluídas'": "AppLocalizations.of(context)!.completed",
    
    # Notas
    "'Nova Nota'": "AppLocalizations.of(context)!.newNote",
    "'Editar Nota'": "AppLocalizations.of(context)!.editNote",
    "'Minhas Notas'": "AppLocalizations.of(context)!.myNotes",
    "'Nenhuma nota'": "AppLocalizations.of(context)!.noNotes",
    "'Nota rápida'": "AppLocalizations.of(context)!.quickNote",
    
    # Livros
    "'Adicionar Livro'": "AppLocalizations.of(context)!.addBook",
    "'Editar Livro'": "AppLocalizations.of(context)!.editBook",
    "'Meus Livros'": "AppLocalizations.of(context)!.myBooks",
    "'Nenhum livro'": "AppLocalizations.of(context)!.noBooks",
    "'Lendo'": "AppLocalizations.of(context)!.reading",
    "'Lido'": "AppLocalizations.of(context)!.read",
    "'Quero Ler'": "AppLocalizations.of(context)!.toRead",
    "'Abandonado'": "AppLocalizations.of(context)!.abandoned",
    "'Autor'": "AppLocalizations.of(context)!.author",
    "'Páginas'": "AppLocalizations.of(context)!.pages",
    "'Avaliação'": "AppLocalizations.of(context)!.rating",
    "'Gênero'": "AppLocalizations.of(context)!.genre",
    
    # Hábitos
    "'Novo Hábito'": "AppLocalizations.of(context)!.newHabit",
    "'Editar Hábito'": "AppLocalizations.of(context)!.editHabit",
    "'Criar Hábito'": "AppLocalizations.of(context)!.createHabit",
    "'Sequência'": "AppLocalizations.of(context)!.streak",
    "'Lembrete'": "AppLocalizations.of(context)!.reminder",
    "'Lembretes'": "AppLocalizations.of(context)!.reminders",
    "'Frequência'": "AppLocalizations.of(context)!.frequency",
    
    # Ações comuns
    "'Salvar'": "AppLocalizations.of(context)!.save",
    "'Cancelar'": "AppLocalizations.of(context)!.cancel",
    "'Excluir'": "AppLocalizations.of(context)!.delete",
    "'Editar'": "AppLocalizations.of(context)!.edit",
    "'Adicionar'": "AppLocalizations.of(context)!.add",
    "'Confirmar'": "AppLocalizations.of(context)!.confirm",
    "'Fechar'": "AppLocalizations.of(context)!.close",
    "'Voltar'": "AppLocalizations.of(context)!.back",
    "'Continuar'": "AppLocalizations.of(context)!.continue_",
    "'Pular'": "AppLocalizations.of(context)!.skip_",
    "'Próximo'": "AppLocalizations.of(context)!.next",
    "'Anterior'": "AppLocalizations.of(context)!.previous",
    "'Sim'": "AppLocalizations.of(context)!.yes",
    "'Não'": "AppLocalizations.of(context)!.no",
    "'OK'": "AppLocalizations.of(context)!.ok",
    "'Concluído'": "AppLocalizations.of(context)!.done",
    "'Salvar Alterações'": "AppLocalizations.of(context)!.saveChanges",
    "'Descartar'": "AppLocalizations.of(context)!.discard",
    "'Remover'": "AppLocalizations.of(context)!.remove",
    "'Buscar'": "AppLocalizations.of(context)!.search",
    "'Pesquisar...'": "AppLocalizations.of(context)!.search",
    "'Ver todos'": "AppLocalizations.of(context)!.seeAll",
    "'Ver mais'": "AppLocalizations.of(context)!.seeMore",
    "'Ver menos'": "AppLocalizations.of(context)!.seeLess",
    
    # Categorias
    "'Pessoal'": "AppLocalizations.of(context)!.categoryPersonal",
    "'Trabalho'": "AppLocalizations.of(context)!.categoryWork",
    "'Estudos'": "AppLocalizations.of(context)!.categoryStudies",
    "'Saúde'": "AppLocalizations.of(context)!.categoryHealth",
    "'Casa'": "AppLocalizations.of(context)!.categoryHome",
    "'Outros'": "AppLocalizations.of(context)!.categoryOther",
    
    # Status/Mensagens
    "'Carregando...'": "AppLocalizations.of(context)!.loading",
    "'Carregando'": "AppLocalizations.of(context)!.loading",
    "'Erro'": "AppLocalizations.of(context)!.errorOccurred",
    "'Tente novamente'": "AppLocalizations.of(context)!.tryAgain",
    "'Sem dados'": "AppLocalizations.of(context)!.noData",
    
    # Títulos/Labels
    "'Título'": "AppLocalizations.of(context)!.title",
    "'Descrição'": "AppLocalizations.of(context)!.description",
    "'Data'": "AppLocalizations.of(context)!.date",
    "'Hora'": "AppLocalizations.of(context)!.time",
    "'Mais'": "AppLocalizations.of(context)!.more",
    "'Histórico'": "AppLocalizations.of(context)!.history",
    "'Estatísticas'": "AppLocalizations.of(context)!.statistics",
    "'Progresso'": "AppLocalizations.of(context)!.progress",
    "'Nível'": "AppLocalizations.of(context)!.level",
    "'Conquistas'": "AppLocalizations.of(context)!.achievements",
    
    # Backup/Settings
    "'Backup'": "AppLocalizations.of(context)!.backup",
    "'Restaurar'": "AppLocalizations.of(context)!.restore",
    "'Tema'": "AppLocalizations.of(context)!.theme",
    "'Idioma'": "AppLocalizations.of(context)!.language",
    "'Notificações'": "AppLocalizations.of(context)!.notifications",
    "'Sons'": "AppLocalizations.of(context)!.sounds",
    "'Sobre'": "AppLocalizations.of(context)!.about",
    "'Versão'": "AppLocalizations.of(context)!.version",
    "'Ajuda'": "AppLocalizations.of(context)!.help",
}

# Arquivos a processar
TARGET_DIRS = [
    'lib/src/features/home/presentation',
    'lib/src/features/mood_records/presentation',
    'lib/src/features/habits/presentation',
    'lib/src/features/notes/presentation',
    'lib/src/features/library/presentation',
    'lib/src/features/time_tracker/presentation',
    'lib/src/features/calendar/presentation',
    'lib/src/features/log/presentation',
    'lib/src/features/analytics/presentation',
    'lib/src/features/gamification/presentation',
]

IMPORT_LINE = "import 'package:odyssey/src/localization/app_localizations.dart';"

def process_file(filepath):
    """Processa um arquivo Dart e substitui strings hardcoded"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"  ⚠️ Erro lendo {filepath}: {e}")
        return 0
    
    original = content
    changes = 0
    
    # Verificar se já tem import
    has_import = IMPORT_LINE in content or "app_localizations.dart" in content
    
    # Substituir strings
    for pt_string, l10n_call in REPLACEMENTS.items():
        if pt_string in content:
            content = content.replace(pt_string, l10n_call)
            changes += content.count(l10n_call) - original.count(l10n_call)
    
    # Adicionar import se necessário e houve mudanças
    if changes > 0 and not has_import:
        # Adicionar após os imports existentes
        import_pattern = r"(import 'package:[^']+';)\n"
        matches = list(re.finditer(import_pattern, content))
        if matches:
            last_import = matches[-1]
            insert_pos = last_import.end()
            content = content[:insert_pos] + IMPORT_LINE + "\n" + content[insert_pos:]
    
    if content != original:
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return changes
        except Exception as e:
            print(f"  ⚠️ Erro escrevendo {filepath}: {e}")
            return 0
    
    return 0

def main():
    print("🌍 Substituindo strings hardcoded por AppLocalizations\n")
    
    total_changes = 0
    files_changed = 0
    
    for target_dir in TARGET_DIRS:
        if not os.path.exists(target_dir):
            continue
            
        for filepath in glob.glob(f"{target_dir}/**/*.dart", recursive=True):
            changes = process_file(filepath)
            if changes > 0:
                print(f"  ✅ {filepath}: {changes} substituições")
                total_changes += changes
                files_changed += 1
    
    print(f"\n📊 Total: {total_changes} substituições em {files_changed} arquivos")
    print("🎯 Próximo passo: flutter gen-l10n && flutter run")

if __name__ == "__main__":
    main()
