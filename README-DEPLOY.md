# 🚀 Script de Deploy ECS - Aplicação Bia

## 📋 **Resumo**

Script automatizado para deploy da aplicação Bia no Amazon ECS com versionamento baseado em commit hash do Git.

## ⚡ **Quick Start**

```bash
# 1. Navegar para o diretório do projeto
cd /home/ec2-user/bia

# 2. Executar deploy
./ecs-deploy.sh deploy

# 3. Verificar versões disponíveis
./ecs-deploy.sh list

# 4. Fazer rollback se necessário
./ecs-deploy.sh rollback <commit-hash>
```

## 🎯 **Características**

### ✅ **Versionamento Automático**
- Cada deploy cria uma imagem Docker com tag baseada no commit hash (8 caracteres)
- Exemplo: `3bfdfc1d` (commit atual)
- Rastreabilidade completa entre código e deploy

### ✅ **Deploy Zero-Downtime**
- Atualização gradual do serviço ECS
- Rollback rápido em caso de problemas
- Monitoramento automático da estabilização

### ✅ **Integração Completa**
- **ECR**: Upload automático de imagens
- **ECS**: Criação de Task Definitions e atualização de serviços
- **Secrets Manager**: Credenciais seguras do banco
- **CloudWatch**: Logs centralizados

## 📊 **Exemplo de Uso Completo**

### **Cenário: Deploy de Nova Feature**

```bash
# 1. Fazer alterações no código
echo "Nova funcionalidade" >> client/src/App.jsx

# 2. Commit das alterações
git add .
git commit -m "feat: adicionar nova funcionalidade"

# 3. Verificar commit hash
git rev-parse --short=8 HEAD
# Output: a1b2c3d4

# 4. Executar deploy
./ecs-deploy.sh deploy
```

**Resultado esperado:**
```
=============================================================================
 DEPLOY DA APLICAÇÃO BIA
=============================================================================
📋 Verificando pré-requisitos...
✅ Todos os pré-requisitos atendidos
ℹ️  Branch atual: main
ℹ️  Commit hash: a1b2c3d4
📋 Fazendo login no Amazon ECR...
✅ Login no ECR realizado com sucesso
📋 Verificando repositório ECR...
✅ Repositório ECR encontrado
📋 Construindo imagem Docker...
ℹ️  Tag da imagem: 873976611862.dkr.ecr.us-east-1.amazonaws.com/bia:a1b2c3d4
✅ Imagem construída com sucesso
📋 Enviando imagem para ECR...
✅ Imagem enviada para ECR com sucesso
📋 Criando nova Task Definition...
✅ Task Definition criada: arn:aws:ecs:us-east-1:873976611862:task-definition/task-def-bia:4
📋 Atualizando serviço ECS...
✅ Serviço atualizado com sucesso
ℹ️  Aguardando estabilização do serviço...
✅ Serviço estabilizado com commit hash: a1b2c3d4
=============================================================================
 DEPLOY CONCLUÍDO COM SUCESSO
=============================================================================
✅ Versão deployada: a1b2c3d4
✅ Task Definition: arn:aws:ecs:us-east-1:873976611862:task-definition/task-def-bia:4
ℹ️  Acesse a aplicação em: http://54.161.19.13
```

### **Cenário: Rollback de Emergência**

```bash
# 1. Listar versões disponíveis
./ecs-deploy.sh list

# 2. Identificar versão anterior estável
# Output mostra: 3bfdfc1d (versão anterior)

# 3. Executar rollback
./ecs-deploy.sh rollback 3bfdfc1d
```

**Resultado esperado:**
```
=============================================================================
 ROLLBACK PARA VERSÃO 3bfdfc1d
=============================================================================
📋 Verificando se a versão existe no ECR...
✅ Imagem encontrada no ECR
📋 Criando Task Definition para rollback...
✅ Task Definition criada: arn:aws:ecs:us-east-1:873976611862:task-definition/task-def-bia:5
📋 Atualizando serviço ECS...
✅ Serviço atualizado com sucesso
ℹ️  Aguardando estabilização do serviço...
✅ Serviço estabilizado com commit hash: 3bfdfc1d
✅ Rollback concluído para versão: 3bfdfc1d
```

