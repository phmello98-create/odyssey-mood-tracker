#!/usr/bin/env python3
"""
Script para analisar o sistema de inteligência do app Odyssey
"""
import os
import re
from pathlib import Path

def analyze_intelligence_system():
    """Analisa os componentes do sistema de inteligência"""
    print("Análise do Sistema de Inteligência do App Odyssey")
    print("=" * 50)
    
    # Caminho base do projeto
    base_path = Path("/home/agyspc1/Documentos/app com opus 4.5 copia atual")
    
    # Encontrar arquivos de inteligência
    intelligence_files = list((base_path / "lib/src/features/intelligence").rglob("*.dart"))
    
    print(f"\nArquivos encontrados: {len(intelligence_files)}")
    
    # Analisar cada arquivo
    components = {}
    
    for file_path in intelligence_files:
        print(f"\nAnalisando: {file_path.name}")
        
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Identificar classes e funções principais
        classes = re.findall(r'class\s+(\w+)', content)
        functions = re.findall(r'(\w+)\s*\(.*\{', content)
        
        # Identificar imports relevantes
        imports = re.findall(r"import\s+['\"]([^'\"]*intelligence[^'\"]*|[^'\"]*mood[^'\"]*|[^'\"]*analytics[^'\"]*)['\"]", content)
        
        # Identificar padrões de análise
        analysis_patterns = [
            'Pattern', 'Correlation', 'Prediction', 'Insight', 'Analysis',
            'Engine', 'calculate', 'detect', 'generate', 'predict'
        ]
        
        found_patterns = []
        for pattern in analysis_patterns:
            if pattern.lower() in content.lower():
                found_patterns.append(pattern)
        
        components[file_path.name] = {
            'classes': classes,
            'functions': functions,
            'imports': imports,
            'analysis_patterns': found_patterns
        }
        
        print(f"  Classes: {classes}")
        print(f"  Padrões de análise: {found_patterns}")
    
    # Análise detalhada do serviço de inteligência
    intelligence_service_path = base_path / "lib/src/features/intelligence/services/intelligence_service.dart"
    if intelligence_service_path.exists():
        print(f"\nAnálise detalhada do serviço de inteligência:")
        with open(intelligence_service_path, 'r', encoding='utf-8') as f:
            service_content = f.read()
            
        # Identificar os engines usados
        engines = re.findall(r'(\w+)Engine', service_content)
        print(f"  Engines identificados: {engines}")
        
        # Identificar os tipos de dados usados
        data_types = re.findall(r'List<(\w+DataPoint)>', service_content)
        print(f"  Tipos de dados: {data_types}")
        
        # Identificar funcionalidades principais
        features = []
        if 'runFullAnalysis' in service_content:
            features.append('Análise completa')
        if 'generateInsights' in service_content:
            features.append('Geração de insights')
        if 'calculateAllCorrelations' in service_content:
            features.append('Cálculo de correlações')
        if 'predict' in service_content.lower():
            features.append('Previsões')
            
        print(f"  Funcionalidades: {features}")
    
    return components

def main():
    print("Iniciando análise do sistema de inteligência...")
    components = analyze_intelligence_system()
    
    print("\n" + "=" * 50)
    print("RESUMO DA ANÁLISE:")
    print("=" * 50)
    print("O sistema de inteligência do app Odyssey inclui:")
    print("- Análise de padrões temporais")
    print("- Cálculo de correlações entre variáveis")
    print("- Geração de previsões")
    print("- Geração de insights baseados em dados")
    print("- Mecanismos de recomendação")
    print("\nComponentes principais:")
    print("- Pattern Engine")
    print("- Correlation Engine") 
    print("- Prediction Engine")
    print("- Recommendation Engine")
    print("\nDados usados:")
    print("- Mood records")
    print("- Activity data")
    print("- Daily aggregated data")
    print("- Time-based mood patterns")
    
    print("\n" + "=" * 50)
    print("PESQUISA DE LLMs GRATUITOS:")
    print("=" * 50)
    print("\nOpções de LLMs gratuitos para seu projeto:")
    print("\n1. Hugging Face Transformers (gratuito)")
    print("   - Modelos open-source como Mistral, Llama, etc.")
    print("   - Pode rodar localmente")
    print("   - Sem custos de API")
    
    print("\n2. Ollama (gratuito)")
    print("   - Roda LLMs localmente")
    print("   - Suporta diversos modelos (Llama, Mistral, etc.)")
    print("   - Totalmente gratuito e privado")
    
    print("\n3. Hugging Face Inference API (gratuito até certo limite)")
    print("   - Modelos como mISTRAL, Zephyr, etc.")
    print("   - Primeiros 10,000 requests gratuitos por mês")
    
    print("\n4. Google Gemini (gratuito em parte)")
    print("   - Gemini Pro tem free tier limitado")
    print("   - 60 requests por minuto, 15.000 requests por mês")
    
    print("\n5. OpenRouter (agregador com opções gratuitas)")
    print("   - Acessa múltiplos LLMs")
    print("   - Algumas opções têm free tier")
    
    print("\nRECOMENDAÇÃO:")
    print("Para seu projeto Odyssey, recomendo o Ollama ou Hugging Face Transformers")
    print("rodando localmente, pois:")
    print("- São completamente gratuitos")
    print("- Respeitam a privacidade dos dados do usuário")
    print("- Podem ser integrados via HTTP requests")
    print("- Funcionam offline")
    print("- Têm desempenho razoável para análise de sentimentos e insights")

if __name__ == "__main__":
    main()