# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

## [1.0.0] - 2025-11-05

### Adicionado
- Container Nginx para servir downloads do app Android
- Endpoint `/downloads/latest.json` com informações de versão
- Endpoint `/downloads/latest.apk` para download do APK
- Configuração de cache (no-store para JSON, cache longo para APKs)
- Script de release (`tools/release.sh`)
- Documentação completa no README.md
- Health check endpoint (`/health`)
- Suporte para CORS em `latest.json`
- Dockerfile multi-stage para otimização
- Configuração para Railway (variável PORT)

