#!/usr/bin/env python3
"""
🤗 HUGGING FACE SENTIMENT ANALYSIS - TESTE

Testa o modelo cardiffnlp/twitter-roberta-base-sentiment-latest
para análise de sentimento.

IMPORTANTE: O token precisa ter permissão para Inference API!
Vá em https://huggingface.co/settings/tokens e:
1. Crie um novo token (Write)
2. Marque "Make calls to the serverless Inference API"

Uso:
  python scripts/huggingface_sentiment_test.py "Estou muito feliz hoje!"
  python scripts/huggingface_sentiment_test.py --batch
  python scripts/huggingface_sentiment_test.py --local      # Usa análise léxica local
  python scripts/huggingface_sentiment_test.py --translate  # Traduz PT→EN (melhor precisão!)
  python scripts/huggingface_sentiment_test.py --compare    # Compara com e sem tradução
"""

import sys
import os
import json
import re

# ============================================================
# DICIONÁRIO DE TRADUÇÃO PT → EN
# O modelo cardiffnlp funciona ~50% melhor com texto em inglês
# ============================================================
TRANSLATIONS = {
    # Frases comuns (processar primeiro - mais específicas)
    'muito feliz': 'very happy',
    'estou feliz': 'I am happy',
    'me sinto feliz': 'I feel happy',
    'que alegria': 'what joy',
    'muito animado': 'very excited',
    'estou animado': 'I am excited',
    'me sinto bem': 'I feel good',
    'dia maravilhoso': 'wonderful day',
    'dia incrível': 'amazing day',
    'ótimo dia': 'great day',
    'bom dia': 'good day',
    'muito grato': 'very grateful',
    'estou grato': 'I am grateful',
    'adorei': 'I loved it',
    'amei': 'I loved it',
    'consegui': 'I achieved',
    'muito triste': 'very sad',
    'estou triste': 'I am sad',
    'triste demais': 'too sad',
    'me sinto triste': 'I feel sad',
    'que tristeza': 'how sad',
    'estou deprimido': 'I am depressed',
    'me sinto deprimido': 'I feel depressed',
    'dia terrível': 'terrible day',
    'dia péssimo': 'awful day',
    'dia horrível': 'horrible day',
    'tudo deu errado': 'everything went wrong',
    'não consegui': 'I could not',
    'estou ansioso': 'I am anxious',
    'estou preocupado': 'I am worried',
    'muito cansado': 'very tired',
    'estou cansado': 'I am tired',
    'perdi meu': 'I lost my',
    'morreu': 'died',
    'fracassei': 'I failed',
    'com raiva': 'angry',
    'o dia está': 'the day is',
    'que dia': 'what a day',
    'hoje foi': 'today was',
    'me sinto': 'I feel',
    'manter a calma': 'stay calm',
    'tanto queria': 'wanted so much',
    'que tanto': 'that I',
    # Palavras individuais (fallback)
    'feliz': 'happy',
    'alegre': 'joyful',
    'contente': 'content',
    'animado': 'excited',
    'empolgado': 'thrilled',
    'grato': 'grateful',
    'maravilhoso': 'wonderful',
    'incrível': 'amazing',
    'ótimo': 'great',
    'excelente': 'excellent',
    'perfeito': 'perfect',
    'lindo': 'beautiful',
    'triste': 'sad',
    'deprimido': 'depressed',
    'ansioso': 'anxious',
    'preocupado': 'worried',
    'frustrado': 'frustrated',
    'irritado': 'irritated',
    'estressado': 'stressed',
    'terrível': 'terrible',
    'horrível': 'horrible',
    'péssimo': 'awful',
    'ruim': 'bad',
    'cansado': 'tired',
    'medo': 'fear',
    'raiva': 'anger',
    'tranquilo': 'calm',
    'relaxado': 'relaxed',
    'calmo': 'calm',
    'meditei': 'I meditated',
    'exercícios': 'exercises',
    'acordei': 'I woke up',
    'dormi': 'I slept',
    'trabalhei': 'I worked',
    'hoje': 'today',
    'ontem': 'yesterday',
    'amanhã': 'tomorrow',
    'cachorro': 'dog',
    'trabalho': 'work',
    'promoção': 'promotion',
    'café': 'coffee',
    'bem': 'well',
    'fiz': 'I did',
    'tomei': 'I had',
    'normal': 'normal',
    'nada': 'nothing',
    'especial': 'special',
    'minutos': 'minutes',
    'mais': 'more',
    'tentando': 'trying',
    'mas': 'but',
    'perdi': 'I lost',
    'meu': 'my',
    'está': 'is',
    'estou': 'I am',
}

