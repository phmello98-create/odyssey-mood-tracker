# 🎓 Guia de Melhores Práticas MCP para Flutter

Este documento compila as melhores técnicas e práticas para usar o servidor MCP Odyssey no desenvolvimento Flutter.

## 📚 Técnicas de MCP Baseadas em Pesquisa

### 1. Design de Tools (Ferramentas)

#### ✅ DO: Foco em Objetivos
```python
@mcp.tool()
def flutter_analyze_file(file_path: str) -> dict:
    """Analisa um arquivo completo com múltiplas métricas"""
    return {
        "imports": [...],
        "widgets": [...],
        "suggestions": [...]
    }
```

#### ❌ DON'T: APIs Atômicas Demais
```python
# Evite criar tools muito granulares
@mcp.tool()
def count_imports(file_path: str) -> int:  # Muito específico
    pass
```

### 2. Naming Conventions

- **Use snake_case**: `flutter_analyze_file` ✅
- **Evite espaços/pontos**: `flutter.analyze` ❌
- **Seja descritivo**: `analyze_file` ❌ vs `flutter_analyze_file` ✅
- **Verbos de ação**: `get_`, `find_`, `generate_`, `analyze_`

### 3. Estrutura de Retorno

#### Padronização
```python
# Sempre retorne dicts estruturados
{
    "status": "success" | "error",
    "data": {...},
    "message": "...",
    "suggestions": [...]
}
```

#### Lazy Loading para Resources
```python
@mcp.resource("odyssey://project/structure")
def get_project_structure() -> str:
    # Só carrega quando solicitado
    return project_structure_resource.get_structure_markdown()
```

### 4. Error Handling

```python
@mcp.tool()
def analyze_file(file_path: str) -> dict:
    try:
        # Validação de input
        if not file_path:
            return {"error": "file_path is required"}
        
        full_path = project_root / file_path
        if not full_path.exists():
            return {"error": f"File not found: {file_path}"}
        
        # Lógica principal
        return {"status": "success", "data": {...}}
    
    except Exception as e:
        return {"error": str(e), "type": type(e).__name__}
```

## 🎯 Padrões Específicos Flutter

### 1. Análise de Código Flutter

```python
# Pattern: Extração de Widgets
widget_pattern = r"class\s+(\w+)\s+extends\s+(?:StatelessWidget|StatefulWidget|ConsumerWidget)"

# Pattern: Providers Riverpod
provider_pattern = r"ref\.(?:watch|read)\((\w+)\)"

# Pattern: Rotas GoRouter
route_pattern = r"GoRoute\s*\([^)]*path:\s*['\"]([^'\"]+)['\"]"
```

### 2. Detecção de Padrões

```python
def detect_state_management(content: str) -> str:
    """Detecta tipo de state management"""
    patterns = {
        "riverpod": ["ConsumerWidget", "ref.watch", "@riverpod"],
        "bloc": ["BlocBuilder", "BlocConsumer"],
        "provider": ["Provider.of", "ChangeNotifierProvider"],
    }
    
    for sm_type, keywords in patterns.items():
        if any(kw in content for kw in keywords):
            return sm_type
    
    return "none"
```

### 3. Análise de Performance

```python
def check_performance_issues(content: str) -> list:
    """Identifica problemas comuns de performance"""
    issues = []
    
    # Check 1: ListView sem builder
    if re.search(r"ListView\s*\(", content):
        issues.append({
            "type": "performance",
            "severity": "medium",
            "message": "Use ListView.builder for better performance"
        })
    
    # Check 2: Falta de const
    if "Widget build" in content and content.count("const ") < 5:
        issues.append({
            "type": "performance",
            "severity": "low",
            "message": "Consider using const constructors"
        })
    
    return issues
```

## 🛠️ Geração de Código Inteligente

### 1. Templates Contextuais

```python
def generate_provider(name: str, type: str) -> str:
    """Gera provider baseado no contexto do projeto"""
    
    # Template para Riverpod com code generation
    if type == "StateNotifier":
        return f'''
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{name}_provider.g.dart';

@riverpod
class {name.capitalize()}Notifier extends _${name.capitalize()}Notifier {{
  @override
  StateType build() {{
    return StateType();
  }}
  
  void update(/* params */) {{
    state = state.copyWith(/* updates */);
  }}
}}
'''
```

### 2. Geração Baseada em Arquivos Existentes

```python
def generate_similar_widget(reference_file: str, new_name: str) -> str:
    """Gera widget similar a um existente"""
    
    # Analisa arquivo de referência
    ref_content = read_file(reference_file)
    
    # Extrai padrões
    has_riverpod = "ConsumerWidget" in ref_content
    has_hooks = "Hook" in ref_content
    
    # Gera baseado nos padrões encontrados
    if has_riverpod:
        return generate_consumer_widget(new_name)
    else:
        return generate_stateless_widget(new_name)
```

## 📖 Resources Best Practices

### 1. URIs Bem Estruturados

```python
# Hierárquico e descritivo
odyssey://project/structure
odyssey://project/features/{feature_name}
odyssey://patterns/common
odyssey://docs/architecture
```

### 2. Lazy Loading

```python
@mcp.resource("odyssey://project/features/{feature_name}")
def get_feature_details(feature_name: str) -> str:
    """Carrega apenas quando solicitado"""
    # Só processa quando o recurso é acessado
    return analyze_feature(feature_name)
```

## 💬 Prompts Efetivos

### 1. Contextualização

