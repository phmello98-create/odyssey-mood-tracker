#!/usr/bin/env python3
"""
🤖 MODELOS PRÉ-TREINADOS PARA ANÁLISE DE EMOÇÕES

Este script lista e avalia modelos TFLite pré-treinados disponíveis
para análise de texto/emoções que podem ser usados no app Odyssey.

Modelos Recomendados:
1. MobileBERT (Google) - Leve e rápido para mobile
2. DistilBERT - Versão compacta do BERT
3. TinyBERT - Ultra compacto para on-device
4. Sentiment Analysis Model (TF Hub)

Uso:
  python scripts/tflite_models_info.py
  python scripts/tflite_models_info.py --download mobileBERT
  python scripts/tflite_models_info.py --convert custom_model.h5
"""

import argparse
import os
import sys

# Modelos pré-treinados disponíveis
PRETRAINED_MODELS = {
    'mobileBERT': {
        'name': 'MobileBERT',
        'source': 'TensorFlow Hub',
        'url': 'https://tfhub.dev/tensorflow/lite-model/mobilebert/1/metadata/1',
        'size_mb': 100,
        'languages': ['en'],
        'tasks': ['text_classification', 'sentiment_analysis'],
        'accuracy': '88%',
        'inference_ms': 200,
        'description': 'Versão otimizada do BERT para mobile. Bom equilíbrio entre precisão e performance.',
        'flutter_package': 'tflite_flutter',
        'pros': [
            'Otimizado para mobile',
            'Suporte oficial do Google',
            'Boa precisão',
            'Documentação completa',
        ],
        'cons': [
            'Apenas inglês nativamente',
            '100MB pode ser grande para alguns apps',
            'Requer pré-processamento de texto',
        ],
    },
    'sentimentModel': {
        'name': 'Sentiment Analysis',
        'source': 'TensorFlow Lite Model Maker',
        'url': 'https://www.tensorflow.org/lite/models/text/sentiment_analysis',
        'size_mb': 2,
        'languages': ['en', 'pt-br (com fine-tuning)'],
        'tasks': ['sentiment_analysis'],
        'accuracy': '85%',
        'inference_ms': 50,
        'description': 'Modelo leve para análise de sentimento. Perfeito para classificação positivo/negativo.',
        'flutter_package': 'tflite_flutter',
        'pros': [
            'Ultra leve (2MB)',
            'Muito rápido',
            'Fácil de usar',
            'Pode ser fine-tuned para português',
        ],
        'cons': [
            'Menos nuances que BERT',
            'Precisa de fine-tuning para PT-BR',
        ],
    },
    'textClassification': {
        'name': 'Text Classification',
        'source': 'TensorFlow Lite',
        'url': 'https://www.tensorflow.org/lite/examples/text_classification/overview',
        'size_mb': 0.5,
        'languages': ['en'],
        'tasks': ['text_classification'],
        'accuracy': '82%',
        'inference_ms': 20,
        'description': 'Modelo básico de classificação de texto. Muito leve e rápido.',
        'flutter_package': 'tflite_flutter',
        'pros': [
            'Extremamente leve',
            'Inferência super rápida',
            'Bom para casos simples',
        ],
        'cons': [
            'Precisão limitada',
            'Apenas inglês',
            'Sem embeddings contextuais',
        ],
    },
    'distilBERT': {
        'name': 'DistilBERT',
        'source': 'Hugging Face',
        'url': 'https://huggingface.co/distilbert-base-uncased',
        'size_mb': 250,
        'languages': ['en', 'multilingual'],
        'tasks': ['text_classification', 'sentiment_analysis', 'NER', 'QA'],
        'accuracy': '95%',
        'inference_ms': 150,
        'description': '60% menor que BERT com 97% da performance. Excelente para produção.',
        'flutter_package': 'tflite_flutter (requer conversão)',
        'pros': [
            'Alta precisão',
            'Versão multilíngue disponível',
            'Bem documentado',
            'Comunidade ativa',
        ],
        'cons': [
            '250MB é pesado para mobile',
            'Requer conversão para TFLite',
            'Mais complexo de integrar',
        ],
    },
    'mBERT': {
        'name': 'Multilingual BERT (mBERT)',
        'source': 'Google',
        'url': 'https://github.com/google-research/bert/blob/master/multilingual.md',
        'size_mb': 680,
        'languages': ['104 idiomas incluindo PT-BR'],
        'tasks': ['text_classification', 'sentiment_analysis', 'NER'],
        'accuracy': '92%',
        'inference_ms': 300,
        'description': 'BERT treinado em 104 idiomas. Suporta português nativamente.',
        'flutter_package': 'tflite_flutter (requer conversão)',
        'pros': [
            'Suporta português nativamente',
            'Alta precisão',
            'Versátil',
        ],
        'cons': [
            '680MB é muito grande para mobile',
            'Lento para inferência on-device',
            'Melhor usar via API',
        ],
    },
    'emotionBERT': {
        'name': 'Emotion Detection (GoEmotions)',
        'source': 'Google Research',
        'url': 'https://github.com/google-research/google-research/tree/master/goemotions',
        'size_mb': 440,
        'languages': ['en'],
        'tasks': ['emotion_detection'],
        'accuracy': '48% (27 emoções)',
        'inference_ms': 250,
        'description': 'Detecta 27 emoções diferentes (alegria, tristeza, raiva, medo, etc).',
        'flutter_package': 'tflite_flutter (requer conversão)',
        'emotions_detected': [
            'admiration', 'amusement', 'anger', 'annoyance', 'approval',
            'caring', 'confusion', 'curiosity', 'desire', 'disappointment',
            'disapproval', 'disgust', 'embarrassment', 'excitement', 'fear',
            'gratitude', 'grief', 'joy', 'love', 'nervousness', 'optimism',
            'pride', 'realization', 'relief', 'remorse', 'sadness', 'surprise',
        ],
        'pros': [
            '27 emoções diferentes',
            'Perfeito para mood tracking',
            'Dataset público disponível',
        ],
        'cons': [
            'Apenas inglês',
            'Precisa de conversão',
            'Arquivo grande',
        ],
    },
}