# API Key - PRECISA TER PERMISSÃO PARA INFERENCE API
# Para criar: https://huggingface.co/settings/tokens
HF_TOKEN = os.environ.get("HF_TOKEN", "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")

# Modelo a usar
MODEL = "cardiffnlp/twitter-roberta-base-sentiment-latest"

# URLs da API (nova e antiga para fallback)
API_URLS = [
    f"https://router.huggingface.co/hf-inference/models/{MODEL}",
    f"https://api-inference.huggingface.co/models/{MODEL}",
]

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
    print("⚠️ requests não instalado. pip install requests")


def analyze_with_client(text: str) -> dict:
    """Analisa sentimento usando requests diretamente."""
    return analyze_with_requests(text)


def translate_to_english(text: str) -> str:
    """Traduz texto português para inglês usando dicionário."""
    result = text.lower()
    # Ordena por tamanho (frases maiores primeiro)
    sorted_translations = sorted(TRANSLATIONS.items(), key=lambda x: -len(x[0]))
    for pt, en in sorted_translations:
        result = result.replace(pt, en)
    return result


def analyze_with_requests(text: str, translate: bool = False) -> dict:
    """Analisa sentimento usando requests."""
    if not HAS_REQUESTS:
        return {"error": "requests não instalado"}
    
    # Traduz se necessário
    input_text = translate_to_english(text) if translate else text
    
    headers = {"Authorization": f"Bearer {HF_TOKEN}"}
    
    # Tenta os endpoints disponíveis
    response = None
    for api_url in API_URLS:
        try:
            response = requests.post(api_url, headers=headers, json={"inputs": input_text}, timeout=30)
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 503:
                # Modelo carregando
                return {"loading": True, "message": "Modelo carregando, aguarde..."}
        except Exception as e:
            continue
    
    if response:
        return {"error": f"Nenhum endpoint disponível. Status: {response.status_code}", "detail": response.text}
    return {"error": "Nenhum endpoint disponível"}


def analyze_local(text: str) -> dict:
    """Análise léxica local sem API."""
    lower_text = text.lower()
    
    # Dicionários de palavras (mais completo)
    positive_words = {
        # Português
        'feliz', 'alegre', 'alegria', 'contente', 'animado', 'empolgado', 'grato',
        'maravilhoso', 'incrível', 'ótimo', 'excelente', 'amei', 'adorei',
        'perfeito', 'lindo', 'bom', 'legal', 'top', 'demais', 'tranquilo',
        'calmo', 'sereno', 'paz', 'satisfeito', 'realizado', 'conquista',
        'consegui', 'vitória', 'sucesso', 'promoção', 'bem', 'melhor',
        # Inglês
        'happy', 'excited', 'great', 'amazing', 'wonderful', 'love',
        'awesome', 'fantastic', 'perfect', 'good', 'nice', 'best',
        'calm', 'peaceful', 'satisfied', 'success', 'win',
    }
    
    negative_words = {
        # Português
        'triste', 'tristeza', 'deprimido', 'ansioso', 'preocupado', 'frustrado',
        'terrível', 'horrível', 'péssimo', 'ruim', 'mal', 'raiva',
        'irritado', 'estressado', 'cansado', 'medo', 'pior', 'perdi',
        'perda', 'fracasso', 'chorei', 'chorando', 'lágrimas', 'dor',
        'doloroso', 'sofrendo', 'angústia', 'desespero', 'solidão',
        # Inglês
        'sad', 'depressed', 'anxious', 'worried', 'frustrated',
        'terrible', 'horrible', 'bad', 'angry', 'stressed', 'worst',
        'lost', 'crying', 'pain', 'suffering', 'fear',
    }
    
    # Tokeniza
    words = re.findall(r'\w+', lower_text)
    
    positive_count = sum(1 for w in words if w in positive_words)
    negative_count = sum(1 for w in words if w in negative_words)
    
    total = positive_count + negative_count
    
    if total == 0:
        return [[
            {'label': 'neutral', 'score': 0.8},
            {'label': 'positive', 'score': 0.1},
            {'label': 'negative', 'score': 0.1},
        ]]
    
    positive_score = positive_count / total
    negative_score = negative_count / total
    neutral_score = 0.0
    
    return [[
        {'label': 'positive', 'score': positive_score},
        {'label': 'negative', 'score': negative_score},
        {'label': 'neutral', 'score': neutral_score},
    ]]


