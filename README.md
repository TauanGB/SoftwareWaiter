# Software Waiter

Serviço Nginx para hospedar downloads do app Android (SOFTWARE-EG3).

## 📋 Visão Geral

O **Software Waiter** é um container Docker que serve:
- **Endpoint JSON**: `/downloads/latest.json` (sem cache) - informações da última versão
- **Binários APK**: `/downloads/*.apk` (cache longo + headers de download)

O app Flutter (SOFTWARE-EG3) consulta `latest.json`, compara `version_code` com o build local e, havendo atualização, baixa o APK.

## 🏗️ Estrutura do Projeto

```
software-waiter/
├── downloads/
│   ├── releases/
│   │   └── meuapp-1.4.0+42.apk        # APKs versionados
│   └── latest.json                     # JSON de versão
├── nginx.conf.template                 # Template Nginx (com ${PORT})
├── entrypoint.sh                       # Script de inicialização
├── Dockerfile                          # Build multi-stage
├── tools/
│   └── release.sh                      # Script de release (opcional)
└── README.md
```

## 📦 Estrutura do latest.json

O arquivo `downloads/latest.json` deve seguir este formato:

```json
{
  "version_name": "1.4.0",
  "version_code": 42,
  "url": "/downloads/latest.apk",
  "sha256": "COLOQUE_SHA256_OPCIONAL",
  "changelog": "• Novo relatório\n• Correções de login"
}
```

**Campos importantes:**
- `version_name`: Versão semântica (ex: "1.4.0")
- `version_code`: Build number inteiro que sempre cresce (deve corresponder ao `buildNumber` do Flutter)
- `url`: Sempre `/downloads/latest.apk` (relativo)
- `sha256`: (Opcional) Hash SHA-256 do APK para validação
- `changelog`: (Opcional) Lista de mudanças em Markdown

## 🚀 Build e Execução Local

### Pré-requisitos
- Docker instalado
- Um APK de exemplo em `downloads/releases/`

### Build

```bash
docker build -t software-waiter .
```

### Execução

```bash
docker run -p 8080:8080 -e PORT=8080 software-waiter
```

### Testes Locais

Após iniciar o container, teste os endpoints:

```bash
# Health check
curl http://localhost:8080/health

# Verificar latest.json (sem cache)
curl -H "Cache-Control: no-cache" http://localhost:8080/downloads/latest.json

# Download do APK (simula download)
curl -I http://localhost:8080/downloads/latest.apk
```

### Validação de Headers

```bash
# latest.json deve ter Cache-Control: no-store
curl -I http://localhost:8080/downloads/latest.json | grep -i cache-control

# APK deve ter Cache-Control: public, max-age=31536000 e Content-Disposition: attachment
curl -I http://localhost:8080/downloads/latest.apk | grep -i "cache-control\|content-disposition"
```

## 📤 Publicação/Atualização

Existem duas opções para publicar novas versões:

### Opção A — Rebuild Imutável (Recomendado)

Esta é a abordagem recomendada para produção, garantindo builds imutáveis e versionados.

**Passos:**

1. **Adicionar novo APK** em `downloads/releases/`:
   ```bash
   cp meuapp.apk downloads/releases/meuapp-1.4.1+43.apk
   ```

2. **Atualizar `downloads/latest.json`**:
   ```json
   {
     "version_name": "1.4.1",
     "version_code": 43,
     "url": "/downloads/latest.apk",
     "sha256": "abc123...",
     "changelog": "• Correções de bugs\n• Melhorias de performance"
   }
   ```

3. **Atualizar o Dockerfile** (linha do `cp`):
   ```dockerfile
   RUN cp releases/meuapp-1.4.1+43.apk latest.apk
   ```

4. **Commit e push**:
   ```bash
   git add downloads/releases/meuapp-1.4.1+43.apk downloads/latest.json Dockerfile
   git commit -m "Release 1.4.1+43"
   git push
   ```

5. **Railway builda e publica automaticamente** (se configurado com GitHub)

### Opção B — Volume (Sem Rebuild)

Útil para atualizações rápidas sem rebuild do container. Requer volume montado no Railway.

**Pré-requisito:** Configurar Volume no Railway mapeando `/usr/share/nginx/html/downloads`

**Passos:**

1. **Conectar via SSH no Railway**:
   ```bash
   railway ssh
   ```

2. **Subir novo APK**:
   ```bash
   # Via upload ou wget/curl
   cp /path/to/meuapp-1.4.1+43.apk /usr/share/nginx/html/downloads/releases/
   ```

3. **Atualizar latest.apk**:
   ```bash
   cp /usr/share/nginx/html/downloads/releases/meuapp-1.4.1+43.apk \
      /usr/share/nginx/html/downloads/latest.apk
   ```

4. **Atualizar latest.json**:
   ```bash
   cat > /usr/share/nginx/html/downloads/latest.json <<EOF
   {
     "version_name": "1.4.1",
     "version_code": 43,
     "url": "/downloads/latest.apk",
     "sha256": "abc123...",
     "changelog": "• Correções"
   }
   EOF
   ```