# Alternativas leves para on-device
LIGHTWEIGHT_ALTERNATIVES = {
    'lexicon': {
        'name': 'Análise Léxica (Sem ML)',
        'description': 'Usa dicionários de palavras positivas/negativas. Zero dependências.',
        'size_mb': 0.1,
        'languages': ['pt-br', 'en'],
        'accuracy': '70%',
        'inference_ms': 5,
        'implementation': '''
// Dart implementation
class LexiconAnalyzer {
  static const positiveWords = ['feliz', 'alegre', 'ótimo', 'maravilhoso', ...];
  static const negativeWords = ['triste', 'ruim', 'péssimo', 'terrível', ...];
  
  double analyzeSentiment(String text) {
    final words = text.toLowerCase().split(' ');
    int positive = 0;
    int negative = 0;
    
    for (final word in words) {
      if (positiveWords.contains(word)) positive++;
      if (negativeWords.contains(word)) negative++;
    }
    
    if (positive + negative == 0) return 0.5;
    return positive / (positive + negative);
  }
}
''',
    },
    'regex_patterns': {
        'name': 'Padrões Regex',
        'description': 'Detecta padrões de texto associados a emoções.',
        'size_mb': 0,
        'languages': ['pt-br', 'en'],
        'accuracy': '65%',
        'inference_ms': 2,
        'patterns': {
            'joy': [r'(?i)(feliz|alegr|content|maravilh)', r'😊|😄|🎉'],
            'sadness': [r'(?i)(trist|chorand|deprimi|sozinha?)', r'😢|😭|💔'],
            'anger': [r'(?i)(raiv|irritad|ódio|furi)', r'😡|🤬|💢'],
            'fear': [r'(?i)(med|assust|ansied|pânic)', r'😰|😨|😱'],
            'surprise': [r'(?i)(surpres|espant|chocad)', r'😮|😲|🤯'],
        },
    },
    'word_embeddings': {
        'name': 'Word Embeddings Compactos',
        'description': 'Embeddings pré-computados de 50-100 dimensões.',
        'size_mb': 5,
        'languages': ['pt-br'],
        'accuracy': '78%',
        'inference_ms': 20,
        'recommendation': 'Use FastText comprimido ou Word2Vec reduzido.',
    },
}

