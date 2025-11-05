#!/usr/bin/env sh
# Script de release para Software Waiter
# Uso: ./tools/release.sh <apk_path> <version_name> <version_code> [changelog]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar argumentos
if [ $# -lt 3 ]; then
  echo -e "${RED}Erro: Argumentos insuficientes${NC}"
  echo "Uso: $0 <apk_path> <version_name> <version_code> [changelog]"
  echo "Exemplo: $0 meuapp.apk 1.4.1 43 '• Correções de bugs'"
  exit 1
fi

APK_PATH="$1"
VERSION_NAME="$2"
VERSION_CODE="$3"
CHANGELOG="${4:-• Nova versão}"

# Verificar se o APK existe
if [ ! -f "$APK_PATH" ]; then
  echo -e "${RED}Erro: APK não encontrado: $APK_PATH${NC}"
  exit 1
fi

# Validar formato de versão
if ! echo "$VERSION_NAME" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
  echo -e "${YELLOW}Aviso: version_name não segue formato semântico (X.Y.Z)${NC}"
fi

# Validar version_code (deve ser inteiro)
if ! echo "$VERSION_CODE" | grep -qE '^[0-9]+$'; then
  echo -e "${RED}Erro: version_code deve ser um número inteiro${NC}"
  exit 1
fi

echo -e "${GREEN}🚀 Iniciando release...${NC}"
echo "  APK: $APK_PATH"
echo "  Versão: $VERSION_NAME"
echo "  Build: $VERSION_CODE"
echo ""

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASES_DIR="$PROJECT_ROOT/downloads/releases"

# Criar diretório de releases se não existir
mkdir -p "$RELEASES_DIR"

# Nome do arquivo final
APK_NAME="meuapp-${VERSION_NAME}+${VERSION_CODE}.apk"
APK_DEST="$RELEASES_DIR/$APK_NAME"

# Copiar APK para releases/
echo -e "${GREEN}📦 Copiando APK para releases/...${NC}"
cp "$APK_PATH" "$APK_DEST"
echo "  ✅ $APK_DEST"

# Gerar SHA-256
echo -e "${GREEN}🔐 Gerando SHA-256...${NC}"
if command -v sha256sum >/dev/null 2>&1; then
  SHA256=$(sha256sum "$APK_DEST" | cut -d' ' -f1)
elif command -v shasum >/dev/null 2>&1; then
  SHA256=$(shasum -a 256 "$APK_DEST" | cut -d' ' -f1)
else
  echo -e "${YELLOW}Aviso: sha256sum/shasum não encontrado. Pulando geração de SHA-256.${NC}"
  SHA256="COLOQUE_SHA256_OPCIONAL"
fi

if [ "$SHA256" != "COLOQUE_SHA256_OPCIONAL" ]; then
  echo "  ✅ SHA-256: $SHA256"
fi

# Criar latest.json
echo -e "${GREEN}📝 Atualizando latest.json...${NC}"
LATEST_JSON="$PROJECT_ROOT/downloads/latest.json"

# Converter changelog para JSON (escapar quebras de linha)
CHANGELOG_JSON=$(echo "$CHANGELOG" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

cat > "$LATEST_JSON" <<EOF
{
  "version_name": "$VERSION_NAME",
  "version_code": $VERSION_CODE,
  "url": "/downloads/latest.apk",
  "sha256": "$SHA256",
  "changelog": "$CHANGELOG_JSON"
}
EOF

echo "  ✅ $LATEST_JSON"

# Atualizar Dockerfile (Opção A - Rebuild)
echo -e "${GREEN}🐳 Atualizando Dockerfile...${NC}"
DOCKERFILE="$PROJECT_ROOT/Dockerfile"

# Verificar se Dockerfile existe
if [ -f "$DOCKERFILE" ]; then
  # Buscar linha com cp releases/...
  if grep -q "cp releases/" "$DOCKERFILE"; then
    # Atualizar linha do cp
    sed -i.bak "s|cp releases/.*\.apk|cp releases/$APK_NAME|g" "$DOCKERFILE"
    rm -f "$DOCKERFILE.bak"
    echo "  ✅ Dockerfile atualizado (linha do cp)"
  else
    echo -e "${YELLOW}Aviso: Linha 'cp releases/' não encontrada no Dockerfile${NC}"
  fi
else
  echo -e "${YELLOW}Aviso: Dockerfile não encontrado${NC}"
fi

# Resumo
echo ""
echo -e "${GREEN}✅ Release concluída!${NC}"
echo ""
echo "Próximos passos:"
echo "  1. Verifique os arquivos criados:"
echo "     - $APK_DEST"
echo "     - $LATEST_JSON"
echo "  2. (Opção A) Commit e push para Railway:"
echo "     git add downloads/releases/$APK_NAME downloads/latest.json Dockerfile"
echo "     git commit -m 'Release $VERSION_NAME+$VERSION_CODE'"
echo "     git push"
echo "  3. (Opção B) Se usar Volume, copie manualmente para o container"
echo ""

