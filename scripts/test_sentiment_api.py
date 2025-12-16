#!/usr/bin/env python3
"""
Script de teste e validação do sistema de inteligência do Odyssey App.
Testa a API HuggingFace para análise de sentimento.

Uso: 
  python3 scripts/test_sentiment_api.py           # Rodar testes
  python3 scripts/test_sentiment_api.py --interactive  # Modo interativo
"""

import os
import json
from datetime import datetime

try:
    from huggingface_hub import InferenceClient
    HAS_HF_HUB = True
except ImportError:
    HAS_HF_HUB = False
    import requests

# Configuração da API
API_KEY = os.environ.get('HF_TOKEN', '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')
MODEL_MULTILINGUAL = "cardiffnlp/twitter-xlm-roberta-base-sentiment-multilingual"
MODEL_ENGLISH = "distilbert-base-uncased-finetuned-sst-2-english"

# Textos de teste em português
TEST_TEXTS_PT = [
    # Positivos
    ("Hoje foi um dia maravilhoso! Consegui completar todas as minhas tarefas.", "positive"),
    ("Estou muito feliz com meu progresso no trabalho.", "positive"),
    ("Que dia incrível, fiz exercícios e me sinto ótimo!", "positive"),
    ("Gratidão por tudo de bom que aconteceu hoje.", "positive"),
    ("Adoro minha família, eles são incríveis!", "positive"),
    
    # Negativos
    ("Estou muito cansado e frustrado com tudo.", "negative"),
    ("Dia terrível, nada deu certo.", "negative"),
    ("Me sinto triste e sem motivação.", "negative"),
    ("Ansiedade está me consumindo hoje.", "negative"),
    ("Odeio quando as coisas não funcionam.", "negative"),
    
    # Neutros
    ("Hoje acordei, tomei café e fui trabalhar.", "neutral"),
    ("Reunião às 10h, almoço às 12h.", "neutral"),
    ("Preciso ir ao mercado comprar algumas coisas.", "neutral"),
    ("Segunda-feira, início de semana.", "neutral"),
    ("O tempo está nublado lá fora.", "neutral"),
]


def analyze_sentiment(text: str, use_multilingual: bool = True) -> dict:
    """Analisa o sentimento de um texto usando HuggingFace API."""
    model = MODEL_MULTILINGUAL if use_multilingual else MODEL_ENGLISH
    
    if HAS_HF_HUB:
        try:
            client = InferenceClient(
                provider="hf-inference",
                api_key=API_KEY,
            )
            result = client.text_classification(text, model=model)
            
            scores = [{"label": r.label, "score": r.score} for r in result]
            top = max(scores, key=lambda x: x['score'])
            
            return {
                "success": True,
                "scores": scores,
                "top_label": top['label'],
                "top_score": top['score']
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
    else:
        # Fallback para requests
        url = f"https://api-inference.huggingface.co/models/{model}"
        try:
            response = requests.post(
                url,
                headers={"Authorization": f"Bearer {API_KEY}"},
                json={"inputs": text},
                timeout=30
            )
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list) and len(data) > 0:
                    scores = data[0]
                    top = max(scores, key=lambda x: x['score'])
                    return {
                        "success": True,
                        "scores": scores,
                        "top_label": top['label'],
                        "top_score": top['score']
                    }
            return {"success": False, "error": f"API error: {response.status_code}"}
        except Exception as e:
            return {"success": False, "error": str(e)}


def normalize_label(label: str) -> str:
    """Normaliza o label retornado pela API."""
    label_lower = label.lower()
    if 'positive' in label_lower:
        return 'positive'
    elif 'negative' in label_lower:
        return 'negative'
    return 'neutral'


def run_tests():
    """Executa os testes de sentimento."""
    print("=" * 60)
    print("🧪 TESTE DO SISTEMA DE INTELIGÊNCIA - ANÁLISE DE SENTIMENTO")
    print("=" * 60)
    print(f"Timestamp: {datetime.now().isoformat()}")
    print(f"API Key: {API_KEY[:10]}...")
    print(f"Modelo: {MODEL_MULTILINGUAL}")
    print(f"HuggingFace Hub: {'✅ Instalado' if HAS_HF_HUB else '❌ Usando requests'}")
    print()
    
    # Teste modelo multilíngue (português)
    print("📊 Testando modelo MULTILÍNGUE (português)")
    print("-" * 60)
    
    correct = 0
    total = len(TEST_TEXTS_PT)
    results = []
    
    for text, expected in TEST_TEXTS_PT:
        result = analyze_sentiment(text, use_multilingual=True)
        
        if result["success"]:
            predicted = normalize_label(result["top_label"])
            is_correct = predicted == expected
            correct += 1 if is_correct else 0
            
            status = "✅" if is_correct else "❌"
            print(f"{status} '{text[:40]}...'")
            print(f"   Esperado: {expected} | Previsto: {predicted} ({result['top_score']:.2%})")
            
            results.append({
                "text": text,
                "expected": expected,
                "predicted": predicted,
                "score": result["top_score"],
                "correct": is_correct
            })
        else:
            print(f"⚠️ Erro: {result['error']}")
            print(f"   Texto: '{text[:40]}...'")
    
    accuracy = correct / total * 100 if total > 0 else 0
    print()
    print(f"📈 Acurácia modelo multilíngue: {accuracy:.1f}% ({correct}/{total})")
    print()
    
    print("=" * 60)
    print("📋 RESUMO DOS RESULTADOS")
    print("=" * 60)
    
    # Análise por categoria
    by_category = {"positive": [], "negative": [], "neutral": []}
    for r in results:
        by_category[r["expected"]].append(r)
    
    for category, items in by_category.items():
        if items:
            category_correct = sum(1 for i in items if i["correct"])
            category_accuracy = category_correct / len(items) * 100
            avg_confidence = sum(i["score"] for i in items) / len(items)
            emoji = {"positive": "😊", "negative": "😔", "neutral": "😐"}[category]
            print(f"  {emoji} {category.upper()}: {category_accuracy:.0f}% acurácia, {avg_confidence:.1%} confiança média")
    
    print()
    print("✨ Teste concluído!")
    
    # Salvar resultados
    output = {
        "timestamp": datetime.now().isoformat(),
        "model": MODEL_MULTILINGUAL,
        "accuracy": accuracy,
        "total_tests": total,
        "correct": correct,
        "results": results
    }
    
    os.makedirs("scripts", exist_ok=True)
    with open("scripts/sentiment_test_results.json", "w") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    
    print(f"📁 Resultados salvos em: scripts/sentiment_test_results.json")
    
    return accuracy


def interactive_test():
    """Modo interativo para testar textos."""
    print("=" * 60)
    print("🎯 MODO INTERATIVO - Digite textos para análise")
    print("Digite 'sair' para encerrar")
    print("=" * 60)
    
    while True:
        text = input("\n📝 Texto: ").strip()
        if text.lower() == 'sair':
            break
        
        if not text:
            continue
        
        result = analyze_sentiment(text)
        
        if result["success"]:
            print(f"\n🔍 Resultado:")
            for score in result["scores"]:
                bar = "█" * int(score['score'] * 20)
                print(f"   {score['label']}: {bar} {score['score']:.1%}")
            
            predicted = normalize_label(result["top_label"])
            emoji = {"positive": "😊", "negative": "😔", "neutral": "😐"}[predicted]
            print(f"\n   Sentimento: {emoji} {predicted.upper()} ({result['top_score']:.1%})")
        else:
            print(f"❌ Erro: {result['error']}")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "--interactive":
        interactive_test()
    else:
        run_tests()