5. **Sem reiniciar**: Nginx serve imediatamente os novos arquivos.

## 🌐 Deploy no Railway

### 1. Via GitHub (Recomendado)

1. **Criar repositório** no GitHub (se ainda não existir)
2. **Conectar ao Railway**:
   - Acesse [Railway Dashboard](https://railway.app)
   - Clique em "New Project" → "Deploy from GitHub repo"
   - Selecione o repositório `software-waiter`
3. **Configurar variáveis de ambiente**:
   - `PORT`: Automático (Railway define automaticamente)
4. **Deploy automático**: Railway detecta o `Dockerfile` e faz build/publish

### 2. Via CLI

```bash
# Instalar Railway CLI
npm i -g @railway/cli

# Login
railway login

# Inicializar projeto
railway init

# Linkar ao projeto existente (se necessário)
railway link

# Deploy
railway up
```

### 3. Configuração de Domínio

1. **No Railway Dashboard**:
   - Vá em Settings → Domains
   - Clique em "Generate Domain" ou adicione domínio customizado
2. **HTTPS**: Habilitado automaticamente pelo Railway
3. **URL final**: `https://seu-dominio.railway.app`

### 4. Health Check

Railway pode usar o endpoint `/health` para monitoramento:

```
GET /health
→ 200 OK
```

## 🔧 Integração com SOFTWARE-EG3

O app Flutter já está preparado para consultar `/downloads/latest.json`. Certifique-se de:

1. **Configurar a URL base** no app:
   ```dart
   // Exemplo em app_config.dart
   static const String updateServerUrl = 'https://seu-dominio.railway.app';
   ```

2. **Endpoint completo**:
   ```
   GET ${updateServerUrl}/downloads/latest.json
   ```

3. **Comparação de versão**:
   - O app compara `version_code` (inteiro) com `buildNumber` local
   - Se `version_code > buildNumber`, mostra diálogo de atualização

4. **Download do APK**:
   - URL: `${updateServerUrl}/downloads/latest.apk`
   - O app baixa e instala automaticamente (se configurado)

## ✅ Critérios de Aceitação

- [x] `GET /downloads/latest.json` retorna JSON válido com `Cache-Control: no-store`
- [x] `GET /downloads/latest.apk` baixa o binário com:
  - `Content-Disposition: attachment`
  - `Content-Type: application/vnd.android.package-archive`
- [x] APKs servidos com cache longo (1 ano = 31536000 segundos)
- [x] Sem listagem de diretórios (`autoindex off`)
- [x] Build local (`docker build`) funciona
- [x] Execução local (`docker run -e PORT=8080`) funciona
- [x] Endpoints respondem corretamente
- [x] Deploy no Railway funcional, obedecendo `${PORT}`
- [x] Processo de atualização documentado (Opção A e B)
- [x] `latest.json` usa `version_code` coerente com o app (`buildNumber`)

## 🛠️ Script de Release (Opcional)

O script `tools/release.sh` facilita o processo de release:

```bash
# Uso
./tools/release.sh meuapp.apk 1.4.1 43 "• Correções de bugs"
```

**Funcionalidades:**
- Renomeia APK para formato `meuapp-X.Y.Z+N.apk`
- Gera SHA-256 do APK
- Atualiza `downloads/latest.json`
- Atualiza linha do `Dockerfile` (Opção A)

**Nota:** Requer `sh` e `sha256sum` (ou equivalente no macOS: `shasum -a 256`)

## 🔒 Segurança

- ✅ Apenas arquivos estáticos (sem código server-side)
- ✅ HTTPS obrigatório em produção (Railway)
- ✅ Sem exposição de credenciais
- ✅ CORS configurado apenas para `latest.json` (opcional)

## 📝 Notas Importantes

1. **Version Code**: Deve sempre aumentar e corresponder ao `buildNumber` do Flutter
2. **latest.apk**: Sempre aponta para a versão mais recente (alias criado no Dockerfile)
3. **Cache**: 
   - `latest.json`: Sempre sem cache (no-store)
   - APKs: Cache longo para performance
4. **HTTPS**: Sempre usar HTTPS em produção (Railway fornece automaticamente)

## 🐛 Troubleshooting

### Container não inicia

```bash
# Verificar logs
docker logs <container-id>

# Verificar se PORT está definido
docker run -e PORT=8080 software-waiter
```

### APK não encontrado

```bash
# Verificar se o arquivo existe no container
docker exec <container-id> ls -la /usr/share/nginx/html/downloads/

# Verificar se o nome do APK no Dockerfile está correto
```

### latest.json retorna 404

```bash
# Verificar se o arquivo existe
docker exec <container-id> cat /usr/share/nginx/html/downloads/latest.json
```

### Cache não funciona

- Verificar headers com `curl -I`
- `latest.json` deve ter `Cache-Control: no-store`
- APKs devem ter `Cache-Control: public, max-age=31536000`

## 📚 Referências

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Railway Documentation](https://docs.railway.app/)
- [Flutter Package Info](https://pub.dev/packages/package_info_plus)

## 📄 Licença

Este projeto é parte do ecossistema SOFTWARE-EG3.

