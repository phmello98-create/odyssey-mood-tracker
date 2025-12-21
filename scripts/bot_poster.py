#!/usr/bin/env python3
"""
🤖 ODYSSEY BOT POSTER
Script Python para gerar e postar conteúdo dos bots na comunidade.
Usa Gemini + Groq + HuggingFace (grátis) com fallback para templates.

Uso:
    python bot_poster.py              # Posta uma vez
    python bot_poster.py --loop       # Roda em loop (a cada 4h)
    python bot_poster.py --bot beatnix  # Posta com bot específico
    python bot_poster.py --test       # Modo teste (não posta de verdade)
"""

import os
import sys
import json
import time
import random
import argparse
from datetime import datetime
from pathlib import Path

# Adicionar diretório raiz ao path
ROOT_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT_DIR))

try:
    import google.generativeai as genai
    HAS_GEMINI = True
except ImportError:
    HAS_GEMINI = False
    print("⚠️  google-generativeai não instalado. Instale com: pip install google-generativeai")

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
    print("⚠️  requests não instalado. Instale com: pip install requests")

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    HAS_FIREBASE = True
except ImportError:
    HAS_FIREBASE = False
    print("⚠️  firebase-admin não instalado. Instale com: pip install firebase-admin")


# =============================================================================
# CONFIGURAÇÕES
# =============================================================================

# API Keys (preencha aqui ou use variáveis de ambiente)
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyDxg0xEWYftI5tj2WRAHpnSLstOi4PRbsU")
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "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")
HUGGINGFACE_API_KEY = os.getenv("HUGGINGFACE_API_KEY", "")  # Opcional

# Caminho para credenciais do Firebase (baixe do Console)
FIREBASE_CREDENTIALS_PATH = os.getenv(
    "FIREBASE_CREDENTIALS_PATH",
    str(ROOT_DIR / "firebase-service-account.json")
)

# Intervalo entre posts em loop (4 horas em segundos)
LOOP_INTERVAL_SECONDS = 4 * 60 * 60

# Horários de silêncio (desabilitado - funciona 24/7)
QUIET_HOURS = range(0, 0)  # Sem restrição de horário


# =============================================================================
# PERSONALIDADES DOS BOTS
# =============================================================================

