# 🗺️ ROADMAP DE IMPLEMENTAÇÃO - ODYSSEY

**Guia prático para implementar novas funcionalidades**

---

## 📋 Template de Feature Completa

### Checklist de Implementação

Ao adicionar uma nova feature, seguir este checklist:

```markdown
## Feature: [Nome da Feature]

### 1. Planejamento ✏️
- [ ] Definir requisitos funcionais
- [ ] Criar mockups/wireframes
- [ ] Definir modelo de dados
- [ ] Identificar dependências externas
- [ ] Estimar tempo de desenvolvimento

### 2. Modelo de Dados 🗄️
- [ ] Criar classe de domínio
- [ ] Adicionar anotações Hive (@HiveType, @HiveField)
- [ ] Definir TypeId único
- [ ] Adicionar Freezed (se aplicável)
- [ ] Gerar código (build_runner)

### 3. Repositório 📦
- [ ] Criar repository class
- [ ] Implementar CRUD operations
- [ ] Criar provider Riverpod
- [ ] Adicionar testes unitários

### 4. UI/UX 🎨
- [ ] Criar screen principal
- [ ] Criar widgets reutilizáveis
- [ ] Implementar navegação
- [ ] Adicionar animações
- [ ] Testar responsividade

### 5. Integração 🔗
- [ ] Conectar com sistema de XP/Gamificação
- [ ] Adicionar notificações (se aplicável)
- [ ] Integrar com backup
- [ ] Adicionar analytics events

### 6. Localização 🌍
- [ ] Adicionar strings em app_pt.arb
- [ ] Adicionar strings em app_en.arb
- [ ] Gerar localizações (flutter gen-l10n)
- [ ] Testar ambos idiomas

### 7. Testes ✅
- [ ] Testes unitários (modelo + repository)
- [ ] Testes de widget
- [ ] Testes de integração
- [ ] Teste manual em Android
- [ ] Teste manual em iOS

### 8. Documentação 📚
- [ ] Atualizar DOCUMENTATION.md
- [ ] Adicionar comentários no código
- [ ] Criar exemplos de uso
- [ ] Atualizar README se necessário

### 9. Build & Deploy 🚀
- [ ] Rodar flutter analyze
- [ ] Corrigir warnings
- [ ] Build release (Android/iOS)
- [ ] Testar APK/IPA
- [ ] Criar release notes
```

---

## 🛠️ Guias de Implementação Detalhados

### 1. Sistema de Tags (Exemplo Completo)

#### Passo 1: Modelo de Dados

```dart
// lib/src/features/tags/domain/tag.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

@freezed
@HiveType(typeId: 26) // ⚠️ USAR PRÓXIMO ID DISPONÍVEL
class Tag with _$Tag {
  @HiveType(typeId: 26, adapterName: 'TagAdapter')
  factory Tag({
    @HiveField(0) required String id,
    @HiveField(1) required String name,
    @HiveField(2) required int color,
    @HiveField(3) required String icon,
    @HiveField(4) @Default([]) List<String> linkedItems, // IDs de tasks/notes
    @HiveField(5) required DateTime createdAt,
  }) = _Tag;
}
```

#### Passo 2: Repository