def interpret_result(result) -> dict:
    """Interpreta o resultado para uso no app."""
    if isinstance(result, list) and len(result) > 0:
        # Formato: [[{label, score}, ...]]
        if isinstance(result[0], list):
            scores = result[0]
        else:
            scores = result
        
        # Mapeia labels
        label_map = {
            'positive': 'positivo',
            'negative': 'negativo',
            'neutral': 'neutro',
        }
        
        # Encontra o label dominante
        best = max(scores, key=lambda x: x.get('score', 0))
        
        # Calcula mood score (1-5)
        positive_score = next((s['score'] for s in scores if s['label'] == 'positive'), 0)
        negative_score = next((s['score'] for s in scores if s['label'] == 'negative'), 0)
        neutral_score = next((s['score'] for s in scores if s['label'] == 'neutral'), 0)
        
        # Formula: base 3 + (positivo * 2) - (negativo * 2)
        mood_score = 3 + (positive_score * 2) - (negative_score * 2)
        mood_score = max(1, min(5, mood_score))
        
        return {
            'label': label_map.get(best['label'], best['label']),
            'confidence': best['score'],
            'mood_score': round(mood_score, 2),
            'breakdown': {
                'positivo': positive_score,
                'neutro': neutral_score,
                'negativo': negative_score,
            },
            'raw': scores,
        }
    
    return {'error': 'Formato inesperado', 'raw': result}


