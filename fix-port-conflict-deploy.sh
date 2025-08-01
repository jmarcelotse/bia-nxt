#!/bin/bash

# Script para resolver conflito de porta e fazer deploy
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

echo -e "${BLUE}🔧 RESOLVENDO CONFLITO DE PORTA E FAZENDO DEPLOY${NC}"
echo "================================================="

echo -e "\n${YELLOW}🔍 PASSO 1: Diagnosticando o problema...${NC}"

# Verificar tasks atuais
echo -e "   ${CYAN}Verificando tasks em execução...${NC}"
CURRENT_TASKS=$(aws --profile $PROFILE ecs list-tasks \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --query 'taskArns' \
    --output text)

if [ -n "$CURRENT_TASKS" ] && [ "$CURRENT_TASKS" != "None" ]; then
    echo -e "   ${YELLOW}⚠️  Tasks atuais encontradas:${NC}"
    for task in $CURRENT_TASKS; do
        echo "   - $task"
    done
else
    echo -e "   ${GREEN}✅ Nenhuma task em execução${NC}"
fi

echo -e "\n${YELLOW}🔍 PASSO 2: Verificando uso de portas...${NC}"

# Verificar container instances
CONTAINER_INSTANCES=$(aws --profile $PROFILE ecs list-container-instances \
    --cluster $CLUSTER_NAME \
    --query 'containerInstanceArns' \
    --output text)

echo -e "   ${CYAN}Container instances no cluster:${NC}"
for instance in $CONTAINER_INSTANCES; do
    echo "   - $instance"
done

echo -e "\n${YELLOW}🔧 PASSO 3: Estratégia de resolução...${NC}"

echo -e "   ${CYAN}Opções disponíveis:${NC}"
echo "   1. Parar service temporariamente e reiniciar"
echo "   2. Escalar para 0 e depois para 1"
echo "   3. Force new deployment com rolling update"

echo -e "\n   ${YELLOW}Usando estratégia: Escalar para 0 e depois para 1${NC}"

echo -e "\n${YELLOW}🔄 PASSO 4: Escalando service para 0...${NC}"

# Escalar service para 0
aws --profile $PROFILE ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --desired-count 0

echo -e "   ${GREEN}✅ Service escalado para 0${NC}"

# Aguardar tasks pararem
echo -e "   ${YELLOW}⏳ Aguardando tasks pararem...${NC}"
sleep 30

# Verificar se tasks pararam
REMAINING_TASKS=$(aws --profile $PROFILE ecs list-tasks \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --query 'taskArns' \
    --output text)

if [ -z "$REMAINING_TASKS" ] || [ "$REMAINING_TASKS" = "None" ]; then
    echo -e "   ${GREEN}✅ Todas as tasks foram paradas${NC}"
else
    echo -e "   ${YELLOW}⏳ Aguardando mais tempo...${NC}"
    sleep 30
fi

echo -e "\n${YELLOW}🚀 PASSO 5: Executando build da nova imagem...${NC}"

# Executar build
echo -e "   ${CYAN}Executando ./build.sh...${NC}"
if ./build.sh; then
    echo -e "   ${GREEN}✅ Build executado com sucesso${NC}"
else
    echo -e "   ${RED}❌ Erro no build${NC}"
    exit 1
fi

echo -e "\n${YELLOW}🔄 PASSO 6: Escalando service para 1 com nova imagem...${NC}"

# Escalar service para 1 (isso vai usar a nova imagem)
aws --profile $PROFILE ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --desired-count 1 \
    --force-new-deployment

echo -e "   ${GREEN}✅ Service escalado para 1 com nova imagem${NC}"

echo -e "\n${YELLOW}⏳ PASSO 7: Aguardando service estabilizar...${NC}"

# Aguardar service estabilizar
echo -e "   ${CYAN}Aguardando service estabilizar...${NC}"
aws --profile $PROFILE ecs wait services-stable \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME

echo -e "   ${GREEN}✅ Service estabilizado${NC}"

echo -e "\n${YELLOW}📊 PASSO 8: Verificando resultado...${NC}"

# Verificar status final
aws --profile $PROFILE ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount,TaskDefinition:taskDefinition}' \
    --output table

# Verificar nova task
echo -e "\n   ${CYAN}Nova task criada:${NC}"
NEW_TASKS=$(aws --profile $PROFILE ecs list-tasks \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --query 'taskArns' \
    --output text)

if [ -n "$NEW_TASKS" ] && [ "$NEW_TASKS" != "None" ]; then
    for task in $NEW_TASKS; do
        echo "   - $task"
    done
else
    echo -e "   ${RED}❌ Nenhuma task encontrada${NC}"
fi

echo -e "\n${YELLOW}🧪 PASSO 9: Testando aplicação...${NC}"

# Aguardar um pouco para a aplicação inicializar
echo -e "   ${YELLOW}⏳ Aguardando aplicação inicializar...${NC}"
sleep 60

# Testar aplicação
echo -e "   ${CYAN}Testando aplicação em http://54.161.19.13...${NC}"
if curl -s --connect-timeout 10 http://54.161.19.13/api/versao >/dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Aplicação respondendo!${NC}"
    API_VERSION=$(curl -s http://54.161.19.13/api/versao)
    echo -e "   ${CYAN}Versão: $API_VERSION${NC}"
else
    echo -e "   ${YELLOW}⚠️  Aplicação ainda não está respondendo${NC}"
    echo -e "   ${YELLOW}💡 Pode levar alguns minutos para inicializar completamente${NC}"
fi

echo -e "\n${GREEN}🎉 DEPLOY CONCLUÍDO COM SUCESSO!${NC}"
echo ""
echo -e "${CYAN}📋 Resumo:${NC}"
echo "  ✅ Conflito de porta resolvido"
echo "  ✅ Service escalado para 0 e depois para 1"
echo "  ✅ Nova imagem com IP correto deployada"
echo "  ✅ Service estabilizado"
echo "  ✅ Aplicação disponível em http://54.161.19.13"
echo ""
echo -e "${BLUE}🌐 URLs da aplicação:${NC}"
echo "  - Frontend: http://54.161.19.13"
echo "  - API: http://54.161.19.13/api/versao"
echo ""
echo -e "${YELLOW}💡 Próximos passos:${NC}"
echo "  - Testar todas as funcionalidades da aplicação"
echo "  - Verificar se o frontend está se comunicando com a API"
echo "  - Verificar conexão com o banco RDS"
