# 🚀 Guia do Script ECS Deploy

## 📋 **Visão Geral**

O script `ecs-deploy.sh` automatiza completamente o processo de deploy da aplicação Bia no Amazon ECS com versionamento baseado em commit hash do Git.

## ✨ **Características Principais**

### 🔄 **Versionamento Inteligente**
- **Tag baseada em commit**: Cada imagem recebe uma tag com os últimos 8 caracteres do commit hash
- **Rastreabilidade completa**: Cada deploy é vinculado a um commit específico
- **Rollback fácil**: Volte para qualquer versão anterior rapidamente

### 🏗️ **Deploy Automatizado**
- **Build otimizado**: Construção da imagem Docker com cache inteligente
- **Push seguro**: Upload automático para Amazon ECR
- **Task Definition dinâmica**: Criação automática com configurações atualizadas
- **Deploy zero-downtime**: Atualização do serviço ECS sem interrupção

### 🔐 **Integração Completa**
- **AWS Secrets Manager**: Credenciais do banco gerenciadas automaticamente
- **CloudWatch Logs**: Logs centralizados e organizados
- **Security Groups**: Configuração de rede mantida
- **Health Checks**: Verificação automática da saúde do serviço

## 🛠️ **Como Usar**

### **1. Deploy Padrão**
```bash
# Navegar para o diretório do projeto
cd /home/ec2-user/bia

# Executar deploy
./ecs-deploy.sh deploy
```

### **2. Listar Versões**
```bash
# Ver todas as versões disponíveis
./ecs-deploy.sh list
```

### **3. Rollback**
```bash
# Fazer rollback para versão específica
./ecs-deploy.sh rollback a1b2c3d4
```

### **4. Ajuda**
```bash
# Ver ajuda completa
./ecs-deploy.sh help
```

## 📊 **Fluxo Detalhado do Deploy**

### **Fase 1: Validação** ⚡
```
✅ Verificar Docker rodando
✅ Validar credenciais AWS
✅ Confirmar repositório Git
✅ Checar arquivos necessários
✅ Verificar repositório ECR
```

### **Fase 2: Preparação** 🔧
```
📋 Obter commit hash atual (8 chars)
📋 Verificar branch ativo
📋 Analisar alterações não commitadas
📋 Confirmar configurações
```

### **Fase 3: Build** 🏗️
```
🐳 Construir imagem Docker
🐳 Aplicar tag com commit hash
🐳 Criar tag 'latest' adicional
🐳 Validar imagem construída
```

### **Fase 4: Upload** ☁️
```
🔐 Login automático no ECR
📤 Push da imagem versionada
📤 Push da tag latest
📤 Verificar upload completo
```

### **Fase 5: Deploy** 🚀
```
📝 Criar nova Task Definition
📝 Configurar variáveis de ambiente
📝 Integrar Secrets Manager
🔄 Atualizar serviço ECS
⏳ Aguardar estabilização
✅ Confirmar deploy bem-sucedido
```

## 🎯 **Exemplos Práticos**

### **Cenário 1: Deploy de Nova Feature**
```bash
# 1. Fazer commit das alterações
git add .
git commit -m "feat: adicionar nova funcionalidade"

# 2. Executar deploy
./ecs-deploy.sh deploy

# Resultado: Imagem taggeada com hash do commit (ex: a1b2c3d4)
```

### **Cenário 2: Rollback de Emergência**
```bash
# 1. Listar versões disponíveis
./ecs-deploy.sh list

# 2. Identificar versão estável anterior
# 3. Executar rollback
./ecs-deploy.sh rollback f9e8d7c6

# Resultado: Aplicação volta para versão anterior em ~2 minutos
```

### **Cenário 3: Verificação de Deploy**
```bash
# 1. Executar deploy
./ecs-deploy.sh deploy

# 2. Verificar logs
aws logs tail /ecs/task-def-bia --follow

# 3. Testar aplicação
curl http://54.161.19.13
```

## 🔍 **Monitoramento e Logs**

### **CloudWatch Logs**
```bash
# Ver logs em tempo real
aws logs tail /ecs/task-def-bia --follow

# Ver logs de período específico
aws logs filter-log-events \
  --log-group-name /ecs/task-def-bia \
  --start-time $(date -d '1 hour ago' +%s)000
```