```python
@mcp.prompt()
def flutter_debug_prompt(error_message: str) -> list:
    """Include context about the project"""
    
    # Gather project context
    dependencies = get_dependencies()
    state_mgmt = detect_state_management()
    
    return [{
        "role": "user",
        "content": f"""
Debug this Flutter error in Odyssey project:

ERROR: {error_message}

PROJECT CONTEXT:
- State Management: {state_mgmt}
- Dependencies: {dependencies}
- Patterns: Riverpod, GoRouter, Hive

Please provide:
1. Root cause analysis
2. Specific solution for this project
3. Code examples using our patterns
"""
    }]
```

### 2. Few-Shot Learning

```python
@mcp.prompt()
def refactor_prompt(code: str) -> list:
    """Provide examples for better results"""
    return [{
        "role": "system",
        "content": """
Example refactoring in this project:

BEFORE:
class MyWidget extends StatelessWidget {
  Widget build(context) { ... }
}

AFTER:
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});
  
  @override
  Widget build(context, ref) {
    final theme = ref.watch(themeProvider);
    return ...;
  }
}
"""
    }, {
        "role": "user",
        "content": f"Refactor this code:\n\n{code}"
    }]
```

## 🔍 Análise Avançada

### 1. Dependency Graph

```python
def build_dependency_graph() -> dict:
    """Cria grafo de dependências entre features"""
    graph = {}
    
    for feature in get_features():
        imports = get_feature_imports(feature)
        graph[feature] = {
            "imports": imports,
            "imported_by": find_importers(feature)
        }
    
    return graph
```

### 2. Code Metrics

```python
def calculate_code_metrics(file_path: str) -> dict:
    """Calcula métricas de qualidade"""
    content = read_file(file_path)
    
    return {
        "lines": len(content.splitlines()),
        "complexity": calculate_cyclomatic_complexity(content),
        "widget_count": count_widgets(content),
        "nesting_level": calculate_max_nesting(content),
        "test_coverage": get_test_coverage(file_path),
        "score": calculate_quality_score(content)
    }
```

## 🚀 Performance do Servidor MCP

### 1. Caching

```python
from functools import lru_cache

@lru_cache(maxsize=128)
def get_project_structure() -> dict:
    """Cache structure - raramente muda"""
    return analyze_project_structure()
```

### 2. Operações Assíncronas

```python
import asyncio

async def analyze_multiple_files(files: list[str]) -> list[dict]:
    """Analisa múltiplos arquivos em paralelo"""
    tasks = [analyze_file_async(f) for f in files]
    return await asyncio.gather(*tasks)
```

### 3. Limitação de Resultados

```python
def search_code(query: str, limit: int = 50) -> dict:
    """Limita resultados para evitar sobrecarga"""
    results = []
    
    for file in search_files():
        if len(results) >= limit:
            break
        # Process...
    
    return {
        "results": results,
        "total_found": count_all_matches(query),
        "truncated": count_all_matches(query) > limit
    }
```

## 🔐 Segurança

### 1. Validação de Paths

```python
def validate_file_path(file_path: str) -> bool:
    """Previne path traversal"""
    full_path = (project_root / file_path).resolve()
    
    # Garante que está dentro do projeto
    return str(full_path).startswith(str(project_root))
```

### 2. Sanitização de Input

```python
def sanitize_input(value: str) -> str:
    """Remove caracteres perigosos"""
    # Remove null bytes, controle chars, etc
    return re.sub(r'[\x00-\x1f\x7f-\x9f]', '', value)
```

## 📊 Logging e Monitoramento

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

@mcp.tool()
def analyze_file(file_path: str) -> dict:
    logging.info(f"Analyzing file: {file_path}")
    
    try:
        result = do_analysis(file_path)
        logging.info(f"Analysis completed: {len(result)} issues found")
        return result
    except Exception as e:
        logging.error(f"Analysis failed: {e}")
        raise
```

## 🎯 Uso no Antigravity

### Comandos Naturais

```
❌ "Use flutter_analyze_file com lib/main.dart"
✅ "Analise o arquivo lib/main.dart"

❌ "Execute generate_widget_template MyWidget stateless"  
✅ "Gere um widget stateless chamado MyWidget"

❌ "Call find_widget_usage StreakWidget"
✅ "Onde o StreakWidget é usado?"
```

### Workflows Eficientes

```
1. "Liste todas as features do projeto"
2. "Analise a feature home em detalhes"
3. "Encontre problemas de performance em home_screen.dart"
4. "Gere um provider para gerenciar o estado do home"
```

## 📝 Documentação de Tools

```python
@mcp.tool()
def analyze_file(file_path: str) -> dict[str, Any]:
    """
    Analisa um arquivo Dart/Flutter específico.
    
    Esta ferramenta examina:
    - Imports e dependências
    - Widgets definidos
    - Uso de state management
    - Padrões de performance
    - Problemas potenciais
    
    Args:
        file_path: Caminho relativo ao projeto (ex: lib/main.dart)
        
    Returns:
        Dict contendo:
        - imports: Lista de imports
        - widgets: Widgets encontrados
        - providers: Providers Riverpod usados
        - suggestions: Sugestões de melhoria
        
    Example:
        >>> analyze_file("lib/src/features/home/home_screen.dart")
        {
            "imports": ["package:flutter/material.dart", ...],
            "widgets": ["HomeScreen"],
            "suggestions": [...]
        }
    """
    pass
```

---

**Última atualização**: 2025-12-20  
**Autor**: Odyssey Development Team
