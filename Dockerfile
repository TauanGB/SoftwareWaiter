FROM alpine:3.20 AS assets
WORKDIR /out/downloads
COPY downloads/releases ./releases
COPY downloads/latest.json .
# Alias para a versão vigente (ajuste o nome do .apk de origem ao publicar)
# IMPORTANTE: Atualize este nome ao publicar nova versão
RUN cp releases/meuapp-1.4.0+42.apk latest.apk 2>/dev/null || echo "AVISO: APK não encontrado, será necessário copiar manualmente"

FROM nginx:alpine
ENV PORT=8080

# Instalar gettext para envsubst
RUN apk add --no-cache gettext

# Templates e estáticos
COPY nginx.conf.template /etc/nginx/templates/nginx.conf.template
COPY --from=assets /out/downloads /usr/share/nginx/html/downloads

# Entrypoint para envsubst + nginx
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expor porta (será sobrescrita pela variável PORT)
EXPOSE 8080

CMD ["/entrypoint.sh"]

