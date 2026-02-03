#!/bin/bash

# 'set -e' faz o script parar imediatamente se qualquer comando der erro.
# Isso evita que o Docker diga que "deu certo" se o download falhar.
set -e

echo "=== [BUILD] INICIANDO INSTALAÇÃO DO PLUGIN HP ==="

# 1. DETECTAR A VERSÃO DO HPLIP INSTALADA
# O comando dpkg lista o pacote, awk pega a coluna da versão, cut remove o "+dfsg" do Debian
HP_VERSION=$(dpkg -l hplip | grep ii | awk '{print $3}' | cut -d+ -f1)

if [ -z "$HP_VERSION" ]; then
    echo "ERRO: HPLIP não parece estar instalado."
    exit 1
fi

echo "--> Versão detectada: $HP_VERSION"

# 2. BAIXAR O ARQUIVO .RUN (PLUGIN)
# O site openprinting é o repositório oficial que o hp-plugin usa internamente
URL="https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-${HP_VERSION}-plugin.run"
DEST="/tmp/hplip-plugin.run"

echo "--> Baixando plugin de: $URL"
wget -O "$DEST" "$URL"

if [ ! -f "$DEST" ]; then
    echo "ERRO: Falha ao baixar o arquivo."
    exit 1
fi

# 3. INSTALAÇÃO SILENCIOSA
# O segredo aqui é o '-- -q'. 
# O primeiro '--' passa argumentos para o instalador interno.
# O '-q' (quit/quiet) aceita a licença automaticamente e instala sem interface gráfica.
echo "--> Executando instalador silencioso..."
chmod +x "$DEST"
sh "$DEST" -- -q

# 4. LIMPEZA
# Remove o instalador para a imagem Docker ficar menor
echo "--> Limpando arquivos temporários..."
rm "$DEST"

echo "=== [BUILD] PLUGIN INSTALADO COM SUCESSO! ==="