# Recomendação para o Odyssey
ODYSSEY_RECOMMENDATION = """
╔══════════════════════════════════════════════════════════════════════╗
║                    🎯 RECOMENDAÇÃO PARA ODYSSEY                       ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                       ║
║  ABORDAGEM HÍBRIDA (Melhor custo-benefício):                         ║
║                                                                       ║
║  1. ON-DEVICE (Rápido, Offline):                                     ║
║     • Análise Léxica PT-BR (dicionário de palavras)                  ║
║     • Padrões Regex para emoções                                      ║
║     • TFLite Sentiment Model (2MB) para análise básica               ║
║                                                                       ║
║  2. CLOUD (Quando online, para análises profundas):                  ║
║     • Google Cloud Natural Language API                               ║
║     • OpenAI API (GPT para análise contextual)                       ║
║     • Hugging Face Inference API                                      ║
║                                                                       ║
║  IMPLEMENTAÇÃO SUGERIDA:                                             ║
║                                                                       ║
║  📱 Notas curtas (< 50 palavras) → Análise léxica local              ║
║  📝 Notas médias (50-200 palavras) → TFLite Sentiment                ║
║  📖 Notas longas/diário → Cloud API (com cache)                      ║
║                                                                       ║
║  PRÓXIMOS PASSOS:                                                     ║
║  1. Implementar LexiconAnalyzer em Dart                              ║
║  2. Baixar TFLite Sentiment Model                                    ║
║  3. Criar fallback para Cloud API                                    ║
║  4. Cachear resultados de análise                                    ║
║                                                                       ║
╚══════════════════════════════════════════════════════════════════════╝
"""


def print_model_info(model_key: str):
    """Imprime informações detalhadas de um modelo."""
    if model_key not in PRETRAINED_MODELS:
        print(f"❌ Modelo '{model_key}' não encontrado")
        return
    
    model = PRETRAINED_MODELS[model_key]
    
    print(f"\n{'='*60}")
    print(f"📦 {model['name']}")
    print(f"{'='*60}")
    print(f"Fonte: {model['source']}")
    print(f"URL: {model['url']}")
    print(f"Tamanho: {model['size_mb']} MB")
    print(f"Idiomas: {', '.join(model['languages'])}")
    print(f"Tarefas: {', '.join(model['tasks'])}")
    print(f"Precisão: {model['accuracy']}")
    print(f"Inferência: {model['inference_ms']} ms")
    print(f"\n📝 {model['description']}")
    
    print("\n✅ Prós:")
    for pro in model['pros']:
        print(f"   • {pro}")
    
    print("\n❌ Contras:")
    for con in model['cons']:
        print(f"   • {con}")
    
    if 'emotions_detected' in model:
        print(f"\n🎭 Emoções detectadas ({len(model['emotions_detected'])}):")
        emotions = model['emotions_detected']
        for i in range(0, len(emotions), 5):
            print(f"   {', '.join(emotions[i:i+5])}")


def list_all_models():
    """Lista todos os modelos disponíveis."""
    print("\n" + "="*70)
    print("🤖 MODELOS PRÉ-TREINADOS PARA ANÁLISE DE EMOÇÕES")
    print("="*70)
    
    print("\n📦 MODELOS BASEADOS EM ML:")
    print("-"*50)
    
    for key, model in PRETRAINED_MODELS.items():
        size_indicator = "🟢" if model['size_mb'] < 10 else ("🟡" if model['size_mb'] < 100 else "🔴")
        print(f"\n  {size_indicator} {model['name']} ({model['size_mb']}MB)")
        print(f"     Precisão: {model['accuracy']} | Inferência: {model['inference_ms']}ms")
        print(f"     Idiomas: {', '.join(model['languages'])}")
    
    print("\n\n🪶 ALTERNATIVAS LEVES (SEM ML PESADO):")
    print("-"*50)
    
    for key, alt in LIGHTWEIGHT_ALTERNATIVES.items():
        print(f"\n  🟢 {alt['name']} ({alt['size_mb']}MB)")
        print(f"     Precisão: {alt['accuracy']} | Inferência: {alt['inference_ms']}ms")
        print(f"     {alt['description']}")
    
    print(ODYSSEY_RECOMMENDATION)


