#!/usr/bin/env python3
"""
Script para adicionar strings extraídas aos arquivos ARB
"""
import json
import re

# Carrega strings extraídas
with open('scripts/extracted_strings.json', 'r', encoding='utf-8') as f:
    extracted = json.load(f)

# Carrega ARBs existentes
with open('lib/src/localization/app_en.arb', 'r', encoding='utf-8') as f:
    arb_en = json.load(f)

with open('lib/src/localization/app_pt.arb', 'r', encoding='utf-8') as f:
    arb_pt = json.load(f)

# Traduções manuais para as strings em inglês que apareceram
translations = {
    'ativar': ('Enable', 'Ativar'),
    'limpar': ('Clear', 'Limpar'),
    'tarefas': ('Tasks', 'Tarefas'),
    'aplicar': ('Apply', 'Aplicar'),
    'limparFiltros': ('Clear filters', 'Limpar filtros'),
    'acertei': ('Got it', 'Acertei'),
    'registrar': ('Register', 'Registrar'),
    'selecioneUmIdiomaPrimeiro': ('Select a language first', 'Selecione um idioma primeiro'),
    'editar': ('Edit', 'Editar'),
    'adicionarIdioma': ('Add Language', 'Adicionar Idioma'),
    'voltar': ('Back', 'Voltar'),
    'reenviar': ('Resend', 'Reenviar'),
    'continuar': ('Continue', 'Continuar'),
    'e': (' and ', ' e '),
    'entrar': ('Sign In', 'Entrar'),
    'nenhum': ('None', 'Nenhum'),
    'cancelar': ('Cancel', 'Cancelar'),
    'tentarNovamente': ('Try again', 'Tentar novamente'),
    'sincronizarAgora': ('Sync now', 'Sincronizar agora'),
    'note': ('Note: ', 'Nota: '),
}

# Adiciona strings portuguesas ao ARB
added_count = 0
for key, data in extracted['portuguese'].items():
    if key not in arb_pt:
        arb_pt[key] = data['text']
        arb_en[key] = data['text']  # Temporário, precisa tradução
        added_count += 1
        print(f"  + {key}: PT='{data['text']}'")

# Adiciona strings "inglesas" (com tradução manual)
for key, data in extracted['english'].items():
    if key not in arb_en:
        if key in translations:
            en, pt = translations[key]
            arb_en[key] = en
            arb_pt[key] = pt
        else:
            # Strings com variáveis ou muito específicas, ignorar
            if '$' in data['text'] or '_' in data['text'] or '${' in data['text']:
                continue
            arb_en[key] = data['text']
            arb_pt[key] = data['text']
        added_count += 1
        print(f"  + {key}: EN='{arb_en.get(key)}'")

# Remove entradas @metadata antes de salvar
def clean_arb(arb):
    """Remove metadata entries (começam com @)"""
    return {k: v for k, v in arb.items() if not k.startswith('@') or k == '@@locale'}

# Salva ARBs atualizados
arb_en_clean = clean_arb(arb_en)
arb_pt_clean = clean_arb(arb_pt)

with open('lib/src/localization/app_en.arb', 'w', encoding='utf-8') as f:
    json.dump(arb_en_clean, f, indent=2, ensure_ascii=False)
    f.write('\n')

with open('lib/src/localization/app_pt.arb', 'w', encoding='utf-8') as f:
    json.dump(arb_pt_clean, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f"\n✅ {added_count} novas strings adicionadas aos ARBs")
print(f"📊 Total EN: {len(arb_en_clean)} strings")
print(f"📊 Total PT: {len(arb_pt_clean)} strings")
print("\n🎯 Próximo passo: flutter gen-l10n")
