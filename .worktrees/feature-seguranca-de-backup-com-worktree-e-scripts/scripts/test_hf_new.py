#!/usr/bin/env python3
"""Teste usando a nova API do HuggingFace Hub"""

from huggingface_hub import InferenceClient
import os

API_KEY = os.environ.get('HF_TOKEN', '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')

# Testar com provider hf-inference
print("Testando com InferenceClient...")

try:
    client = InferenceClient(
        provider="hf-inference",
        api_key=API_KEY,
    )

    # Testar em português
    texts = [
        "Hoje foi um dia maravilhoso! Estou muito feliz.",
        "Estou triste e cansado, nada dá certo.",
        "Fui ao mercado e comprei frutas.",
    ]

    for text in texts:
        result = client.text_classification(
            text,
            model="cardiffnlp/twitter-xlm-roberta-base-sentiment-multilingual",
        )
        print(f"\nTexto: '{text[:50]}...'")
        print(f"Resultado: {result}")

except Exception as e:
    print(f"Erro: {e}")
    
    # Tentar outro modelo
    print("\nTentando modelo alternativo...")
    try:
        client = InferenceClient(api_key=API_KEY)
        
        for text in ["I am happy today!", "I feel sad."]:
            result = client.text_classification(
                text,
                model="distilbert-base-uncased-finetuned-sst-2-english",
            )
            print(f"Texto: '{text}' => {result}")
    except Exception as e2:
        print(f"Erro alternativo: {e2}")