def generate_dart_lexicon():
    """Gera código Dart para análise léxica em português."""
    
    dart_code = '''
// AUTO-GENERATED - Lexicon Analyzer for Portuguese
// Gerado por scripts/tflite_models_info.py

/// Analisador léxico para português brasileiro
/// Não requer ML - usa dicionário de palavras
class PortugueseLexiconAnalyzer {
  // Palavras positivas em português
  static const positiveWords = {
    // Emoções positivas
    'feliz', 'alegre', 'contente', 'satisfeito', 'animado',
    'empolgado', 'entusiasmado', 'radiante', 'eufórico', 'extasiado',
    'grato', 'agradecido', 'abençoado', 'sortudo', 'privilegiado',
    'amado', 'querido', 'adorado', 'apreciado', 'valorizado',
    'tranquilo', 'sereno', 'calmo', 'relaxado', 'zen',
    'confiante', 'seguro', 'forte', 'capaz', 'competente',
    'orgulhoso', 'realizado', 'vitorioso', 'bem-sucedido',
    'inspirado', 'motivado', 'determinado', 'focado',
    'esperançoso', 'otimista', 'positivo', 'confiante',
    
    // Experiências positivas
    'maravilhoso', 'incrível', 'fantástico', 'excelente', 'ótimo',
    'perfeito', 'sensacional', 'espetacular', 'extraordinário',
    'bom', 'legal', 'bacana', 'massa', 'top', 'demais',
    'lindo', 'bonito', 'belo', 'gracioso', 'encantador',
    'divertido', 'engraçado', 'hilário', 'prazeroso',
    'delicioso', 'gostoso', 'saboroso', 'apetitoso',
    
    // Ações positivas
    'consegui', 'conquistei', 'alcancei', 'realizei', 'completei',
    'superei', 'venci', 'ganhei', 'melhorei', 'progredi',
    'aprendi', 'cresci', 'evolui', 'desenvolvi',
    'amei', 'adorei', 'curti', 'aprovei', 'apreciei',
  };

  // Palavras negativas em português
  static const negativeWords = {
    // Emoções negativas
    'triste', 'deprimido', 'melancólico', 'abatido', 'desanimado',
    'frustrado', 'decepcionado', 'desiludido', 'desapontado',
    'ansioso', 'nervoso', 'preocupado', 'apreensivo', 'tenso',
    'estressado', 'sobrecarregado', 'exausto', 'esgotado', 'cansado',
    'irritado', 'bravo', 'furioso', 'irado', 'revoltado',
    'com raiva', 'zangado', 'indignado', 'enfurecido',
    'medo', 'assustado', 'apavorado', 'aterrorizado', 'temor',
    'inseguro', 'vulnerável', 'frágil', 'incapaz', 'impotente',
    'solitário', 'sozinho', 'abandonado', 'isolado', 'rejeitado',
    'culpado', 'arrependido', 'envergonhado', 'humilhado',
    
    // Experiências negativas
    'terrível', 'horrível', 'péssimo', 'ruim', 'mal',
    'difícil', 'complicado', 'problemático', 'desafiador',
    'doloroso', 'sofrido', 'angustiante', 'agonizante',
    'chato', 'entediante', 'monótono', 'tedioso',
    'feio', 'horrendo', 'desagradável', 'repugnante',
    
    // Ações/situações negativas
    'perdi', 'fracassei', 'falhei', 'errei', 'estraguei',
    'chorei', 'chorar', 'chorando', 'lágrimas',
    'odiei', 'detestei', 'não gostei', 'não suportei',
    'desisti', 'abandonei', 'larguei', 'parei',
    'briguei', 'discuti', 'conflito', 'confusão',
  };

  // Intensificadores
  static const intensifiers = {
    'muito': 1.5,
    'demais': 1.5,
    'super': 1.5,
    'extremamente': 2.0,
    'incrivelmente': 2.0,
    'absurdamente': 2.0,
    'pouco': 0.5,
    'levemente': 0.5,
    'um pouco': 0.5,
  };

  // Negadores
  static const negators = {'não', 'nem', 'nunca', 'jamais', 'nada'};

  /// Analisa o sentimento de um texto
  /// Retorna um valor entre 0 (muito negativo) e 1 (muito positivo)
  static double analyzeSentiment(String text) {
    final words = _tokenize(text.toLowerCase());
    
    if (words.isEmpty) return 0.5;
    
    double positiveScore = 0;
    double negativeScore = 0;
    double multiplier = 1.0;
    bool negated = false;
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      
      // Check for negators
      if (negators.contains(word)) {
        negated = true;
        continue;
      }
      
      // Check for intensifiers
      if (intensifiers.containsKey(word)) {
        multiplier = intensifiers[word]!;
        continue;
      }
      
      // Score the word
      if (positiveWords.contains(word)) {
        if (negated) {
          negativeScore += multiplier;
        } else {
          positiveScore += multiplier;
        }
      } else if (negativeWords.contains(word)) {
        if (negated) {
          positiveScore += multiplier;
        } else {
          negativeScore += multiplier;
        }
      }
      
      // Reset modifiers after each scored word
      multiplier = 1.0;
      negated = false;
    }
    
    final total = positiveScore + negativeScore;
    if (total == 0) return 0.5;
    
    return positiveScore / total;
  }

  /// Detecta emoções específicas no texto
  static Map<String, double> detectEmotions(String text) {
    final lowerText = text.toLowerCase();
    
    // Padrões de emoção
    final emotionPatterns = {
      'alegria': ['feliz', 'alegr', 'content', 'animad', 'empolgad', '😊', '😄', '🎉'],
      'tristeza': ['trist', 'chorand', 'deprimi', 'melanc', 'abatid', '😢', '😭', '💔'],
      'raiva': ['raiv', 'irritad', 'brav', 'furios', 'revoltad', '😡', '🤬', '💢'],
      'medo': ['med', 'assust', 'ansios', 'preocu', 'pânic', '😰', '😨', '😱'],
      'surpresa': ['surpres', 'espant', 'chocad', 'incrível', '😮', '😲', '🤯'],
      'nojo': ['nojo', 'repugn', 'asco', '🤢', '🤮'],
      'amor': ['am', 'ador', 'querid', 'paixão', '❤️', '💕', '😍'],
      'gratidão': ['grat', 'agradeç', 'obrigad', '🙏'],
    };
    
    final emotions = <String, double>{};
    
    for (final entry in emotionPatterns.entries) {
      int matches = 0;
      for (final pattern in entry.value) {
        if (lowerText.contains(pattern)) matches++;
      }
      if (matches > 0) {
        emotions[entry.key] = (matches / entry.value.length).clamp(0.0, 1.0);
      }
    }
    
    return emotions;
  }

  /// Calcula um mood score de 1-5 baseado no texto
  static double calculateMoodScore(String text) {
    final sentiment = analyzeSentiment(text);
    // Converte 0-1 para 1-5
    return 1 + (sentiment * 4);
  }

  static List<String> _tokenize(String text) {
    // Remove pontuação e divide em palavras
    return text
        .replaceAll(RegExp(r'[^\\w\\s\\u00C0-\\u017F]'), ' ')
        .split(RegExp(r'\\s+'))
        .where((w) => w.length > 1)
        .toList();
  }
}
'''
    
    return dart_code


def main():
    parser = argparse.ArgumentParser(description='TFLite Models Info')
    parser.add_argument('--model', type=str, help='Ver detalhes de um modelo específico')
    parser.add_argument('--generate-lexicon', action='store_true', help='Gera código Dart do analisador léxico')
    parser.add_argument('--list', action='store_true', help='Lista todos os modelos')
    args = parser.parse_args()
    
    if args.model:
        print_model_info(args.model)
    elif args.generate_lexicon:
        print("📝 Gerando analisador léxico em Dart...")
        dart_code = generate_dart_lexicon()
        
        output_path = 'lib/src/features/intelligence/services/lexicon_analyzer.dart'
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        with open(output_path, 'w') as f:
            f.write(dart_code)
        
        print(f"✅ Código gerado em: {output_path}")
    else:
        list_all_models()


if __name__ == '__main__':
    main()
