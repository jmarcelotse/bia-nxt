# 🚀 Projeto BIA - Aplicação de Gerenciamento de Tarefas

**Versão**: 4.2.0  
**Última Atualização**: 02/08/2025 10:01:36 UTC  
**Status**: ✅ **OPERACIONAL**

## 📋 Sobre o Projeto

O Projeto BIA é uma aplicação completa de gerenciamento de tarefas desenvolvida para demonstrar implementação de infraestrutura moderna na AWS.

### **Tecnologias Utilizadas**
- **Frontend**: React 17 + Vite
- **Backend**: Node.js + Express  
- **Banco de Dados**: PostgreSQL 17.4
- **Infraestrutura**: Amazon ECS + ALB
- **Container**: Docker
- **Autenticação DB**: AWS Secrets Manager

## 🏗️ Arquitetura Atual

```
Internet → ALB (bia-alb) → ECS Service (service-bia-alb) → RDS PostgreSQL
                ↓
        Target Group (tg-bia)
                ↓  
    ECS Cluster (cluster-bia-alb)
    ├── EC2 Instance (us-east-1a)
    └── EC2 Instance (us-east-1b)
```

## 🌐 Acesso à Aplicação

- **URL Principal**: http://bia-alb-690586468.us-east-1.elb.amazonaws.com
- **API Versão**: http://bia-alb-690586468.us-east-1.elb.amazonaws.com/api/versao  
- **API Tarefas**: http://bia-alb-690586468.us-east-1.elb.amazonaws.com/api/tarefas

## 🔧 Configuração Local

### **Pré-requisitos**
- Node.js 22+
- Docker
- AWS CLI configurado

### **Executar Localmente**
```bash
# Instalar dependências
npm install
cd client && npm install

# Build do frontend
cd client && npm run build

# Executar aplicação
npm start
```

## 🚀 Deploy na AWS

### **Recursos Criados**
- **ECS Cluster**: cluster-bia-alb (2 instâncias t3.micro)
- **ECS Service**: service-bia-alb (2 tasks)
- **Task Definition**: task-def-bia-alb:4
- **ALB**: bia-alb com target group tg-bia
- **RDS**: PostgreSQL com Secrets Manager

### **Scripts de Deploy**
```bash
# Criar cluster ECS
./create-ecs-cluster-alb-working.sh

# Criar task definition  
./create-task-definition-bia-alb.sh

# Criar serviço ECS
./create-ecs-service-wait-cleanup.sh
```

## 📊 Status Atual

- **Cluster Status**: ACTIVE
- **Service Status**: ACTIVE  
- **Running Tasks**: 2/2
- **ALB State**: active
- **Healthy Targets**: 2/2

## 🔍 Monitoramento

### **Health Checks**
```bash
# Verificar aplicação
curl http://bia-alb-690586468.us-east-1.elb.amazonaws.com/api/versao

# Status do serviço
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb --region us-east-1

# Logs da aplicação
aws logs tail /ecs/task-def-bia-alb --follow --region us-east-1
```

## 📁 Estrutura do Projeto

```
/home/ec2-user/bia/          # Código da aplicação
├── api/                     # Backend API
├── client/                  # Frontend React
├── config/                  # Configurações
├── database/               # Migrations
├── Dockerfile              # Container config
└── package.json            # Dependências

/home/ec2-user/2/           # Scripts e configurações AWS
├── create-*.sh             # Scripts de criação
├── *-info.json            # Informações dos recursos
└── *.md                   # Documentação
```

## 💰 Custos Estimados

| Recurso | Tipo | Custo Mensal |
|---------|------|--------------|
| EC2 | 2x t3.micro | ~$17.00 |
| ALB | Application LB | ~$16.20 |
| RDS | db.t3.micro | ~$12.60 |
| Logs | CloudWatch | ~$0.50 |
| **Total** | | **~$46.30** |

## 🔐 Segurança

- **Secrets Manager**: Credenciais do banco seguras
- **Security Groups**: Isolamento de rede
- **IAM Roles**: Permissões mínimas necessárias
- **VPC**: Rede isolada

## 🎯 Próximos Passos

- [ ] Implementar HTTPS com certificado SSL
- [ ] Configurar domínio personalizado  
- [ ] Adicionar auto scaling
- [ ] Implementar CI/CD pipeline
- [ ] Configurar monitoramento avançado

## 📞 Suporte

- **Desenvolvedor**: Jose Marcelo Tse
- **Email**: jmarcelotse@hotmail.com
- **Região AWS**: us-east-1

---
*Projeto atualizado em: 02/08/2025 10:01:36 UTC*