```dart
// lib/src/features/tags/data/tag_repository.dart
import 'package:hive/hive.dart';
import '../domain/tag.dart';

class TagRepository {
  final Box<Tag> _box;

  TagRepository(this._box);

  // Create
  Future<void> createTag(Tag tag) async {
    await _box.put(tag.id, tag);
  }

  // Read
  List<Tag> getAllTags() {
    return _box.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Tag? getTag(String id) {
    return _box.get(id);
  }

  List<Tag> getTagsForItem(String itemId) {
    return _box.values.where((tag) => 
      tag.linkedItems.contains(itemId)
    ).toList();
  }

  // Update
  Future<void> updateTag(Tag tag) async {
    await _box.put(tag.id, tag);
  }

  Future<void> linkTagToItem(String tagId, String itemId) async {
    final tag = _box.get(tagId);
    if (tag != null && !tag.linkedItems.contains(itemId)) {
      final updated = tag.copyWith(
        linkedItems: [...tag.linkedItems, itemId],
      );
      await _box.put(tagId, updated);
    }
  }

  Future<void> unlinkTagFromItem(String tagId, String itemId) async {
    final tag = _box.get(tagId);
    if (tag != null) {
      final updated = tag.copyWith(
        linkedItems: tag.linkedItems.where((id) => id != itemId).toList(),
      );
      await _box.put(tagId, updated);
    }
  }

  // Delete
  Future<void> deleteTag(String id) async {
    await _box.delete(id);
  }

  // Search
  List<Tag> searchTags(String query) {
    final lowerQuery = query.toLowerCase();
    return _box.values
        .where((tag) => tag.name.toLowerCase().contains(lowerQuery))
        .toList();
  }
}

// Provider
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final box = Hive.box<Tag>('tags');
  return TagRepository(box);
});

// State provider para lista de tags
final tagsProvider = StateNotifierProvider<TagsNotifier, List<Tag>>((ref) {
  final repository = ref.watch(tagRepositoryProvider);
  return TagsNotifier(repository);
});

class TagsNotifier extends StateNotifier<List<Tag>> {
  final TagRepository _repository;

  TagsNotifier(this._repository) : super([]) {
    _loadTags();
  }

  void _loadTags() {
    state = _repository.getAllTags();
  }

  Future<void> addTag(Tag tag) async {
    await _repository.createTag(tag);
    _loadTags();
  }

  Future<void> removeTag(String id) async {
    await _repository.deleteTag(id);
    _loadTags();
  }

  Future<void> updateTag(Tag tag) async {
    await _repository.updateTag(tag);
    _loadTags();
  }
}
```

#### Passo 3: UI - Tag Manager Screen

```dart
// lib/src/features/tags/presentation/tags_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/localization/app_localizations_x.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import '../data/tag_repository.dart';
import '../domain/tag.dart';
import 'tag_form_dialog.dart';

class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.tags),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTagForm(context, ref),
          ),
        ],
      ),
      body: tags.isEmpty
          ? _buildEmptyState(context)
          : _buildTagList(context, ref, tags),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_outline,
            size: 80,
            color: UltravioletColors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            context.loc.noTagsYet,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.loc.createFirstTag,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: UltravioletColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagList(BuildContext context, WidgetRef ref, List<Tag> tags) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        return _TagCard(tag: tag);
      },
    );
  }

  void _showTagForm(BuildContext context, WidgetRef ref, [Tag? tag]) {
    showDialog(
      context: context,
      builder: (context) => TagFormDialog(tag: tag),
    );
  }
}

class _TagCard extends ConsumerWidget {
  final Tag tag;

  const _TagCard({required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(tag.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            IconData(int.parse(tag.icon), fontFamily: 'MaterialIcons'),
            color: color,
            size: 24,
          ),
        ),
        title: Text(tag.name),
        subtitle: Text('${tag.linkedItems.length} items'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editTag(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteTag(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _editTag(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TagFormDialog(tag: tag),
    );
  }

  void _deleteTag(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.deleteTag),
        content: Text(context.loc.deleteTagConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(context.loc.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(tagsProvider.notifier).removeTag(tag.id);
    }
  }
}
```

#### Passo 4: Tag Form Dialog

