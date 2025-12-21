"""
Documentation Resource
Fornece acesso à documentação do projeto
"""

from pathlib import Path
from typing import Any


class DocumentationResource:
    """Recurso de documentação"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
    
    def get_main_docs(self) -> str:
        """Retorna documentação principal"""
        docs = []
        
        # README
        readme = self.project_root / "README.md"
        if readme.exists():
            docs.append("# README\n")
            docs.append(readme.read_text(encoding='utf-8'))
            docs.append("\n---\n")
        
        # DOCUMENTATION.md
        doc_file = self.project_root / "DOCUMENTATION.md"
        if doc_file.exists():
            docs.append("# Documentation\n")
            docs.append(doc_file.read_text(encoding='utf-8'))
            docs.append("\n---\n")
        
        # INDEX_DOCUMENTACAO.md
        index_doc = self.project_root / "INDEX_DOCUMENTACAO.md"
        if index_doc.exists():
            docs.append("# Documentation Index\n")
            docs.append(index_doc.read_text(encoding='utf-8'))
        
        if not docs:
            return "No documentation files found"
        
        return "\n".join(docs)
    
    def get_common_patterns(self) -> str:
        """Retorna padrões comuns do projeto"""
        patterns = ["# Common Patterns in Odyssey\n"]
        
        patterns.append("""
## State Management Pattern

This project uses **Riverpod** for state management.

### Provider Pattern
```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() {
    return MyState();
  }
  
  void updateState() {
    state = state.copyWith(/* updates */);
  }
}
```

### Usage in Widgets
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myNotifierProvider);
    return /* widget tree */;
  }
}
```

## Navigation Pattern

Uses **GoRouter** for navigation.

### Route Definition
```dart
GoRoute(
  path: '/my-route',
  name: 'myRoute',
  builder: (context, state) => MyScreen(),
)
```

### Navigation
```dart
context.goNamed('myRoute');
context.push('/my-route');
```

## Database Pattern

Uses **Hive** for local storage.

### Model Definition
```dart
@HiveType(typeId: 0)
class MyModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
}
```

### Usage
```dart
final box = await Hive.openBox<MyModel>('myBox');
await box.put(key, model);
final model = box.get(key);
```

## Feature Structure

Each feature follows this structure:

```
features/
  my_feature/
    data/
      models/
      repositories/
    domain/
      entities/
      usecases/
    presentation/
      screens/
      widgets/
      providers/
```

## Firebase Integration

### Firestore
```dart
final firestore = FirebaseFirestore.instance;
await firestore.collection('myCollection').add(data);
```

### Authentication
```dart
final auth = FirebaseAuth.instance;
await auth.signInWithEmailAndPassword(email, password);
```

## Widget Best Practices

1. Use `const` constructors whenever possible
2. Extract complex widgets into separate files
3. Use `ConsumerWidget` for Riverpod integration
4. Keep widgets small and focused
5. Use proper key management

## Performance Tips

1. Use `ListView.builder` for long lists
2. Implement `const` widgets
3. Avoid heavy computations in `build()`
4. Use `RepaintBoundary` for complex animations
5. Profile with Flutter DevTools
""")
        
        return "\n".join(patterns)
    
    def get_architecture_docs(self) -> str:
        """Retorna documentação de arquitetura"""
        arch_file = self.project_root / "ARCHITECTURE_DIAGRAMS.md"
        
        if arch_file.exists():
            return arch_file.read_text(encoding='utf-8')
        
        return "Architecture documentation not found"
    
    def list_all_docs(self) -> list[str]:
        """Lista todos os arquivos de documentação"""
        doc_files = []
        
        for md_file in self.project_root.glob("*.md"):
            doc_files.append(str(md_file.relative_to(self.project_root)))
        
        return sorted(doc_files)
