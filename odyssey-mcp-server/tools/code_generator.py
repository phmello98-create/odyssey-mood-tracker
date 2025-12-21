"""
Code Generator
Gera código boilerplate Flutter/Dart
"""

from pathlib import Path
from typing import Any


class CodeGenerator:
    """Gerador de código Flutter"""
    
    def __init__(self, project_root: Path):
        self.project_root = project_root
    
    def generate_provider(self, provider_name: str, provider_type: str) -> str:
        """Gera código para um Riverpod provider"""
        
        templates = {
            "StateNotifierProvider": self._generate_state_notifier,
            "StateProvider": self._generate_state_provider,
            "FutureProvider": self._generate_future_provider,
            "StreamProvider": self._generate_stream_provider,
            "Provider": self._generate_simple_provider,
        }
        
        generator = templates.get(provider_type, self._generate_simple_provider)
        return generator(provider_name)
    
    def _generate_state_notifier(self, name: str) -> str:
        """Gera StateNotifierProvider"""
        class_name = f"{name.capitalize()}Notifier"
        
        return f"""import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{name}_provider.g.dart';

@riverpod
class {class_name} extends _${class_name} {{
  @override
  YourStateType build() {{
    // Initialize state
    return YourStateType();
  }}
  
  // Add your methods here
  void updateState(/* parameters */) {{
    state = state.copyWith(/* updates */);
  }}
}}

// Usage:
// final {name} = ref.watch({name}NotifierProvider);
// ref.read({name}NotifierProvider.notifier).updateState();
"""
    
    def _generate_state_provider(self, name: str) -> str:
        """Gera StateProvider"""
        return f"""import 'package:flutter_riverpod/flutter_riverpod.dart';

final {name}Provider = StateProvider<YourType>((ref) {{
  return YourType(); // Initial value
}});

// Usage:
// final {name} = ref.watch({name}Provider);
// ref.read({name}Provider.notifier).state = newValue;
"""
    
    def _generate_future_provider(self, name: str) -> str:
        """Gera FutureProvider"""
        return f"""import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{name}_provider.g.dart';

@riverpod
Future<YourType> {name}(Ref ref) async {{
  // Your async logic here
  final result = await yourAsyncFunction();
  return result;
}}

// Usage:
// final {name}Async = ref.watch({name}Provider);
// {name}Async.when(
//   data: (data) => /* success */,
//   loading: () => /* loading */,
//   error: (error, stack) => /* error */,
// );
"""
    
    def _generate_stream_provider(self, name: str) -> str:
        """Gera StreamProvider"""
        return f"""import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{name}_provider.g.dart';

@riverpod
Stream<YourType> {name}(Ref ref) {{
  // Your stream logic here
  return yourStream();
}}

// Usage:
// final {name}Stream = ref.watch({name}Provider);
// {name}Stream.when(
//   data: (data) => /* success */,
//   loading: () => /* loading */,
//   error: (error, stack) => /* error */,
// );
"""
    
    def _generate_simple_provider(self, name: str) -> str:
        """Gera Provider simples"""
        return f"""import 'package:flutter_riverpod/flutter_riverpod.dart';

final {name}Provider = Provider<YourType>((ref) {{
  // Your logic here
  return YourType();
}});

// Usage:
// final {name} = ref.watch({name}Provider);
"""
    
    def generate_widget(self, widget_name: str, widget_type: str) -> str:
        """Gera template de widget"""
        
        templates = {
            "stateless": self._generate_stateless_widget,
            "stateful": self._generate_stateful_widget,
            "consumer": self._generate_consumer_widget,
            "hook": self._generate_hook_widget,
        }
        
        generator = templates.get(widget_type.lower(), self._generate_stateless_widget)
        return generator(widget_name)
    
    def _generate_stateless_widget(self, name: str) -> str:
        """Gera StatelessWidget"""
        return f"""import 'package:flutter/material.dart';

class {name} extends StatelessWidget {{
  const {name}({{super.key}});

  @override
  Widget build(BuildContext context) {{
    return Container(
      // Your widget tree here
      child: const Text('{name}'),
    );
  }}
}}
"""
    
    def _generate_stateful_widget(self, name: str) -> str:
        """Gera StatefulWidget"""
        return f"""import 'package:flutter/material.dart';

class {name} extends StatefulWidget {{
  const {name}({{super.key}});

  @override
  State<{name}> createState() => _{name}State();
}}

class _{name}State extends State<{name}> {{
  @override
  void initState() {{
    super.initState();
    // Initialize state here
  }}

  @override
  void dispose() {{
    // Clean up here
    super.dispose();
  }}

  @override
  Widget build(BuildContext context) {{
    return Container(
      // Your widget tree here
      child: const Text('{name}'),
    );
  }}
}}
"""
    
    def _generate_consumer_widget(self, name: str) -> str:
        """Gera ConsumerWidget"""
        return f"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class {name} extends ConsumerWidget {{
  const {name}({{super.key}});

  @override
  Widget build(BuildContext context, WidgetRef ref) {{
    // Watch providers here
    // final someValue = ref.watch(someProvider);
    
    return Container(
      // Your widget tree here
      child: const Text('{name}'),
    );
  }}
}}
"""
    
    def _generate_hook_widget(self, name: str) -> str:
        """Gera HookConsumerWidget"""
        return f"""import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class {name} extends HookConsumerWidget {{
  const {name}({{super.key}});

  @override
  Widget build(BuildContext context, WidgetRef ref) {{
    // Use hooks here
    // final controller = useTextEditingController();
    // final animationController = useAnimationController();
    
    // Watch providers here
    // final someValue = ref.watch(someProvider);
    
    return Container(
      // Your widget tree here
      child: const Text('{name}'),
    );
  }}
}}
"""
    
    def generate_model(self, model_name: str, fields: list[dict[str, str]]) -> str:
        """Gera um modelo Hive"""
        class_name = model_name.capitalize()
        
        # Gera os campos
        field_declarations = []
        hive_fields = []
        constructor_params = []
        
        for i, field in enumerate(fields):
            field_name = field["name"]
            field_type = field["type"]
            
            hive_fields.append(f"  @HiveField({i})")
            field_declarations.append(f"  final {field_type} {field_name};")
            constructor_params.append(f"required this.{field_name}")
        
        return f"""import 'package:hive/hive.dart';

part '{model_name}.g.dart';

@HiveType(typeId: 0) // TODO: Change typeId to unique value
class {class_name} extends HiveObject {{
{chr(10).join(hive_fields)}
{chr(10).join(field_declarations)}

  {class_name}({{
    {', '.join(constructor_params)},
  }});
}}

// Don't forget to run: flutter pub run build_runner build
"""
    
    def generate_screen(self, screen_name: str, has_app_bar: bool = True) -> str:
        """Gera uma screen completa"""
        return f"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class {screen_name}Screen extends ConsumerWidget {{
  const {screen_name}Screen({{super.key}});

  @override
  Widget build(BuildContext context, WidgetRef ref) {{
    return Scaffold({
      f'''
      appBar: AppBar(
        title: const Text('{screen_name}'),
      ),''' if has_app_bar else ''}
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '{screen_name} Screen',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Add your content here
            ],
          ),
        ),
      ),
    );
  }}
}}
"""
