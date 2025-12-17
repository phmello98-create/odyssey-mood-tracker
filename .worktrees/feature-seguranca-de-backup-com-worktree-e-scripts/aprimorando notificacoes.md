📋 CHECKLIST DE CORREÇÕES - ANÁLISE COMPLETA
🔔 PROBLEMA 1: Notificações chegando na instalação
Causa Raiz:
- Arquivo: lib/src/utils/services/notification_scheduler.dart
- Linhas: 100-130
- As configurações padrão são ativadas automaticamente na primeira execução:
  - Humor Manhã: 8:00 AM (habilitado por padrão)
  - Humor Noite: 20:00 PM (habilitado por padrão)
  - Lembretes de Hábitos: A cada 30 min (habilitado por padrão)
  - Lembretes de Tarefas: A cada 30 min (habilitado por padrão)
  - Mensagens Motivacionais: 3x por dia (habilitado por padrão)
- Arquivo: lib/src/features/habits/data/habit_repository.dart
- Linhas: 33-99
- Hábitos de exemplo são criados automaticamente com horários fixos:
  - Meditação (6:30 AM)
  - Exercício (7:00 AM)
  - Leitura (22:00 PM)
- Arquivo: lib/src/features/gamification/data/data_seeder.dart
- Linhas: 226-259
- Tarefas de exemplo são criadas com lembretes ativos
✅ Ações de Correção:
  1.1 - Desabilitar notificações por padrão na primeira instalação
- Modificar notification_scheduler.dart linhas 101-129
- Alterar valores padrão de true para false:
    // Antes: await _prefs!.setBool(_keyMoodMorningEnabled, true);
  // Depois: await _prefs!.setBool(_keyMoodMorningEnabled, false);
  
  1.2 - Criar onboarding de notificações
- Criar tela de boas-vindas que pergunta ao usuário se deseja ativar notificações
- Permitir configuração inicial antes de agendar qualquer notificação
  1.3 - Desabilitar criação automática de hábitos de exemplo
- Modificar habit_repository.dart linha 27
- Adicionar flag de controle para criar hábitos apenas se usuário optar:
    // Adicionar verificação se é primeiro acesso + preferência do usuário
  final shouldCreateSamples = prefs.getBool('create_sample_habits') ?? false;
  if (shouldCreateSamples && box.isEmpty) {
    await _addSampleHabits();
  }
  
  1.4 - Desabilitar criação automática de tarefas de exemplo
- Similar ao item 1.3, adicionar flag de controle em data_seeder.dart
  1.5 - Adicionar opção "Dados de Exemplo" nas configurações
- Permitir que usuário escolha criar dados de exemplo após instalação
---
⌨️ PROBLEMA 2: Teclado passa por cima dos campos de texto
Causa Raiz:
- Arquivo: lib/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart
- Linhas: 109, 126
- A implementação atual usa viewInsets.bottom corretamente, MAS:
  - Aplica padding apenas no SingleChildScrollView
  - Não há resizeToAvoidBottomInset configurado no scaffold
  - Não há animação suave ao abrir/fechar teclado
✅ Ações de Correção:
  2.1 - Verificar scaffold principal do modal
- Garantir que o dialog/modal sheet tenha resizeToAvoidBottomInset: true
  2.2 - Adicionar KeyboardVisibilityBuilder
- Instalar package flutter_keyboard_visibility: ^6.0.0
- Envolver formulários com listener de teclado:
    KeyboardVisibilityBuilder(
    builder: (context, isKeyboardVisible) {
      return AnimatedPadding(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.only(
          bottom: isKeyboardVisible ? keyboardSpace : 0,
        ),
        child: // seu conteúdo
      );
    }
  )
  
  2.3 - Implementar auto-scroll ao focar campo
- Adicionar listener de foco que scrola automaticamente para o campo:
    _focusNode.addListener(() {
    if (_focusNode.hasFocus) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
  
  2.4 - Aplicar correção em todas as telas com TextField
- Arquivos afetados:
  - lib/src/features/tasks/presentation/tasks_screen.dart (linhas 116, 148)
  - lib/src/features/notes/presentation/notes_screen.dart (linhas 538-543)
  - lib/src/features/notes/presentation/note_editor_screen.dart (linha 329)
  - lib/src/features/home/presentation/home_screen.dart (linhas 5218, 5579)
  2.5 - Adicionar Scaffold.resizeToAvoidBottomInset
- Verificar todos os Scaffolds que contém TextFields
- Garantir propriedade resizeToAvoidBottomInset: true
---
🎨 PROBLEMA 3: Ícones e cores desalinhados na tela de editar hábitos
Causa Raiz:
- Arquivo: lib/src/features/home/presentation/home_screen.dart
- Linhas: 5362-5412
Grid de Ícones (linhas 5365-5384):
- Usa Wrap com spacing: 10 e runSpacing: 10
- Containers com width: 48 e height: 48
- PROBLEMA: Não há alinhamento definido no Wrap
- PROBLEMA: Pode sobrar espaço à direita dependendo da largura da tela
Seletor de Cores (linhas 5390-5412):
- Usa Row direto (não flexível)
- Containers com margin: EdgeInsets.only(right: 12)
- PROBLEMA: Row não centralizado
- PROBLEMA: Última cor tem margem desnecessária à direita
✅ Ações de Correção:
  3.1 - Centralizar grid de ícones
Wrap(
  alignment: WrapAlignment.center,  // ADICIONAR
  runAlignment: WrapAlignment.center,  // ADICIONAR
  spacing: 10,
  runSpacing: 10,
  children: icons.map((icon) {
    // código existente
  }).toList(),
),
  3.2 - Calcular largura dinâmica do grid de ícones
// Calcular quantos ícones cabem por linha
final screenWidth = MediaQuery.of(context).size.width - 40; // 20 padding cada lado
final iconsPerRow = (screenWidth / (48 + 10)).floor();
final gridWidth = (iconsPerRow * 48) + ((iconsPerRow - 1) * 10);
Center(
  child: SizedBox(
    width: gridWidth,
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: icons.map((icon) { ... }).toList(),
    ),
  ),
)
  3.3 - Centralizar e corrigir seletor de cores
// ANTES (linha 5390):
Row(
  children: colors.map((color) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      // ...
    );
  }).toList(),
),
// DEPOIS:
Row(
  mainAxisAlignment: MainAxisAlignment.center,  // ADICIONAR
  children: colors.asMap().entries.map((entry) {
    final index = entry.key;
    final color = entry.value;
    final isLast = index == colors.length - 1;
    
    return Container(
      margin: EdgeInsets.only(right: isLast ? 0 : 12),  // Remover margem da última cor
      width: 36,
      height: 36,
      // resto do código
    );
  }).toList(),
),
  3.4 - Adicionar padding consistente no dialog
