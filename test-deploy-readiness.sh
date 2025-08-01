#!/bin/bash

# Script de teste para verificar se o deploy pode ser executado
# Autor: Amazon Q

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROFILE="nxt"
CLUSTER_NAME="cluster-bia"
SERVICE_NAME="service-bia"
ECR_REGISTRY="873976611862.dkr.ecr.us-east-1.amazonaws.com"

echo -e "${BLUE}🧪 TESTE DE PRONTIDÃO PARA DEPLOY${NC}"
echo "================================="

echo -e "\n${YELLOW}1. Verificando arquivos necessários...${NC}"

# Verificar se os arquivos existem
if [ -f "build.sh" ]; then
    echo -e "   ${GREEN}✅ build.sh encontrado${NC}"
else
    echo -e "   ${RED}❌ build.sh não encontrado${NC}"
    exit 1
fi

if [ -f "deploy-fixed.sh" ]; then
    echo -e "   ${GREEN}✅ deploy-fixed.sh criado${NC}"
else
    echo -e "   ${RED}❌ deploy-fixed.sh não encontrado${NC}"
    exit 1
fi

if [ -f "Dockerfile" ]; then
    echo -e "   ${GREEN}✅ Dockerfile encontrado${NC}"
else
    echo -e "   ${RED}❌ Dockerfile não encontrado${NC}"
    exit 1
fi

echo -e "\n${YELLOW}2. Verificando AWS CLI e credenciais...${NC}"

# Verificar AWS CLI
if command -v aws &> /dev/null; then
    echo -e "   ${GREEN}✅ AWS CLI disponível${NC}"
else
    echo -e "   ${RED}❌ AWS CLI não encontrado${NC}"
    exit 1
fi

# Verificar credenciais
if aws --profile $PROFILE sts get-caller-identity &> /dev/null; then
    echo -e "   ${GREEN}✅ Credenciais AWS funcionando (profile: $PROFILE)${NC}"
else
    echo -e "   ${RED}❌ Erro nas credenciais AWS${NC}"
    exit 1
fi

echo -e "\n${YELLOW}3. Verificando Docker...${NC}"

# Verificar Docker
if command -v docker &> /dev/null; then
    echo -e "   ${GREEN}✅ Docker disponível${NC}"
else
    echo -e "   ${RED}❌ Docker não encontrado${NC}"
    exit 1
fi

# Verificar se Docker está rodando
if docker info &> /dev/null; then
    echo -e "   ${GREEN}✅ Docker daemon rodando${NC}"
else
    echo -e "   ${RED}❌ Docker daemon não está rodando${NC}"
    exit 1
fi

echo -e "\n${YELLOW}4. Verificando acesso ao ECR...${NC}"

# Testar login no ECR
if aws --profile $PROFILE ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY &> /dev/null; then
    echo -e "   ${GREEN}✅ Login no ECR funcionando${NC}"
else
    echo -e "   ${RED}❌ Erro no login do ECR${NC}"
    exit 1
fi

echo -e "\n${YELLOW}5. Verificando ECS Cluster...${NC}"

# Verificar se o cluster existe
CLUSTER_STATUS=$(aws --profile $PROFILE ecs describe-clusters \
    --clusters $CLUSTER_NAME \
    --query 'clusters[0].status' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$CLUSTER_STATUS" = "ACTIVE" ]; then
    echo -e "   ${GREEN}✅ Cluster $CLUSTER_NAME está ativo${NC}"
else
    echo -e "   ${RED}❌ Cluster $CLUSTER_NAME não encontrado ou inativo${NC}"
    exit 1
fi

echo -e "\n${YELLOW}6. Verificando ECS Service...${NC}"

# Verificar se o service existe
SERVICE_STATUS=$(aws --profile $PROFILE ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].status' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$SERVICE_STATUS" = "ACTIVE" ]; then
    echo -e "   ${GREEN}✅ Service $SERVICE_NAME está ativo${NC}"
    
    # Mostrar status atual
    echo -e "   ${CYAN}Status atual do service:${NC}"
    aws --profile $PROFILE ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --query 'services[0].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount,TaskDefinition:taskDefinition}' \
        --output table
else
    echo -e "   ${RED}❌ Service $SERVICE_NAME não encontrado ou inativo${NC}"
    exit 1
fi

echo -e "\n${YELLOW}7. Verificando repositório ECR...${NC}"

# Verificar se o repositório ECR existe
ECR_REPO_STATUS=$(aws --profile $PROFILE ecr describe-repositories \
    --repository-names bia \
    --query 'repositories[0].repositoryName' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$ECR_REPO_STATUS" = "bia" ]; then
    echo -e "   ${GREEN}✅ Repositório ECR 'bia' existe${NC}"
else
    echo -e "   ${RED}❌ Repositório ECR 'bia' não encontrado${NC}"
    exit 1
fi

echo -e "\n${YELLOW}8. Verificando aplicação atual...${NC}"

# Verificar se a aplicação está rodando
if curl -s http://localhost:3001/api/versao &> /dev/null; then
    echo -e "   ${GREEN}✅ Aplicação atual respondendo${NC}"
    echo -e "   ${CYAN}Versão atual: $(curl -s http://localhost:3001/api/versao)${NC}"
else
    echo -e "   ${YELLOW}⚠️  Aplicação local não está respondendo${NC}"
fi

echo -e "\n${GREEN}🎉 TODOS OS TESTES PASSARAM!${NC}"
echo ""
echo -e "${CYAN}📋 Resumo da verificação:${NC}"
echo "  ✅ Arquivos necessários presentes"
echo "  ✅ AWS CLI e credenciais funcionando"
echo "  ✅ Docker disponível e rodando"
echo "  ✅ Acesso ao ECR funcionando"
echo "  ✅ ECS Cluster ativo: $CLUSTER_NAME"
echo "  ✅ ECS Service ativo: $SERVICE_NAME"
echo "  ✅ Repositório ECR disponível"
echo "  ✅ Sistema pronto para deploy"
echo ""
echo -e "${BLUE}🚀 PRONTO PARA EXECUTAR DEPLOY!${NC}"
echo ""
echo -e "${YELLOW}📋 Comandos que serão executados no deploy:${NC}"
echo "  1. ./build.sh (build da imagem Docker)"
echo "  2. docker push para ECR"
echo "  3. aws ecs update-service --force-new-deployment"
echo "  4. aws ecs wait services-stable"
echo ""
echo -e "${CYAN}💡 Para executar o deploy:${NC}"
echo "  ./deploy-fixed.sh"