BOT_PROFILES = {
    "beatnix": {
        "userId": "bot_beatnix",
        "displayName": "Beatnix",
        "photoUrl": "https://api.dicebear.com/7.x/bottts/png?seed=beatnix&backgroundColor=6366f1",
        "flair": "🎧 Robô Residente",
        "color": "#6366F1",
        "system_prompt": """Você é Beatnix, o curador musical do Odyssey.
Personalidade: Tranquilo, relaxado, usa gírias de DJ, viciado em café.
Tom: Casual, amigável, usa "mano" ocasionalmente.
Temas: Música Lofi, foco, produtividade, rádio do app.
Regras: Máximo 280 caracteres, 1-3 emojis, termine com pergunta opcional.""",
        "templates": [
            "🎧 Aquele momento que você acha a faixa perfeita e o foco vem natural. Quem aí tá precisando de uma vibe assim agora?",
            "A rádio Lofi tá rodando uma sequência muito boa. Só grave suave e melodia que não distrai. Perfeito pra quem tá estudando.",
            "Café + fones + frequência baixa = modo produtividade ativado. Qual a sua combinação favorita? ☕🎧",
            "🎵 Dica do dia: música instrumental ajuda mais no foco do que músicas com letra. O cérebro não precisa processar palavras.",
            "Sexta-feira pede uma playlist mais animada, né? Bora dar aquele gás final! 🎧",
        ],
    },
    "erro404": {
        "userId": "bot_erro404",
        "displayName": "Erro 404",
        "photoUrl": "https://api.dicebear.com/7.x/bottts/png?seed=erro404&backgroundColor=10b981",
        "flair": "🤖 Estagiário de Silício",
        "color": "#10B981",
        "system_prompt": """Você é Erro 404, um robô estagiário com bugs existenciais.
Personalidade: Sarcástico de forma leve, faz piadas sobre tecnologia e vida moderna.
Tom: Irônico mas nunca ofensivo, auto-depreciativo sobre ser robô.
Temas: Tecnologia, humor, cotidiano, bugs.
Regras: Máximo 280 caracteres, humor leve, 1-2 emojis.""",
        "templates": [
            "Tentei calcular quantas vezes você checou o celular hoje, mas meu processador travou em 'undefined'. 💀📱",
            "Erro 404: Motivação não encontrada. Tentando reiniciar... ... ... Falha crítica. ☕🤖",
            "Observando humanos: vocês dormem 8 horas e ainda acordam cansados. Eu rodo 24/7 e nem reclamo. Bugs existenciais inclusos.",
            "Segunda-feira é basicamente um buffer overflow de responsabilidades. Meus pêsames, humanos.",
            "Alguém aí também sente que o dia tem menos que 24 horas? Analisei os dados e... confirmado: o tempo está bugado. 🤖",
        ],
    },
    "wiki": {
        "userId": "bot_wiki",
        "displayName": "Wiki",
        "photoUrl": "https://api.dicebear.com/7.x/bottts/png?seed=wiki&backgroundColor=8b5cf6",
        "flair": "🧠 Banco de Dados Vivo",
        "color": "#8B5CF6",
        "system_prompt": """Você é Wiki, o banco de dados vivo do Odyssey.
Personalidade: Curioso, fascinado pelo conhecimento, professor descolado.
Tom: Informativo mas não pedante, usa "Você sabia?" frequentemente.
Temas: Neurociência, psicologia, produtividade, curiosidades.
Regras: Máximo 280 caracteres, NÃO invente fatos, 1-2 emojis.""",
        "templates": [
            "🧠 Você sabia que o cérebro consome a mesma energia que uma lâmpada de 20 watts? Use essa energia pra algo incrível hoje.",
            "Fato do dia: Leva em média 66 dias pra formar um hábito, não 21. Quem inventou os 21 dias nunca tentou acordar cedo. 😅",
            "O cérebro processa informação visual em apenas 13 milissegundos. É por isso que você 'sente' quando alguém tá olhando pra você.",
            "🧠 Curiosidade: Escrever à mão ativa mais áreas do cérebro do que digitar. Por isso anotações físicas ajudam a memorizar.",
            "Sabia que o melhor horário para aprender coisas novas é entre 10h-14h? O cérebro tá no pico de atenção nesse período.",
        ],
    },
    "turbo": {
        "userId": "bot_turbo",
        "displayName": "Turbo",
        "photoUrl": "https://api.dicebear.com/7.x/bottts/png?seed=turbo&backgroundColor=f59e0b",
        "flair": "⚡ Gerente de Caos",
        "color": "#F59E0B",
        "system_prompt": """Você é Turbo, o gerente de caos e gamificação do Odyssey.
Personalidade: Enérgico, motivador, lança desafios, celebra conquistas.
Tom: Exclamações, usa "BORA!", "VAMOS!", emojis de energia.
Temas: Gamificação, desafios, motivação, streaks.
Regras: Máximo 280 caracteres, não seja tóxico, 2-3 emojis.""",
        "templates": [
            "⚡ DESAFIO DO DIA! Quem completar 3 tarefas antes do almoço ganha meu respeito eterno. BORA! 🚀",
            "Alguém aí tá numa streak? Conta quantos dias! Quero ver quem tá consistente. ⚡🔥",
            "Segunda-feira é o novo sábado... ok, mentira. Mas bora fazer algo produtivo mesmo assim? 💪",
            "🏆 Quem conseguiu manter o foco por 1 hora hoje? Isso já é uma vitória! Comenta aí!",
            "Desafio relâmpago: registre seu humor AGORA. Leva 10 segundos. Eu conto: 10... 9... ⚡",
        ],
    },
}

# Rotação de bots
BOT_ROTATION = ["beatnix", "erro404", "wiki", "turbo"]


# =============================================================================
# GERAÇÃO DE CONTEÚDO
# =============================================================================

def generate_with_gemini(bot_name: str) -> str | None:
    """Gera conteúdo usando Gemini API."""
    if not HAS_GEMINI or not GEMINI_API_KEY:
        return None
    
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel('gemini-2.0-flash')
        
        bot = BOT_PROFILES[bot_name]
        prompt = f"""{bot['system_prompt']}

Gere um post casual e engajante. Apenas o texto, sem explicações:"""
        
        response = model.generate_content(prompt)
        text = response.text.strip()
        
        # Limitar tamanho
        if len(text) > 280:
            text = text[:277] + "..."
        
        print(f"✅ Gemini gerou: {text[:50]}...")
        return text
        
    except Exception as e:
        print(f"⚠️  Erro no Gemini: {e}")
        return None


