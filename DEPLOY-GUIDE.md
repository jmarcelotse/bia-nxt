# 🚀 GUIA DE DEPLOY - PROJETO BIA

**Data**: 02/08/2025  
**Versão**: 2.0  
**Script**: `deploy-current.sh`

## 📋 VISÃO GERAL

Este documento explica o funcionamento do script de deploy automatizado do Projeto BIA, que realiza o build, push e deployment da aplicação no Amazon ECS com Application Load Balancer.

## 🎯 OBJETIVO

O script `deploy-current.sh` automatiza todo o processo de deploy, incluindo:
- Build da imagem Docker
- Push para Amazon ECR
- Criação de nova Task Definition
- Atualização do serviço ECS
- Verificação de saúde da aplicação

## 🏗️ ARQUITETURA ATUAL

### **Infraestrutura de Deploy**
```
Código Local → Docker Build → ECR → ECS Task Definition → ECS Service → ALB → Usuários
```

### **Recursos AWS Utilizados**
- **ECS Cluster**: `cluster-bia-alb`
- **ECS Service**: `service-bia-alb`
- **Task Definition**: `task-def-bia-alb`
- **ECR Repository**: `873976611862.dkr.ecr.us-east-1.amazonaws.com/bia`
- **Application Load Balancer**: `bia-alb`
- **Target Group**: `tg-bia`

## 🔧 CONFIGURAÇÕES DO SCRIPT

### **Variáveis Principais**
```bash
REGION="us-east-1"
CLUSTER_NAME="cluster-bia-alb"
SERVICE_NAME="service-bia-alb"
TASK_DEFINITION="task-def-bia-alb"
ECR_REPOSITORY="873976611862.dkr.ecr.us-east-1.amazonaws.com/bia"
APPLICATION_URL="http://bia-alb-690586468.us-east-1.elb.amazonaws.com"
```

### **Configurações do Banco de Dados**
```bash
DB_HOST="bia.ccxceeiycgx6.us-east-1.rds.amazonaws.com"
DB_PORT="5432"
DB_USER="postgres"
DB_SECRET_ARN="arn:aws:secretsmanager:us-east-1:873976611862:secret:rds!db-351c97aa-df32-43ee-8182-b2872962dbb7-mHDOMB"
```

## 📝 FUNCIONAMENTO DETALHADO

### **Fase 1: Verificação de Pré-requisitos**
```bash
check_prerequisites()
```
- ✅ Verifica se está no diretório correto
- ✅ Confirma se Docker está rodando
- ✅ Valida configuração do AWS CLI
- ✅ Faz commit automático de mudanças pendentes

### **Fase 2: Preparação**
```bash
get_commit_hash()
```
- 🔍 Obtém hash do commit atual
- 🏷️ Usa como tag da imagem Docker
- 📝 Registra para rastreabilidade

### **Fase 3: Build e Push**
```bash
# Login no ECR
aws ecr get-login-password | docker login

# Build da imagem
docker build -t bia:$COMMIT_HASH .
docker tag bia:$COMMIT_HASH $ECR_REPOSITORY:$COMMIT_HASH
docker tag bia:$COMMIT_HASH $ECR_REPOSITORY:latest

# Push para ECR
docker push $ECR_REPOSITORY:$COMMIT_HASH
docker push $ECR_REPOSITORY:latest
```

### **Fase 4: Task Definition**
Cria nova Task Definition com:
- **Imagem**: Nova versão com commit hash
- **CPU**: 1024 units (1 vCPU)
- **Memória**: 400 MB (soft limit)
- **Port Mapping**: Container 8080 → Host aleatório
- **Variáveis de Ambiente**: DB_HOST, DB_PORT, DB_USER, COMMIT_HASH
- **Secrets**: DB_PWD via Secrets Manager
- **Logs**: CloudWatch Logs

### **Fase 5: Deployment**
```bash
# Atualizar serviço ECS
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $TASK_DEF_ARN

# Aguardar estabilização
aws ecs wait services-stable
```

### **Fase 6: Verificação**
- 🔍 Status do deployment
- 📊 Contagem de tasks (running/desired)
- ❤️ Health check do ALB
- 🌐 Teste de conectividade da aplicação

## 🚀 COMO USAR

### **Deploy Normal**
```bash
cd /home/ec2-user/bia
./deploy-current.sh
```

### **Deploy com Rollback**
```bash
# Para fazer rollback
./deploy-current.sh rollback arn:aws:ecs:us-east-1:873976611862:task-definition/task-def-bia-alb:4
```

## 📊 ALTERAÇÕES FEITAS NO DEPLOY

### **🔄 Atualizações da Versão 2.0**

#### **1. Configurações Atualizadas**
- ✅ **URL da Aplicação**: Atualizada para ALB (`bia-alb-690586468.us-east-1.elb.amazonaws.com`)
- ✅ **Task Definition**: Corrigida para `task-def-bia-alb`
- ✅ **Log Group**: Atualizado para `/ecs/task-def-bia-alb`
- ✅ **Port Mapping**: Host port 0 (aleatório) para compatibilidade com ALB

