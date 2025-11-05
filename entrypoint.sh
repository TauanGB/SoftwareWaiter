#!/usr/bin/env sh
set -e

# Renderiza template usando envsubst (injeta PORT)
envsubst '\$PORT' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf

# Validação: verifica se PORT foi definido
if [ -z "$PORT" ]; then
  echo "ERRO: Variável PORT não definida. Usando padrão 8080."
  export PORT=8080
fi

# Sobe Nginx
exec nginx -g 'daemon off;'