- Verificar que o padding do dialog é simétrico (mesmo valor esquerda/direita)
- Linha 5126: Verificar padding do modal
---
🎯 PROBLEMA 4: Atividades desalinhadas na tela "Como você está?"
Causa Raiz:
- Arquivo: lib/src/features/activities/presentation/activity_chips.dart
- Linhas: 17-21
return Wrap(
  spacing: 5,
  runAlignment: alignment,  // ❌ Alinha as LINHAS
  alignment: alignment,      // ✅ Alinha os ITENS
  children: activities.map(...)
);
Problema identificado:
- O parâmetro alignment é recebido como WrapAlignment.center por padrão (linha 8)
- MAS quando usado na tela de "Como você está?", pode estar sendo passado outro valor
- OU o Wrap não está preenchendo a largura total disponível
- Arquivo de uso: lib/src/features/mood_records/presentation/add_mood_record/add_mood_record_form.dart
- Linha: 541-544 - Onde o ActivityChips é instanciado
✅ Ações de Correção:
  4.1 - Forçar centralização no ActivityChips
// activity_chips.dart linha 17
Widget build(BuildContext context) {
  return SizedBox(
    width: double.infinity,  // ADICIONAR - força largura total
    child: Wrap(
      spacing: 5,
      runSpacing: 5,  // ADICIONAR runSpacing se não existir
      alignment: WrapAlignment.center,  // FORÇAR centro
      runAlignment: WrapAlignment.center,  // ADICIONAR
      crossAxisAlignment: WrapCrossAlignment.center,  // ADICIONAR
      children: activities.map(...)
    ),
  );
}
  4.2 - Verificar chamada do ActivityChips no formulário
- Arquivo: add_mood_record_form.dart linhas 541-544
- Garantir que não está passando alignment: WrapAlignment.start ou similar
- Remover parâmetro de alignment se estiver sendo passado incorretamente
  4.3 - Verificar container pai dos chips
- Verificar se há algum padding assimétrico no container que envolve os chips
- Garantir que o container tem largura total disponível
  4.4 - Testar com diferentes quantidades de atividades
- 1 atividade: deve centralizar
- 2-3 atividades: deve centralizar na linha
- Múltiplas linhas: cada linha deve centralizar
  4.5 - Aplicar correção em outros locais que usam ActivityChips
- Buscar todos os usos de ActivityChips no projeto
- Garantir consistência de alinhamento em todos os lugares
---
📱 CORREÇÕES GERAIS RECOMENDADAS
  5.1 - Criar padrão de padding consistente
- Definir constantes de padding no design system
- Aplicar em todos os dialogs e modals
  5.2 - Adicionar testes visuais
- Testar em diferentes tamanhos de tela (pequena, média, grande)
- Testar com teclado aberto/fechado
- Testar com diferentes quantidades de itens
  5.3 - Implementar logs de debug
- Adicionar logs quando notificações são agendadas
- Facilitar debugging futuro
  5.4 - Criar documentação de configurações padrão
- Documentar todas as configurações que são ativadas por padrão
- Criar arquivo README com comportamentos iniciais
---
🎯 PRIORIZAÇÃO SUGERIDA
CRÍTICO (fazer primeiro):
1. ✅ Problema 1 - Notificações na instalação (causa confusão ao usuário)
2. ✅ Problema 2 - Teclado sobre campos (UX ruim, impede digitação)
IMPORTANTE (fazer logo em seguida):
3. ✅ Problema 4 - Atividades desalinhadas (aparência ruim)
4. ✅ Problema 3 - Ícones/cores desalinhados (aparência ruim)
MELHORIAS (fazer depois):
5. ✅ Correções gerais e padronização
---
📊 RESUMO EXECUTIVO
Total de arquivos a modificar: 8
Total de correções: 20 itens
Arquivos principais:
1. notification_scheduler.dart - Desabilitar notificações padrão
2. habit_repository.dart - Desabilitar hábitos de exemplo
3. data_seeder.dart - Desabilitar tarefas de exemplo
4. add_mood_record_form.dart - Corrigir comportamento do teclado
5. home_screen.dart - Alinhar ícones e cores no editor de hábitos
6. activity_chips.dart - Centralizar chips de atividades
7. Múltiplos arquivos de formulários - Aplicar correção de teclado