#### **2. Secrets Manager**
- ✅ **ARN Corrigido**: Formato `$DB_SECRET_ARN:password::`
- ✅ **Autenticação Segura**: Senha não exposta em variáveis de ambiente

#### **3. Verificações Aprimoradas**
- ✅ **Health Check ALB**: Verifica targets saudáveis
- ✅ **Timeout**: 15 minutos para estabilização
- ✅ **Retry Logic**: 5 tentativas para teste de conectividade

#### **4. Funcionalidade de Rollback**
- ✅ **Rollback Automático**: Suporte a rollback para versão anterior
- ✅ **Validação**: Verificação de argumentos

#### **5. Logging e Rastreabilidade**
- ✅ **Deploy Info**: Arquivo JSON com informações do deploy
- ✅ **Commit Tracking**: Hash do commit em variável de ambiente
- ✅ **Timestamps**: Registro de data/hora do deploy

## 📁 ARQUIVOS GERADOS

### **Durante o Deploy**
- `deploy-info-{COMMIT_HASH}.json` - Informações do deploy
- `/tmp/task-definition-{COMMIT_HASH}.json` - Task definition temporária

### **Exemplo de deploy-info.json**
```json
{
    "deploy_timestamp": "2025-08-02T10:30:00Z",
    "commit_hash": "abc1234",
    "task_definition_arn": "arn:aws:ecs:us-east-1:873976611862:task-definition/task-def-bia-alb:5",
    "image": "873976611862.dkr.ecr.us-east-1.amazonaws.com/bia:abc1234",
    "cluster": "cluster-bia-alb",
    "service": "service-bia-alb",
    "application_url": "http://bia-alb-690586468.us-east-1.elb.amazonaws.com",
    "deployment_status": "COMPLETED",
    "running_tasks": "2/2",
    "healthy_targets": "2"
}
```

## 🔍 MONITORAMENTO

### **Durante o Deploy**
```bash
# Acompanhar logs
aws logs tail /ecs/task-def-bia-alb --follow --region us-east-1

# Status do serviço
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb --region us-east-1

# Health do ALB
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:873976611862:targetgroup/tg-bia/2f1d581fe8fec016 --region us-east-1
```

### **Após o Deploy**
```bash
# Testar aplicação
curl http://bia-alb-690586468.us-east-1.elb.amazonaws.com/api/versao

# Verificar tasks
aws ecs list-tasks --cluster cluster-bia-alb --service-name service-bia-alb --region us-east-1
```

## ⚠️ TROUBLESHOOTING

### **Problemas Comuns**

#### **1. Erro de Login ECR**
```bash
# Solução
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 873976611862.dkr.ecr.us-east-1.amazonaws.com
```

#### **2. Build Falha**
```bash
# Verificar Dockerfile
docker build -t test .

# Verificar dependências
npm install
cd client && npm install
```

#### **3. Task Não Inicia**
```bash
# Verificar logs
aws logs tail /ecs/task-def-bia-alb --region us-east-1

# Verificar task definition
aws ecs describe-task-definition --task-definition task-def-bia-alb --region us-east-1
```

#### **4. ALB Não Responde**
```bash
# Verificar targets
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:us-east-1:873976611862:targetgroup/tg-bia/2f1d581fe8fec016 --region us-east-1

# Verificar security groups
aws ec2 describe-security-groups --group-ids sg-0dc261beafaf9d4a7 --region us-east-1
```

## 🔐 SEGURANÇA

### **Boas Práticas Implementadas**
- ✅ **Secrets Manager**: Credenciais do banco seguras
- ✅ **IAM Roles**: Permissões mínimas necessárias
- ✅ **ECR**: Imagens privadas
- ✅ **VPC**: Rede isolada
- ✅ **Security Groups**: Controle de acesso

## 💰 IMPACTO DE CUSTOS

### **Recursos Utilizados no Deploy**
- **ECR Storage**: ~$0.10/GB/mês por imagem
- **CloudWatch Logs**: ~$0.50/GB ingerido
- **Data Transfer**: Variável conforme uso

### **Otimizações**
- ✅ Multi-stage build no Dockerfile
- ✅ Limpeza de cache npm
- ✅ Imagens slim do Node.js

## 🎯 PRÓXIMOS PASSOS

### **Melhorias Planejadas**
- [ ] **Blue/Green Deployment**: Deploy sem downtime
- [ ] **Automated Rollback**: Rollback automático em caso de falha
- [ ] **Slack Notifications**: Notificações de deploy
- [ ] **Performance Tests**: Testes automatizados pós-deploy
- [ ] **Multi-Environment**: Suporte a dev/staging/prod

## 📞 SUPORTE

- **Desenvolvedor**: Jose Marcelo Tse
- **Email**: jmarcelotse@hotmail.com
- **Região AWS**: us-east-1
- **Cluster**: cluster-bia-alb

---
*Documentação atualizada em: 02/08/2025*  
*Versão do Script: 2.0*  
*Próxima revisão: 09/08/2025*
