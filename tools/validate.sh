#!/usr/bin/env sh
# Script de validação para Software Waiter
# Valida estrutura de arquivos e configurações

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${GREEN}🔍 Validando estrutura do projeto...${NC}"
echo ""

ERRORS=0

# Verificar arquivos essenciais
check_file() {
  if [ -f "$1" ]; then
    echo -e "${GREEN}✅ $1${NC}"
  else
    echo -e "${RED}❌ $1 não encontrado${NC}"
    ERRORS=$((ERRORS + 1))
  fi
}

# Verificar diretórios
check_dir() {
  if [ -d "$1" ]; then
    echo -e "${GREEN}✅ $1/ existe${NC}"
  else
    echo -e "${RED}❌ $1/ não encontrado${NC}"
    ERRORS=$((ERRORS + 1))
  fi
}

echo "📁 Estrutura de diretórios:"
check_dir "$PROJECT_ROOT/downloads"
check_dir "$PROJECT_ROOT/downloads/releases"
check_dir "$PROJECT_ROOT/tools"

echo ""
echo "📄 Arquivos essenciais:"
check_file "$PROJECT_ROOT/Dockerfile"
check_file "$PROJECT_ROOT/nginx.conf.template"
check_file "$PROJECT_ROOT/entrypoint.sh"
check_file "$PROJECT_ROOT/downloads/latest.json"
check_file "$PROJECT_ROOT/README.md"

echo ""
echo "🔧 Arquivos opcionais:"
if [ -f "$PROJECT_ROOT/tools/release.sh" ]; then
  echo -e "${GREEN}✅ tools/release.sh${NC}"
else
  echo -e "${YELLOW}⚠️  tools/release.sh não encontrado (opcional)${NC}"
fi

if [ -f "$PROJECT_ROOT/railway.toml" ]; then
  echo -e "${GREEN}✅ railway.toml${NC}"
else
  echo -e "${YELLOW}⚠️  railway.toml não encontrado (opcional)${NC}"
fi

echo ""
echo "📦 Validando latest.json..."

if [ -f "$PROJECT_ROOT/downloads/latest.json" ]; then
  # Verificar se é JSON válido (requer jq ou python)
  if command -v jq >/dev/null 2>&1; then
    if jq empty "$PROJECT_ROOT/downloads/latest.json" 2>/dev/null; then
      echo -e "${GREEN}✅ latest.json é JSON válido${NC}"
      
      # Verificar campos obrigatórios
      VERSION_NAME=$(jq -r '.version_name' "$PROJECT_ROOT/downloads/latest.json")
      VERSION_CODE=$(jq -r '.version_code' "$PROJECT_ROOT/downloads/latest.json")
      URL=$(jq -r '.url' "$PROJECT_ROOT/downloads/latest.json")
      
      if [ "$VERSION_NAME" != "null" ] && [ -n "$VERSION_NAME" ]; then
        echo -e "${GREEN}  ✅ version_name: $VERSION_NAME${NC}"
      else
        echo -e "${RED}  ❌ version_name ausente ou inválido${NC}"
        ERRORS=$((ERRORS + 1))
      fi
      
      if [ "$VERSION_CODE" != "null" ] && [ -n "$VERSION_CODE" ]; then
        echo -e "${GREEN}  ✅ version_code: $VERSION_CODE${NC}"
      else
        echo -e "${RED}  ❌ version_code ausente ou inválido${NC}"
        ERRORS=$((ERRORS + 1))
      fi
      
      if [ "$URL" = "/downloads/latest.apk" ]; then
        echo -e "${GREEN}  ✅ url: $URL${NC}"
      else
        echo -e "${YELLOW}  ⚠️  url: $URL (esperado: /downloads/latest.apk)${NC}"
      fi
    else
      echo -e "${RED}❌ latest.json não é JSON válido${NC}"
      ERRORS=$((ERRORS + 1))
    fi
  elif command -v python3 >/dev/null 2>&1; then
    if python3 -m json.tool "$PROJECT_ROOT/downloads/latest.json" >/dev/null 2>&1; then
      echo -e "${GREEN}✅ latest.json é JSON válido${NC}"
    else
      echo -e "${RED}❌ latest.json não é JSON válido${NC}"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo -e "${YELLOW}⚠️  jq ou python3 não encontrado, pulando validação JSON${NC}"
  fi
fi

echo ""
echo "🐳 Validando Dockerfile..."

if [ -f "$PROJECT_ROOT/Dockerfile" ]; then
  # Verificar se menciona PORT
  if grep -q "\$PORT" "$PROJECT_ROOT/Dockerfile" || grep -q "PORT" "$PROJECT_ROOT/Dockerfile"; then
    echo -e "${GREEN}✅ Dockerfile menciona PORT${NC}"
  else
    echo -e "${YELLOW}⚠️  Dockerfile não menciona PORT explicitamente${NC}"
  fi
  
  # Verificar se tem multi-stage build
  if grep -q "FROM.*AS" "$PROJECT_ROOT/Dockerfile"; then
    echo -e "${GREEN}✅ Dockerfile usa multi-stage build${NC}"
  else
    echo -e "${YELLOW}⚠️  Dockerfile não parece usar multi-stage build${NC}"
  fi
fi

echo ""
echo "📋 Resumo:"

if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ Validação concluída sem erros!${NC}"
  exit 0
else
  echo -e "${RED}❌ Validação concluída com $ERRORS erro(s)${NC}"
  exit 1
fi

