#!/bin/bash

# Script para corrigir configurações de deployment do service-bia
# Min running tasks %: 0
# Max running tasks %: 100
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

echo -e "${BLUE}🔧 CORRIGINDO CONFIGURAÇÕES DE DEPLOYMENT DO SERVICE${NC}"
echo "=================================================="

echo -e "\n${YELLOW}🔍 PASSO 1: Verificando configurações atuais...${NC}"

# Verificar configurações atuais do service
CURRENT_CONFIG=$(aws --profile $PROFILE ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].deploymentConfiguration' \
    --output json)

echo -e "   ${CYAN}Configurações atuais de deployment:${NC}"
echo "$CURRENT_CONFIG" | jq .

# Extrair valores atuais
CURRENT_MIN=$(echo "$CURRENT_CONFIG" | jq -r '.minimumHealthyPercent')
CURRENT_MAX=$(echo "$CURRENT_CONFIG" | jq -r '.maximumPercent')

echo -e "\n   ${CYAN}Valores atuais:${NC}"
echo "   - Min running tasks %: $CURRENT_MIN"
echo "   - Max running tasks %: $CURRENT_MAX"

echo -e "\n${YELLOW}🔧 PASSO 2: Aplicando correções necessárias...${NC}"

echo -e "   ${CYAN}Valores que serão aplicados:${NC}"
echo "   - Min running tasks %: 0 (permite parar todas as tasks)"
echo "   - Max running tasks %: 100 (permite apenas 1 task por vez)"

# Atualizar configurações do service
echo -e "\n   ${CYAN}Atualizando configurações do service...${NC}"

aws --profile $PROFILE ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --deployment-configuration '{
        "minimumHealthyPercent": 0,
        "maximumPercent": 100,
        "deploymentCircuitBreaker": {
            "enable": false,
            "rollback": false
        }
    }'

echo -e "   ${GREEN}✅ Configurações atualizadas${NC}"

echo -e "\n${YELLOW}🔍 PASSO 3: Verificando configurações aplicadas...${NC}"

# Verificar se as configurações foram aplicadas
sleep 5

NEW_CONFIG=$(aws --profile $PROFILE ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].deploymentConfiguration' \
    --output json)

echo -e "   ${CYAN}Novas configurações de deployment:${NC}"
echo "$NEW_CONFIG" | jq .

# Extrair novos valores
NEW_MIN=$(echo "$NEW_CONFIG" | jq -r '.minimumHealthyPercent')
NEW_MAX=$(echo "$NEW_CONFIG" | jq -r '.maximumPercent')

echo -e "\n   ${CYAN}Valores aplicados:${NC}"
echo "   - Min running tasks %: $NEW_MIN"
echo "   - Max running tasks %: $NEW_MAX"

# Verificar se as configurações estão corretas
if [ "$NEW_MIN" = "0" ] && [ "$NEW_MAX" = "100" ]; then
    echo -e "   ${GREEN}✅ Configurações aplicadas corretamente${NC}"
else
    echo -e "   ${RED}❌ Erro: Configurações não foram aplicadas corretamente${NC}"
    exit 1
fi

echo -e "\n${YELLOW}📊 PASSO 4: Verificando status do service...${NC}"

# Verificar status geral do service
aws --profile $PROFILE ecs describe-services \
    --cluster $CLUSTER_NAME \
    --services $SERVICE_NAME \
    --query 'services[0].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount,TaskDefinition:taskDefinition}' \
    --output table

echo -e "\n${GREEN}🎉 CONFIGURAÇÕES DE DEPLOYMENT CORRIGIDAS!${NC}"
echo ""
echo -e "${CYAN}📋 Resumo das alterações:${NC}"
echo "  ✅ Min running tasks %: $CURRENT_MIN → 0"
echo "  ✅ Max running tasks %: $CURRENT_MAX → 100"
echo "  ✅ Deployment circuit breaker: Desabilitado"
echo ""
echo -e "${BLUE}💡 Benefícios das novas configurações:${NC}"
echo "  - Min 0%: Permite parar todas as tasks durante deployment"
echo "  - Max 100%: Evita criar tasks extras (resolve conflito de porta)"
echo "  - Permite rolling deployment sem conflitos de recursos"
echo ""
echo -e "${YELLOW}🚀 Próximo passo:${NC}"
echo "  Agora você pode executar o deploy sem conflito de porta:"
echo "  ./fix-port-conflict-deploy.sh"
echo ""
echo -e "${CYAN}📋 O que isso resolve:${NC}"
echo "  - Conflitos de porta durante deployment"
echo "  - Problemas de recursos insuficientes"
echo "  - Permite deployment em container instance único"
