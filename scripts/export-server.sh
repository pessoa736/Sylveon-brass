#!/bin/bash

# Exporta o modpack para distribuição SERVER (sem mods client-only).
# Gera um .zip pronto pra subir na CurseForge/Modrinth como server pack.

set -e

RAM_RECOMENDADA=4096  # servidor costuma precisar de menos RAM que o client

echo "📦 Executando a exportação SERVER do packwiz (side=server)..."
packwiz curseforge export -s server

# 🔍 Descobre automaticamente o nome exato do arquivo ZIP gerado que começa com "Sylveon"
OUTPUT_ZIP=$(ls Sylveon*.zip 2>/dev/null | head -n 1)

if [ -z "$OUTPUT_ZIP" ] || [ ! -f "$OUTPUT_ZIP" ]; then
    echo "❌ Erro: Nenhum arquivo ZIP começando com 'Sylveon' foi encontrado na pasta atual."
    exit 1
fi

echo "📂 Arquivo encontrado: $OUTPUT_ZIP"
echo "🔧 Injetando a configuração de RAM ($RAM_RECOMENDADA MB) no manifest.json..."

# Cria a pasta build e move o zip para dentro dela de forma segura
mkdir -p build
mv "$OUTPUT_ZIP" build/
cd build

# Extrai apenas o manifest.json do zip
unzip -q "$OUTPUT_ZIP" manifest.json

# Usa o jq para inserir de forma limpa a chave no topo do JSON
jq --argjson ram "$RAM_RECOMENDADA" '. + {recommendedMemory: $ram}' manifest.json > manifest.tmp && mv manifest.tmp manifest.json

# Atualiza o manifest.json modificado de volta para dentro do zip
zip -q -u "$OUTPUT_ZIP" manifest.json

# Deleta o arquivo temporário da pasta build
rm manifest.json

# Volta para a pasta anterior para finalizar o processo de forma limpa
cd ..

echo "✅ Sucesso! O arquivo build/$OUTPUT_ZIP está pronto para o servidor com ${RAM_RECOMENDADA}MB de RAM."