```dart
// lib/src/features/tags/presentation/tag_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/tag.dart';
import '../data/tag_repository.dart';

class TagFormDialog extends ConsumerStatefulWidget {
  final Tag? tag;

  const TagFormDialog({super.key, this.tag});

  @override
  ConsumerState<TagFormDialog> createState() => _TagFormDialogState();
}

class _TagFormDialogState extends ConsumerState<TagFormDialog> {
  late TextEditingController _nameController;
  Color _selectedColor = Colors.blue;
  String _selectedIcon = '0xe54d'; // default icon

  final List<Color> _availableColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.pink,
  ];

  final List<String> _availableIcons = [
    '0xe54d', // school
    '0xe3f3', // book
    '0xe868', // work
    '0xe3ba', // mic
    '0xe3e9', // music
    // adicionar mais...
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name);
    if (widget.tag != null) {
      _selectedColor = Color(widget.tag!.color);
      _selectedIcon = widget.tag!.icon;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.tag == null ? 'New Tag' : 'Edit Tag'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            Text('Color'),
            Wrap(
              spacing: 8,
              children: _availableColors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Icon'),
            Wrap(
              spacing: 8,
              children: _availableIcons.map((iconCode) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconCode),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedIcon == iconCode
                          ? _selectedColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconData(int.parse(iconCode), fontFamily: 'MaterialIcons'),
                      color: _selectedIcon == iconCode
                          ? _selectedColor
                          : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveTag,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveTag() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final tag = Tag(
      id: widget.tag?.id ?? const Uuid().v4(),
      name: name,
      color: _selectedColor.value,
      icon: _selectedIcon,
      linkedItems: widget.tag?.linkedItems ?? [],
      createdAt: widget.tag?.createdAt ?? DateTime.now(),
    );

    if (widget.tag == null) {
      await ref.read(tagsProvider.notifier).addTag(tag);
    } else {
      await ref.read(tagsProvider.notifier).updateTag(tag);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
```

#### Passo 5: Integração com Tasks

```dart
// Modificar lib/src/features/tasks/domain/task.dart
@HiveField(8) List<String>? tagIds; // adicionar campo

// Modificar lib/src/features/tasks/presentation/tasks_screen.dart
// Adicionar chip de tags:
Widget _buildTaskTags(Task task) {
  if (task.tagIds == null || task.tagIds!.isEmpty) {
    return const SizedBox.shrink();
  }

  final tagRepo = ref.read(tagRepositoryProvider);
  final tags = task.tagIds!
      .map((id) => tagRepo.getTag(id))
      .whereType<Tag>()
      .toList();

  return Wrap(
    spacing: 4,
    runSpacing: 4,
    children: tags.map((tag) {
      return Chip(
        label: Text(tag.name),
        backgroundColor: Color(tag.color).withValues(alpha: 0.2),
        labelStyle: TextStyle(color: Color(tag.color)),
        avatar: Icon(
          IconData(int.parse(tag.icon), fontFamily: 'MaterialIcons'),
          size: 16,
          color: Color(tag.color),
        ),
      );
    }).toList(),
  );
}
```

#### Passo 6: Localização

```json
// app_pt.arb
{
  "tags": "Tags",
  "noTagsYet": "Nenhuma tag ainda",
  "createFirstTag": "Crie sua primeira tag para organizar",
  "newTag": "Nova Tag",
  "editTag": "Editar Tag",
  "deleteTag": "Excluir Tag",
  "deleteTagConfirmation": "Tem certeza que deseja excluir esta tag?",
  "tagName": "Nome da Tag",
  "tagColor": "Cor",
  "tagIcon": "Ícone"
}

// app_en.arb
{
  "tags": "Tags",
  "noTagsYet": "No tags yet",
  "createFirstTag": "Create your first tag to organize",
  "newTag": "New Tag",
  "editTag": "Edit Tag",
  "deleteTag": "Delete Tag",
  "deleteTagConfirmation": "Are you sure you want to delete this tag?",
  "tagName": "Tag Name",
  "tagColor": "Color",
  "tagIcon": "Icon"
}
```

#### Passo 7: Registrar no Main

```dart
// main.dart
Hive.registerAdapter(TagAdapter());
await Hive.openBox<Tag>('tags');
```

---

### 2. Exportação de Relatórios PDF

#### Dependências

```yaml
# pubspec.yaml
dependencies:
  pdf: ^3.10.0
  printing: ^5.11.0
  path_provider: ^2.1.1
```

#### Implementação

