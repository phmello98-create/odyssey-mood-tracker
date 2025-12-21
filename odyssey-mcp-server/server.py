#!/usr/bin/env python3
"""
Odyssey Flutter MCP Server
An MCP server specialized in Flutter/Dart development assistance
"""

import os
import sys
from pathlib import Path
from typing import Any

from fastmcp import FastMCP

# Add tools directory to path
sys.path.insert(0, str(Path(__file__).parent))

from tools.flutter_analyzer import FlutterAnalyzer
from tools.dependency_manager import DependencyManager
from tools.widget_inspector import WidgetInspector
from tools.code_generator import CodeGenerator
from resources.project_structure import ProjectStructureResource
from resources.documentation import DocumentationResource

# Initialize MCP server
mcp = FastMCP("odyssey-flutter-server")

# Get project root from environment or default
PROJECT_ROOT = Path(os.getenv("PROJECT_ROOT", "/home/agyspc/Downloads/odyssey-mood-tracker"))

# Initialize tools
flutter_analyzer = FlutterAnalyzer(PROJECT_ROOT)
dependency_manager = DependencyManager(PROJECT_ROOT)
widget_inspector = WidgetInspector(PROJECT_ROOT)
code_generator = CodeGenerator(PROJECT_ROOT)

# Initialize resources
project_structure_resource = ProjectStructureResource(PROJECT_ROOT)
documentation_resource = DocumentationResource(PROJECT_ROOT)


# =============================================================================
# TOOLS - Funções que a IA pode chamar
# =============================================================================

@mcp.tool()
def flutter_analyze_file(file_path: str) -> dict[str, Any]:
    """
    Analisa um arquivo Dart/Flutter específico.
    
    Args:
        file_path: Caminho relativo ao projeto do arquivo Dart
        
    Returns:
        Análise detalhada do arquivo incluindo imports, widgets, providers, etc.
    """
    return flutter_analyzer.analyze_file(file_path)


@mcp.tool()
def get_dependencies() -> dict[str, Any]:
    """
    Lista e analisa todas as dependências do pubspec.yaml.
    
    Returns:
        Informações sobre dependências, versões e status de atualização
    """
    return dependency_manager.get_all_dependencies()


@mcp.tool()
def find_widget_usage(widget_name: str) -> dict[str, Any]:
    """
    Encontra todos os lugares onde um widget específico é usado.
    
    Args:
        widget_name: Nome do widget a procurar
        
    Returns:
        Lista de arquivos e localizações onde o widget é usado
    """
    return widget_inspector.find_widget_usage(widget_name)


@mcp.tool()
def generate_riverpod_provider(provider_name: str, provider_type: str) -> str:
    """
    Gera código boilerplate para um Riverpod provider.
    
    Args:
        provider_name: Nome do provider (ex: 'tasks')
        provider_type: Tipo do provider (StateNotifier, StateProvider, FutureProvider, etc.)
        
    Returns:
        Código Dart gerado para o provider
    """
    return code_generator.generate_provider(provider_name, provider_type)


@mcp.tool()
def analyze_performance(file_path: str) -> dict[str, Any]:
    """
    Analisa um arquivo Dart em busca de problemas de performance.
    
    Args:
        file_path: Caminho relativo ao arquivo
        
    Returns:
        Lista de sugestões de otimização
    """
    return flutter_analyzer.analyze_performance(file_path)


@mcp.tool()
def check_firebase_integration() -> dict[str, Any]:
    """
    Verifica o status da integração Firebase no projeto.
    
    Returns:
        Status de configuração e possíveis problemas
    """
    return flutter_analyzer.check_firebase_integration()


@mcp.tool()
def analyze_hive_models() -> dict[str, Any]:
    """
    Analisa todos os modelos Hive no projeto.
    
    Returns:
        Lista de modelos Hive, suas propriedades e configuração
    """
    return flutter_analyzer.analyze_hive_models()


@mcp.tool()
def find_unused_dependencies() -> dict[str, Any]:
    """
    Encontra dependências declaradas mas não utilizadas no projeto.
    
    Returns:
        Lista de dependências não utilizadas
    """
    return dependency_manager.find_unused_dependencies()


@mcp.tool()
def generate_widget_template(widget_name: str, widget_type: str) -> str:
    """
    Gera template de um widget Flutter.
    
    Args:
        widget_name: Nome do widget
        widget_type: Tipo (stateless, stateful, consumer)
        
    Returns:
        Código Dart do widget
    """
    return code_generator.generate_widget(widget_name, widget_type)


@mcp.tool()
def analyze_state_management() -> dict[str, Any]:
    """
    Analisa o uso de state management (Riverpod) no projeto.
    
    Returns:
        Análise de providers, notifiers e padrões usados
    """
    return flutter_analyzer.analyze_state_management()