## 🔧 **Configurações do Script**

### **Variáveis Principais**
```bash
PROJECT_NAME="bia"
PROJECT_DIR="/home/ec2-user/bia"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="873976611862"
ECS_CLUSTER="cluster-bia"
ECS_SERVICE="service-bia"
TASK_DEFINITION_FAMILY="task-def-bia"
```

### **Recursos AWS Utilizados**
- **ECR Repository**: `873976611862.dkr.ecr.us-east-1.amazonaws.com/bia`
- **ECS Cluster**: `cluster-bia`
- **ECS Service**: `service-bia`
- **Secrets Manager**: Credenciais do RDS
- **CloudWatch Logs**: `/ecs/task-def-bia`

## 📈 **Monitoramento**

### **Verificar Status do Deploy**
```bash
# Status do serviço ECS
aws ecs describe-services \
  --cluster cluster-bia \
  --services service-bia \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount}'

# Logs da aplicação
aws logs tail /ecs/task-def-bia --follow

# Testar aplicação
curl http://54.161.19.13
```

### **Métricas Importantes**
- **Deploy Time**: ~5-10 minutos
- **Rollback Time**: ~1-2 minutos
- **Image Size**: ~377MB
- **Zero Downtime**: ✅ Garantido

## 🛡️ **Segurança**

### **Credenciais Protegidas**
- ✅ **Senha do banco**: AWS Secrets Manager
- ✅ **Credenciais AWS**: IAM Roles
- ✅ **Imagens**: ECR privado
- ✅ **Logs**: CloudWatch protegido

### **Permissões Necessárias**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecs:RegisterTaskDefinition",
                "ecs:UpdateService",
                "ecs:DescribeServices",
                "ecs:ListTaskDefinitions",
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

## 🚨 **Troubleshooting**

### **Problemas Comuns**

#### **1. Docker não está rodando**
```bash
# Verificar status
sudo systemctl status docker

# Iniciar se necessário
sudo systemctl start docker
```

#### **2. Credenciais AWS inválidas**
```bash
# Testar credenciais
aws sts get-caller-identity

# Reconfigurar
aws configure
```

#### **3. Repositório ECR não existe**
```bash
# Criar repositório
aws ecr create-repository --repository-name bia --region us-east-1
```

#### **4. Alterações não commitadas**
```bash
# O script avisa sobre alterações não commitadas
# Opções:
# 1. Fazer commit: git add . && git commit -m "message"
# 2. Continuar mesmo assim: responder 'y' quando perguntado
# 3. Cancelar: responder 'n' e fazer commit primeiro
```

## 📚 **Documentação Adicional**

- **Guia Completo**: `ECS-DEPLOY-GUIDE.md`
- **Ajuda do Script**: `./ecs-deploy.sh help`
- **Logs AWS**: CloudWatch Console → Log Groups → `/ecs/task-def-bia`

## 🎉 **Benefícios**

### **Para Desenvolvedores**
- ✅ Deploy com um comando
- ✅ Rollback instantâneo
- ✅ Versionamento automático
- ✅ Logs centralizados

### **Para Operações**
- ✅ Zero downtime
- ✅ Rastreabilidade completa
- ✅ Monitoramento integrado
- ✅ Segurança por padrão

### **Para o Negócio**
- ✅ Releases mais rápidos
- ✅ Menor risco de falhas
- ✅ Recuperação rápida
- ✅ Maior confiabilidade

---

**🚀 Pronto para usar!** Execute `./ecs-deploy.sh deploy` e veja a mágica acontecer!

**📅 Criado**: 2025-08-01  
**🔧 Versão**: 1.0  
**👨‍💻 Commit Atual**: `3bfdfc1d`