### **Status do Serviço**
```bash
# Verificar status do serviço
aws ecs describe-services \
  --cluster cluster-bia \
  --services service-bia

# Ver tasks em execução
aws ecs list-tasks \
  --cluster cluster-bia \
  --service-name service-bia
```

## ⚠️ **Troubleshooting**

### **Problema: Docker não está rodando**
```bash
# Solução
sudo systemctl start docker
sudo systemctl enable docker
```

### **Problema: Credenciais AWS inválidas**
```bash
# Verificar credenciais
aws sts get-caller-identity

# Reconfigurar se necessário
aws configure
```

### **Problema: Repositório ECR não existe**
```bash
# Criar repositório
aws ecr create-repository \
  --repository-name bia \
  --region us-east-1
```

### **Problema: Task Definition falha**
```bash
# Verificar logs do ECS
aws ecs describe-services \
  --cluster cluster-bia \
  --services service-bia \
  --query 'services[0].events[0:5]'
```

### **Problema: Imagem não encontrada**
```bash
# Listar imagens no ECR
aws ecr list-images \
  --repository-name bia \
  --region us-east-1
```

## 📈 **Otimizações e Boas Práticas**

### **1. Cache do Docker**
```bash
# O script usa cache automático do Docker
# Para rebuild completo (se necessário):
docker system prune -f
./ecs-deploy.sh deploy
```

### **2. Versionamento Semântico**
```bash
# Use tags Git para releases importantes
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# O script ainda usará commit hash, mas você terá referência
```

### **3. Ambiente de Staging**
```bash
# Modifique as variáveis no script para staging:
# ECS_CLUSTER="cluster-bia-staging"
# ECS_SERVICE="service-bia-staging"
```

### **4. Rollback Automático**
```bash
# Criar script de rollback automático em caso de falha
#!/bin/bash
LAST_GOOD_VERSION=$(aws ecr describe-images \
  --repository-name bia \
  --query 'sort_by(imageDetails,&imagePushedAt)[-2].imageTags[0]' \
  --output text)

./ecs-deploy.sh rollback $LAST_GOOD_VERSION
```

## 🔐 **Segurança**

### **Variáveis de Ambiente Seguras**
- ✅ **DB_PWD**: Obtida do AWS Secrets Manager
- ✅ **Credenciais AWS**: Nunca expostas no código
- ✅ **Imagens**: Armazenadas em repositório privado ECR

### **Permissões Necessárias**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:*",
                "ecs:*",
                "secretsmanager:GetSecretValue",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
```

## 📊 **Métricas e Monitoramento**

### **Métricas Importantes**
- **Deploy Time**: Tempo total do deploy (~5-10 minutos)
- **Image Size**: Tamanho da imagem Docker (~400MB)
- **Service Stability**: Tempo para estabilização (~2-3 minutos)
- **Rollback Time**: Tempo de rollback (~1-2 minutos)

### **Alertas Recomendados**
```bash
# CPU alta
aws cloudwatch put-metric-alarm \
  --alarm-name "ECS-HighCPU" \
  --alarm-description "ECS CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# Memory alta
aws cloudwatch put-metric-alarm \
  --alarm-name "ECS-HighMemory" \
  --alarm-description "ECS Memory > 80%" \
  --metric-name MemoryUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

## 🎉 **Conclusão**

O script `ecs-deploy.sh` fornece uma solução completa e robusta para deploy automatizado no ECS com:

- ✅ **Versionamento confiável** baseado em Git
- ✅ **Deploy zero-downtime** com rollback rápido
- ✅ **Integração completa** com serviços AWS
- ✅ **Monitoramento** e logs centralizados
- ✅ **Segurança** com Secrets Manager
- ✅ **Facilidade de uso** com comandos simples

**Próximos passos recomendados:**
1. Testar o script em ambiente de desenvolvimento
2. Configurar alertas de monitoramento
3. Criar pipeline CI/CD integrado
4. Implementar testes automatizados pré-deploy

---

**📅 Criado**: 2025-08-01  
**🔧 Versão**: 1.0  
**👨‍💻 Autor**: Amazon Q