@mcp.tool()
def list_project_features() -> dict[str, Any]:
    """
    Lista todas as features/módulos do projeto Flutter.
    
    Returns:
        Estrutura de features com detalhes de cada uma
    """
    return project_structure_resource.list_features()


@mcp.tool()
def search_code(query: str, file_pattern: str = "*.dart") -> dict[str, Any]:
    """
    Busca por código no projeto.
    
    Args:
        query: Termo ou padrão a buscar
        file_pattern: Padrão de arquivos (padrão: *.dart)
        
    Returns:
        Resultados da busca com contexto
    """
    return flutter_analyzer.search_code(query, file_pattern)


@mcp.tool()
def get_widget_tree(file_path: str) -> dict[str, Any]:
    """
    Extrai a árvore de widgets de um arquivo.
    
    Args:
        file_path: Caminho do arquivo
        
    Returns:
        Estrutura hierárquica de widgets
    """
    return widget_inspector.get_widget_tree(file_path)


@mcp.tool()
def analyze_routing() -> dict[str, Any]:
    """
    Analisa a configuração de rotas (GoRouter) do projeto.
    
    Returns:
        Estrutura de rotas e navegação
    """
    return flutter_analyzer.analyze_routing()


# =============================================================================
# RESOURCES - Dados que podem ser lidos pela IA
# =============================================================================

@mcp.resource("odyssey://project/structure")
def get_project_structure() -> str:
    """
    Retorna a estrutura completa do projeto Flutter.
    """
    return project_structure_resource.get_structure_markdown()


@mcp.resource("odyssey://project/docs")
def get_documentation() -> str:
    """
    Retorna a documentação principal do projeto.
    """
    return documentation_resource.get_main_docs()


@mcp.resource("odyssey://patterns/common")
def get_common_patterns() -> str:
    """
    Retorna padrões comuns usados no projeto.
    """
    return documentation_resource.get_common_patterns()


@mcp.resource("odyssey://project/dependencies")
def get_dependency_graph() -> str:
    """
    Retorna o grafo de dependências do projeto.
    """
    return dependency_manager.get_dependency_graph()


@mcp.resource("odyssey://project/features/{feature_name}")
def get_feature_details(feature_name: str) -> str:
    """
    Retorna detalhes de uma feature específica.
    """
    return project_structure_resource.get_feature_details(feature_name)


# =============================================================================
# PROMPTS - Templates para a IA
# =============================================================================

@mcp.prompt()
def flutter_debug_prompt(error_message: str) -> list[dict[str, str]]:
    """
    Prompt para ajudar a debuggar erros Flutter.
    
    Args:
        error_message: Mensagem de erro
    """
    return [
        {
            "role": "user",
            "content": f"""Ajude-me a debuggar este erro Flutter:

ERRO:
{error_message}

Por favor:
1. Identifique a causa provável do erro
2. Sugira soluções específicas para este projeto
3. Forneça código de exemplo se necessário
4. Considere os padrões usados neste projeto (Riverpod, GoRouter, Hive)
"""
        }
    ]


@mcp.prompt()
def optimize_code_prompt(file_path: str) -> list[dict[str, str]]:
    """
    Prompt para otimização de código.
    
    Args:
        file_path: Arquivo a otimizar
    """
    analysis = flutter_analyzer.analyze_performance(file_path)
    
    return [
        {
            "role": "user",
            "content": f"""Analise e otimize o arquivo: {file_path}

ANÁLISE ATUAL:
{analysis}

Sugira:
1. Otimizações de performance
2. Melhorias de legibilidade
3. Refatorações seguindo best practices Flutter
4. Uso apropriado de Riverpod e widgets
"""
        }
    ]


@mcp.prompt()
def refactor_suggestion_prompt(code_snippet: str) -> list[dict[str, str]]:
    """
    Prompt para sugestões de refatoração.
    
    Args:
        code_snippet: Trecho de código
    """
    return [
        {
            "role": "user",
            "content": f"""Analise este código e sugira refatorações:

```dart
{code_snippet}
```

Considere:
1. Princípios SOLID
2. Padrões Flutter/Dart
3. Uso de Riverpod para state management
4. Separação de concerns
5. Testabilidade
"""
        }
    ]


# =============================================================================
# MAIN - Inicia o servidor
# =============================================================================

if __name__ == "__main__":
    print(f"🚀 Odyssey Flutter MCP Server starting...")
    print(f"📂 Project root: {PROJECT_ROOT}")
    print(f"✓ Server initialized with {len(mcp._tools)} tools")
    print(f"✓ Resources available: {len(mcp._resources)}")
    print(f"✓ Prompts available: {len(mcp._prompts)}")
    
    # Start the server
    mcp.run()