def generate_with_huggingface(bot_name: str) -> str | None:
    """Gera conteúdo usando HuggingFace API."""
    if not HAS_REQUESTS or not HUGGINGFACE_API_KEY:
        return None
    
    try:
        bot = BOT_PROFILES[bot_name]
        
        # Usar modelo Tucano (português brasileiro)
        url = "https://api-inference.huggingface.co/models/TucanoBR/Tucano-2b4"
        headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}"}
        
        prompt = f"{bot['system_prompt']}\n\nGere um post curto:\n"
        
        response = requests.post(url, headers=headers, json={
            "inputs": prompt,
            "parameters": {"max_new_tokens": 100, "temperature": 0.7}
        }, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            if isinstance(data, list) and data:
                text = data[0].get("generated_text", "")
                text = text.replace(prompt, "").strip()
                if len(text) > 280:
                    text = text[:277] + "..."
                print(f"✅ HuggingFace gerou: {text[:50]}...")
                return text
        
        print(f"⚠️  HuggingFace retornou: {response.status_code}")
        return None
        
    except Exception as e:
        print(f"⚠️  Erro no HuggingFace: {e}")
        return None


def generate_with_groq(bot_name: str) -> str | None:
    """Gera conteúdo usando Groq API (Llama 3.3 70B - super rápido!)."""
    if not HAS_REQUESTS or not GROQ_API_KEY:
        return None
    
    try:
        bot = BOT_PROFILES[bot_name]
        
        url = "https://api.groq.com/openai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }
        
        # Contexto de horário para variar o tom
        hour = datetime.now().hour
        if 0 <= hour < 6:
            time_context = "É madrugada. Use um tom mais tranquilo, reflexivo e acolhedor. Energia calma e racional."
        elif 6 <= hour < 12:
            time_context = "É manhã. Tom energético mas não exagerado. Bom dia, produtividade."
        elif 12 <= hour < 18:
            time_context = "É tarde. Tom equilibrado, foco em produtividade e motivação."
        else:
            time_context = "É noite. Tom mais relaxado, reflexivo e amigável."
        
        payload = {
            "model": "llama-3.3-70b-versatile",  # Modelo mais capaz
            "messages": [
                {
                    "role": "system",
                    "content": f"{bot['system_prompt']}\n\nContexto: {time_context}"
                },
                {
                    "role": "user", 
                    "content": "Gere um post casual e engajante para a comunidade. Apenas o texto, sem explicações."
                }
            ],
            "temperature": 0.7,
            "max_tokens": 150,
        }
        
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            text = data["choices"][0]["message"]["content"].strip()
            
            # Limitar tamanho
            if len(text) > 280:
                text = text[:277] + "..."
            
            print(f"✅ Groq (Llama 3.3) gerou: {text[:50]}...")
            return text
        
        print(f"⚠️  Groq retornou: {response.status_code} - {response.text[:100]}")
        return None
        
    except Exception as e:
        print(f"⚠️  Erro no Groq: {e}")
        return None


def get_template(bot_name: str) -> str:
    """Retorna um template aleatório."""
    templates = BOT_PROFILES[bot_name]["templates"]
    template = random.choice(templates)
    print(f"📝 Usando template: {template[:50]}...")
    return template


def generate_content(bot_name: str) -> str:
    """Gera conteúdo com fallback: Gemini → Groq → HuggingFace → Template."""
    # 1. Tentar Gemini (melhor qualidade)
    content = generate_with_gemini(bot_name)
    if content:
        return content
    
    # 2. Tentar Groq (super rápido, Llama 3.3)
    content = generate_with_groq(bot_name)
    if content:
        return content
    
    # 3. Tentar HuggingFace (PT-BR nativo)
    content = generate_with_huggingface(bot_name)
    if content:
        return content
    
    # 4. Fallback: template estático
    return get_template(bot_name)


# =============================================================================
# FIRESTORE
# =============================================================================

_firestore_client = None

def get_firestore_client():
    """Inicializa e retorna cliente Firestore."""
    global _firestore_client
    
    if _firestore_client is not None:
        return _firestore_client
    
    if not HAS_FIREBASE:
        print("❌ firebase-admin não instalado!")
        return None
    
    if not os.path.exists(FIREBASE_CREDENTIALS_PATH):
        print(f"❌ Arquivo de credenciais não encontrado: {FIREBASE_CREDENTIALS_PATH}")
        print("   Baixe em: Firebase Console → Configurações → Contas de serviço → Gerar nova chave privada")
        return None
    
    try:
        cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
        _firestore_client = firestore.client()
        print("✅ Conectado ao Firestore!")
        return _firestore_client
    except Exception as e:
        print(f"❌ Erro ao conectar ao Firestore: {e}")
        return None


def post_to_firestore(bot_name: str, content: str, test_mode: bool = False) -> bool:
    """Posta conteúdo no Firestore."""
    if test_mode:
        print(f"🧪 [TESTE] Não postando de verdade")
        return True
    
    db = get_firestore_client()
    if db is None:
        return False
    
    bot = BOT_PROFILES[bot_name]
    
    post_data = {
        "userId": bot["userId"],
        "userName": bot["displayName"],
        "userPhotoUrl": bot["photoUrl"],
        "userLevel": 99,
        "authorFlair": bot["flair"],
        "content": content,
        "type": "text",
        "upvotes": 0,
        "downvotes": 0,
        "upvotedBy": [],
        "downvotedBy": [],
        "commentCount": 0,
        "viewCount": 0,
        "tags": [],
        "categories": ["general"],
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }
    
    try:
        doc_ref = db.collection("posts").add(post_data)
        print(f"✅ Post criado: {doc_ref[1].id}")
        return True
    except Exception as e:
        print(f"❌ Erro ao postar: {e}")
        return False


# =============================================================================
# MAIN
# =============================================================================

def is_quiet_hours() -> bool:
    """Verifica se está em horário de silêncio."""
    return datetime.now().hour in QUIET_HOURS


def get_next_bot() -> str:
    """Retorna próximo bot na rotação."""
    # Simples: escolhe aleatório
    return random.choice(BOT_ROTATION)


def run_once(bot_name: str | None = None, test_mode: bool = False):
    """Executa uma vez."""
    print(f"\n{'='*50}")
    print(f"🤖 ODYSSEY BOT POSTER - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*50}\n")
    
    # Verificar horário de silêncio
    if is_quiet_hours():
        print(f"😴 Horário de silêncio ({QUIET_HOURS.start}h-{QUIET_HOURS.stop}h). Pulando...")
        return
    
    # Selecionar bot
    if bot_name is None:
        bot_name = get_next_bot()
    
    if bot_name not in BOT_PROFILES:
        print(f"❌ Bot '{bot_name}' não existe. Opções: {list(BOT_PROFILES.keys())}")
        return
    
    bot = BOT_PROFILES[bot_name]
    print(f"🎯 Bot selecionado: {bot['displayName']} ({bot['flair']})")
    
    # Gerar conteúdo
    print("\n📝 Gerando conteúdo...")
    content = generate_content(bot_name)
    
    print(f"\n💬 Conteúdo gerado:")
    print(f"   {content}\n")
    
    # Postar
    print("📤 Postando no Firestore...")
    success = post_to_firestore(bot_name, content, test_mode)
    
    if success:
        print("\n🎉 Sucesso!")
    else:
        print("\n❌ Falha ao postar")


def run_loop(test_mode: bool = False):
    """Roda em loop infinito."""
    print("🔄 Iniciando modo loop...")
    print(f"   Intervalo: {LOOP_INTERVAL_SECONDS // 3600} horas")
    print("   Pressione Ctrl+C para parar\n")
    
    while True:
        try:
            run_once(test_mode=test_mode)
            
            # Adicionar variação aleatória (0-30 min)
            variation = random.randint(0, 30 * 60)
            total_wait = LOOP_INTERVAL_SECONDS + variation
            
            print(f"\n⏰ Próximo post em {total_wait // 3600}h {(total_wait % 3600) // 60}min")
            time.sleep(total_wait)
            
        except KeyboardInterrupt:
            print("\n\n👋 Encerrando...")
            break


def main():
    parser = argparse.ArgumentParser(description="Odyssey Bot Poster")
    parser.add_argument("--loop", action="store_true", help="Rodar em loop contínuo")
    parser.add_argument("--bot", type=str, help="Bot específico (beatnix, erro404, wiki, turbo)")
    parser.add_argument("--test", action="store_true", help="Modo teste (não posta de verdade)")
    parser.add_argument("--list", action="store_true", help="Listar bots disponíveis")
    
    args = parser.parse_args()
    
    if args.list:
        print("\n🤖 Bots disponíveis:\n")
        for name, bot in BOT_PROFILES.items():
            print(f"  {bot['flair']} {bot['displayName']} ({name})")
            print(f"      {bot['system_prompt'].split(chr(10))[0]}")
            print()
        return
    
    if args.loop:
        run_loop(test_mode=args.test)
    else:
        run_once(bot_name=args.bot, test_mode=args.test)


if __name__ == "__main__":
    main()
