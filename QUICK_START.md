# 🚀 Quick Start - Software Waiter

Guia rápido para começar a usar o Software Waiter.

## 📋 Pré-requisitos

- Docker instalado
- Um APK do app (exemplo: `meuapp.apk`)

## ⚡ Início Rápido

### 1. Preparar APK

```bash
# Copie seu APK para o diretório releases
cp meuapp.apk downloads/releases/meuapp-1.4.0+42.apk
```

### 2. Atualizar latest.json

Edite `downloads/latest.json` com a versão correta:

```json
{
  "version_name": "1.4.0",
  "version_code": 42,
  "url": "/downloads/latest.apk",
  "sha256": "COLOQUE_SHA256_OPCIONAL",
  "changelog": "• Versão inicial"
}
```

### 3. Atualizar Dockerfile

No `Dockerfile`, linha 7, atualize o nome do APK:

```dockerfile
RUN cp releases/meuapp-1.4.0+42.apk latest.apk
```

### 4. Build e Execução

```bash
# Build
docker build -t software-waiter .

# Executar
docker run -p 8080:8080 -e PORT=8080 software-waiter
```

### 5. Testar

```bash
# Health check
curl http://localhost:8080/health

# Verificar latest.json
curl http://localhost:8080/downloads/latest.json

# Verificar headers do APK
curl -I http://localhost:8080/downloads/latest.apk
```

## 🎯 Usando o Script de Release

Para facilitar, use o script de release:

```bash
# Tornar executável (Linux/Mac)
chmod +x tools/release.sh

# Executar
./tools/release.sh meuapp.apk 1.4.0 42 "• Versão inicial"
```

O script irá:
- ✅ Copiar APK para `downloads/releases/`
- ✅ Gerar SHA-256
- ✅ Atualizar `latest.json`
- ✅ Atualizar `Dockerfile`

## 📤 Deploy no Railway

### Opção 1: Via GitHub

1. Faça push do código para o GitHub
2. No Railway, conecte o repositório
3. Railway detecta o `Dockerfile` e faz deploy automático

### Opção 2: Via CLI

```bash
railway login
railway init
railway up
```

## ✅ Checklist de Validação

- [ ] APK está em `downloads/releases/`
- [ ] `latest.json` está atualizado com `version_code` correto
- [ ] `Dockerfile` aponta para o APK correto
- [ ] Build local funciona (`docker build`)
- [ ] Container inicia (`docker run`)
- [ ] `/health` retorna 200
- [ ] `/downloads/latest.json` retorna JSON válido
- [ ] `/downloads/latest.apk` retorna o APK

## 🐛 Problemas Comuns

### "APK não encontrado" no build

**Solução:** Verifique se o APK está em `downloads/releases/` e se o nome no `Dockerfile` está correto.

### Porta já em uso

**Solução:** Use outra porta:
```bash
docker run -p 3000:8080 -e PORT=8080 software-waiter
```

### latest.json retorna 404

**Solução:** Verifique se o arquivo existe e está no lugar correto:
```bash
docker exec <container-id> ls -la /usr/share/nginx/html/downloads/
```

## 📚 Próximos Passos

- Leia o [README.md](README.md) completo para documentação detalhada
- Configure o domínio no Railway
- Integre com o app Flutter (SOFTWARE-EG3)

