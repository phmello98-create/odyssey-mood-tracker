#!/bin/bash

# ==============================================================================
# 🔥 Odyssey - Firebase & GCloud Setup Script
# ==============================================================================
# Execute este script no seu terminal para configurar Firebase e GCloud
# ==============================================================================

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║          🚀 ODYSSEY - Firebase & Google Cloud Setup                  ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths
FIREBASE_CLI="$HOME/.local/bin/firebase"
GCLOUD_CLI="$HOME/.local/google-cloud-sdk/bin/gcloud"

# =============================================================================
# STEP 1: Verificar instalação
# =============================================================================
echo -e "${BLUE}📦 Step 1: Verificando instalação...${NC}"

if [ -f "$FIREBASE_CLI" ]; then
    echo -e "${GREEN}✅ Firebase CLI: $($FIREBASE_CLI --version)${NC}"
else
    echo -e "${RED}❌ Firebase CLI não encontrado${NC}"
    exit 1
fi

if [ -f "$GCLOUD_CLI" ]; then
    echo -e "${GREEN}✅ Google Cloud CLI: $($GCLOUD_CLI --version 2>/dev/null | head -1)${NC}"
else
    echo -e "${RED}❌ Google Cloud CLI não encontrado${NC}"
    exit 1
fi

echo ""

# =============================================================================
# STEP 2: Login Firebase
# =============================================================================
echo -e "${BLUE}🔐 Step 2: Login Firebase...${NC}"
echo "  Isso vai abrir seu navegador para autenticação."
echo ""

read -p "Pressione ENTER para continuar com login Firebase..."
$FIREBASE_CLI login

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Firebase login concluído!${NC}"
else
    echo -e "${RED}❌ Firebase login falhou${NC}"
fi

echo ""

# =============================================================================
# STEP 3: Login Google Cloud
# =============================================================================
echo -e "${BLUE}🔐 Step 3: Login Google Cloud...${NC}"
echo "  Isso vai abrir seu navegador para autenticação."
echo ""

read -p "Pressione ENTER para continuar com login GCloud..."
$GCLOUD_CLI auth login

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ GCloud login concluído!${NC}"
else
    echo -e "${RED}❌ GCloud login falhou${NC}"
fi

echo ""

# =============================================================================
# STEP 4: Listar Projetos Firebase
# =============================================================================
echo -e "${BLUE}📋 Step 4: Listando projetos Firebase disponíveis...${NC}"
$FIREBASE_CLI projects:list

echo ""

# =============================================================================
# STEP 5: Vincular ao projeto Odyssey
# =============================================================================
echo -e "${BLUE}🔗 Step 5: Vincular ao projeto Odyssey...${NC}"
echo ""
echo "Lista de projetos acima. Digite o ID do projeto Odyssey:"
read -p "Project ID: " PROJECT_ID

if [ -n "$PROJECT_ID" ]; then
    cd /home/agys/Documentos/odyssey-mood-tracker
    $FIREBASE_CLI use $PROJECT_ID
    $GCLOUD_CLI config set project $PROJECT_ID
    
    echo -e "${GREEN}✅ Projeto $PROJECT_ID vinculado!${NC}"
else
    echo -e "${YELLOW}⚠️  Nenhum projeto vinculado${NC}"
fi

echo ""

# =============================================================================
# STEP 6: Test Lab - Verificar configuração
# =============================================================================
echo -e "${BLUE}🧪 Step 6: Verificando Test Lab...${NC}"

# Habilitar APIs necessárias
echo "  Habilitando APIs necessárias..."
$GCLOUD_CLI services enable testing.googleapis.com
$GCLOUD_CLI services enable toolresults.googleapis.com

echo ""
echo -e "${GREEN}✅ Setup concluído!${NC}"
echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                           📋 PRÓXIMOS PASSOS                         ║"
echo "╠══════════════════════════════════════════════════════════════════════╣"
echo "║ 1. Gere um APK de debug:                                             ║"
echo "║    flutter build apk --debug                                         ║"
echo "║                                                                       ║"
echo "║ 2. Execute Robo Test:                                                 ║"
echo "║    gcloud firebase test android run \\                                ║"
echo "║      --app build/app/outputs/flutter-apk/app-debug.apk \\            ║"
echo "║      --type robo \\                                                   ║"
echo "║      --device model=oriole,version=33 \\                              ║"
echo "║      --timeout 300s                                                   ║"
echo "║                                                                       ║"
echo "║ 3. Visualize resultados no Console Firebase:                         ║"
echo "║    https://console.firebase.google.com                               ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
