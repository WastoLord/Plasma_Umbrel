#!/bin/bash
set -e

echo "=== [BUILD] INICIANDO INSTALAÇÃO DO PLUGIN HP ==="

# 1. DETECTAR A VERSÃO
VERSION=$(dpkg -l hplip | grep ii | awk '{print $3}' | cut -d+ -f1)

if [ -z "$VERSION" ]; then
    echo "ERRO: HPLIP não encontrado."
    exit 1
fi

ARQUIVO_RUN="hplip-${VERSION}-plugin.run"
URL_BASE="https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins"
CAMINHO_FINAL="/tmp/$ARQUIVO_RUN"

echo "--> Versão: $VERSION"
echo "--> Baixando: $ARQUIVO_RUN"

# 2. DOWNLOAD
wget -O "$CAMINHO_FINAL" "$URL_BASE/$ARQUIVO_RUN"

if [ ! -f "$CAMINHO_FINAL" ]; then
    echo "ERRO: Download falhou."
    exit 1
fi

# 3. INSTALAÇÃO FORÇADA (O PULO DO GATO 🐈)
echo "--> Executando instalador..."
chmod +x "$CAMINHO_FINAL"

# MUDANÇA AQUI:
# 'yes' envia 'y' repetidamente para aceitar a licença
# '-i' força modo texto (console) em vez de gráfico
yes | sh "$CAMINHO_FINAL" -- -i

# 4. LIMPEZA
echo "--> Limpando..."
rm "$CAMINHO_FINAL"

echo "=== [BUILD] SUCESSO! ==="