```dart
// lib/src/features/analytics/data/pdf_report_generator.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PdfReportGenerator {
  Future<File> generateMoodReport({
    required DateTime startDate,
    required DateTime endDate,
    required List<MoodRecord> records,
  }) async {
    final pdf = pw.Document();

    // Add page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text(
                'Relatório de Humor',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 24),

              // Statistics
              _buildStatsSection(records),
              
              pw.SizedBox(height: 24),

              // Records table
              _buildRecordsTable(records),
            ],
          );
        },
      ),
    );

    // Save to file
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/mood_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildStatsSection(List<MoodRecord> records) {
    final avgScore = records.map((r) => r.score).reduce((a, b) => a + b) / records.length;
    final totalRecords = records.length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Estatísticas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text('Total de registros: $totalRecords'),
          pw.Text('Média de humor: ${avgScore.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  pw.Widget _buildRecordsTable(List<MoodRecord> records) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCellText('Data', isBold: true),
            _tableCellText('Humor', isBold: true),
            _tableCellText('Nota', isBold: true),
          ],
        ),
        // Rows
        ...records.map((record) {
          return pw.TableRow(
            children: [
              _tableCellText(DateFormat('dd/MM/yyyy HH:mm').format(record.date)),
              _tableCellText(record.label),
              _tableCellText(record.score.toString()),
            ],
          );
        }).toList(),
      ],
    );
  }

  pw.Widget _tableCellText(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // Share PDF
  Future<void> sharePdf(File file) async {
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: 'mood_report.pdf',
    );
  }

  // Print PDF
  Future<void> printPdf(File file) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => file.readAsBytes(),
    );
  }
}

// Provider
final pdfReportGeneratorProvider = Provider<PdfReportGenerator>((ref) {
  return PdfReportGenerator();
});
```

---

## 🔄 Workflow de Desenvolvimento

### Daily Development Flow

```bash
# 1. Pull latest changes
git pull origin main

# 2. Create feature branch
git checkout -b feature/nome-feature

# 3. Code...

# 4. Generate code if needed
flutter pub run build_runner build --delete-conflicting-outputs

# 5. Generate localization
flutter gen-l10n

# 6. Test
flutter test

# 7. Analyze
flutter analyze --no-fatal-infos

# 8. Format
dart format .

# 9. Commit
git add .
git commit -m "feat: descrição da feature"

# 10. Push
git push origin feature/nome-feature

# 11. Create PR on GitHub
```

### Release Flow

```bash
# 1. Update version in pubspec.yaml
# version: 1.0.0+2002 -> 1.1.0+2003

# 2. Update CHANGELOG.md

# 3. Build release
flutter build apk --release
flutter build appbundle --release

# 4. Test APK/Bundle
adb install build/app/outputs/flutter-apk/app-release.apk

# 5. Tag release
git tag -a v1.1.0 -m "Release 1.1.0"
git push origin v1.1.0

# 6. Upload to Play Store Console
```

---

## 📊 Métricas de Qualidade

### Code Coverage Target
- **Mínimo:** 60%
- **Ideal:** 80%+

### Performance Targets
- **App startup:** < 2s
- **Screen transition:** < 300ms
- **Database query:** < 100ms
- **API response:** < 1s

### Accessibility
- [ ] Todos os botões com semantics
- [ ] Contraste mínimo 4.5:1
- [ ] Tamanho de toque >= 48px
- [ ] Suporte a leitores de tela

---

## 🎯 Próximos Milestones

### Q1 2025
- [ ] Sistema de Tags completo
- [ ] Exportação de relatórios PDF
- [ ] Widget de tela inicial
- [ ] Dark mode adaptativo

### Q2 2025
- [ ] Integração com calendário
- [ ] Modo offline completo
- [ ] Análise de sentimentos IA
- [ ] Colaboração em tempo real (beta)

### Q3 2025
- [ ] Smartwatch app
- [ ] Modo foco com bloqueio
- [ ] Chatbot de bem-estar
- [ ] Programa de recompensas

### Q4 2025
- [ ] AR visualization
- [ ] Integração com wearables
- [ ] Multi-plataforma (desktop)
- [ ] API pública (beta)

---

**Última atualização:** 12/12/2024