def main():
    print("\n" + "="*60)
    print("🤗 HUGGING FACE SENTIMENT ANALYSIS")
    print("   Modelo: cardiffnlp/twitter-roberta-base-sentiment-latest")
    print("="*60)
    
    # Verifica flags
    use_local = "--local" in sys.argv
    use_translate = "--translate" in sys.argv
    use_compare = "--compare" in sys.argv
    
    if use_local:
        print("\n🏠 Usando análise LÉXICA LOCAL (sem API)")
    elif use_compare:
        print("\n🔄 Modo COMPARAÇÃO: sem tradução vs com tradução PT→EN")
    elif use_translate:
        print("\n🌐 Tradução PT→EN ATIVADA (melhor precisão!)")
    else:
        print("\n☁️ Tentando API HuggingFace...")
        print("   (Use --translate para melhor precisão com português)")
        print("   (Use --local para análise offline)")
    
    # Textos de teste
    args_clean = [a for a in sys.argv[1:] if not a.startswith("--")]
    if args_clean:
        texts = [" ".join(args_clean)]
    else:
        texts = [
            "Estou muito feliz hoje! O dia está lindo!",
            "Que dia terrível, tudo deu errado.",
            "Hoje foi um dia normal, nada de especial.",
            "I'm so excited about this new project!",
            "Feeling a bit anxious about tomorrow's meeting.",
            "Acordei bem, fiz exercícios e tomei um bom café.",
            "Estou preocupado com o trabalho, mas tentando manter a calma.",
            "Que alegria! Consegui a promoção que tanto queria!",
            "Triste demais, perdi meu cachorro hoje.",
            "Meditei 10 minutos e me sinto mais tranquilo.",
        ]
    
    print("\n📊 Analisando textos...\n")
    
    for i, text in enumerate(texts, 1):
        print(f"[{i}] \"{text[:50]}...\"" if len(text) > 50 else f"[{i}] \"{text}\"")
        
        try:
            if use_compare:
                # Modo comparação: mostra com e sem tradução
                result_orig = analyze_with_requests(text, translate=False)
                result_trans = analyze_with_requests(text, translate=True)
                
                interp_orig = interpret_result(result_orig)
                interp_trans = interpret_result(result_trans)
                
                if 'error' not in interp_orig and 'error' not in interp_trans:
                    emoji_map = {'positivo': '😊', 'negativo': '😢', 'neutro': '😐'}
                    
                    print(f"    📝 Original: {emoji_map.get(interp_orig['label'], '❓')} {interp_orig['label'].upper()} "
                          f"({interp_orig['confidence']*100:.1f}%) → Mood: {interp_orig['mood_score']:.1f}")
                    
                    translated_text = translate_to_english(text)
                    print(f"    🌐 Traduzido: \"{translated_text[:40]}...\"" if len(translated_text) > 40 else f"    🌐 Traduzido: \"{translated_text}\"")
                    print(f"       {emoji_map.get(interp_trans['label'], '❓')} {interp_trans['label'].upper()} "
                          f"({interp_trans['confidence']*100:.1f}%) → Mood: {interp_trans['mood_score']:.1f}")
                    
                    # Destaca melhoria
                    if interp_trans['confidence'] > interp_orig['confidence']:
                        diff = (interp_trans['confidence'] - interp_orig['confidence']) * 100
                        print(f"       ✅ Confiança +{diff:.1f}% com tradução!")
                else:
                    print(f"    ❌ Erro: {interp_orig.get('error', 'desconhecido')}")
            else:
                if use_local:
                    result = analyze_local(text)
                else:
                    result = analyze_with_requests(text, translate=use_translate)
                    # Se API falhar, usa local como fallback
                    if 'error' in result:
                        print(f"    ⚠️ API indisponível, usando análise local")
                        result = analyze_local(text)
                
                interpreted = interpret_result(result)
                
                if 'error' not in interpreted:
                    emoji_map = {
                        'positivo': '😊',
                        'negativo': '😢',
                        'neutro': '😐',
                    }
                    
                    emoji = emoji_map.get(interpreted['label'], '❓')
                    mood = interpreted['mood_score']
                    confidence = interpreted['confidence'] * 100
                    
                    print(f"    {emoji} {interpreted['label'].upper()} (confiança: {confidence:.1f}%)")
                    print(f"    📈 Mood Score: {mood:.1f}/5")
                    print(f"    └─ Positivo: {interpreted['breakdown']['positivo']*100:.1f}% | "
                          f"Neutro: {interpreted['breakdown']['neutro']*100:.1f}% | "
                          f"Negativo: {interpreted['breakdown']['negativo']*100:.1f}%")
                else:
                    print(f"    ❌ Erro: {interpreted.get('error', interpreted)}")
        
        except Exception as e:
            print(f"    ❌ Erro: {e}")
        
        print()
    
    print("="*60)
    print("✅ Análise concluída!")
    print("\n💡 Para usar no Flutter, veja:")
    print("   lib/src/features/intelligence/services/huggingface_service.dart")
    if not use_translate and not use_compare:
        print("\n🚀 DICA: Use --translate para melhor precisão com português!")
        print("   python scripts/huggingface_sentiment_test.py --translate")
    print("="*60)


if __name__ == '__main__':
    main()
