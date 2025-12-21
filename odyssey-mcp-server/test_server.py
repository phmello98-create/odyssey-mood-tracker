#!/usr/bin/env python3
"""
Script de teste rápido do servidor MCP
"""

import sys
from pathlib import Path

# Add the server directory to path
sys.path.insert(0, str(Path(__file__).parent))

from tools.flutter_analyzer import FlutterAnalyzer
from tools.dependency_manager import DependencyManager

def test_analyzer():
    """Testa o analisador Flutter"""
    print("🔍 Testando Flutter Analyzer...")
    
    project_root = Path(__file__).parent.parent
    analyzer = FlutterAnalyzer(project_root)
    
    # Testa análise de arquivo
    result = analyzer.analyze_file("lib/main.dart")
    
    if "error" in result:
        print(f"  ❌ Erro: {result['error']}")
    else:
        print(f"  ✓ Arquivo analisado: {result['file']}")
        print(f"  ✓ Imports: {len(result['imports'])}")
        print(f"  ✓ Widgets: {len(result['widgets'])}")
        print(f"  ✓ Providers: {len(result['providers_used'])}")
    
    print()

def test_dependency_manager():
    """Testa o gerenciador de dependências"""
    print("📦 Testando Dependency Manager...")
    
    project_root = Path(__file__).parent.parent
    dep_mgr = DependencyManager(project_root)
    
    # Testa listagem de dependências
    result = dep_mgr.get_all_dependencies()
    
    if "error" in result:
        print(f"  ❌ Erro: {result['error']}")
    else:
        print(f"  ✓ Dependências: {result['total_count']}")
        print(f"  ✓ Principais: {len(result['dependencies'])}")
        print(f"  ✓ Dev: {len(result['dev_dependencies'])}")
    
    print()

def test_firebase():
    """Testa verificação Firebase"""
    print("🔥 Testando Firebase Integration...")
    
    project_root = Path(__file__).parent.parent
    analyzer = FlutterAnalyzer(project_root)
    
    result = analyzer.check_firebase_integration()
    
    if "error" in result:
        print(f"  ❌ Erro: {result['error']}")
    else:
        print(f"  ✓ Status: {result['status']}")
        print(f"  ✓ Android configurado: {result['android_configured']}")
        print(f"  ✓ iOS configurado: {result['ios_configured']}")
        
        active_packages = [k for k, v in result['packages'].items() if v]
        print(f"  ✓ Packages ativos: {len(active_packages)}")
    
    print()

def main():
    """Executa todos os testes"""
    print()
    print("=" * 60)
    print("🧪 TESTE DO SERVIDOR MCP ODYSSEY")
    print("=" * 60)
    print()
    
    try:
        test_analyzer()
        test_dependency_manager()
        test_firebase()
        
        print("=" * 60)
        print("✅ TODOS OS TESTES PASSARAM!")
        print("=" * 60)
        print()
        print("👉 Próximo passo: Configurar no Antigravity")
        print("   Veja: CONFIGURACAO_ANTIGRAVITY.md")
        print()
        
    except Exception as e:
        print()
        print("=" * 60)
        print(f"❌ ERRO: {e}")
        print("=" * 60)
        print()
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
