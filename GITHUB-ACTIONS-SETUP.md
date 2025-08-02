# 🚀 GitHub Actions - Seguindo BuildSpec.yml

## 📋 **WORKFLOW ATUALIZADO**

O GitHub Actions agora segue **exatamente as mesmas fases** do `buildspec.yml`:

### **🔄 PRE-BUILD PHASE**
- Login no Amazon ECR
- Definição de variáveis (REPOSITORY_URI, COMMIT_HASH, IMAGE_TAG)
- Logs detalhados como no buildspec

### **🔨 BUILD PHASE**
- Build da imagem Docker com `--build-arg VITE_API_URL`
- Tag das imagens (latest e commit hash)
- Logs idênticos ao buildspec

### **📦 POST-BUILD PHASE**
- Push das imagens para ECR
- Geração do `imagedefinitions.json`
- Verificação da imagem no ECR
- Upload do artifact

### **🚀 DEPLOY PHASE**
- Download da task definition
- Atualização com nova imagem
- Deploy no ECS

### **🔍 VERIFICATION PHASE**
- Verificação do status do serviço
- Teste de conectividade
- Logs de verificação

## 📋 **CONFIGURAÇÃO**

### **1. Secrets no GitHub**
Acesse: `https://github.com/jmarcelotse/bia-nxt/settings/secrets/actions`

- **AWS_ACCESS_KEY_ID**: `AKIA4W7IQYQLAH5BHKB4`
- **AWS_SECRET_ACCESS_KEY**: `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`

### **2. Commit dos Arquivos**
```bash
cd /home/ec2-user/bia
git add .github/workflows/deploy.yml GITHUB-ACTIONS-SETUP.md
git commit -m "feat: GitHub Actions seguindo buildspec.yml"
git push origin main
```

## 🔍 **COMPARAÇÃO**

| Fase | BuildSpec.yml | GitHub Actions |
|------|---------------|----------------|
| PRE-BUILD | ✅ Login ECR | ✅ Idêntico |
| BUILD | ✅ Docker build | ✅ Idêntico |
| POST-BUILD | ✅ Push + artifacts | ✅ Idêntico |
| DEPLOY | ❌ CodePipeline | ✅ Integrado |

## ✅ **VANTAGENS**
- ✅ Compatibilidade total com buildspec.yml
- ✅ Sem limitação de builds
- ✅ Deploy integrado
- ✅ Artifacts automáticos
