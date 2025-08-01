#!/bin/bash

# Script para atualizar IP no Dockerfile (SEM PORTA) e fazer deploy
# Autor: Amazon Q

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

OLD_URL="http://34.229.224.0:3001"
NEW_URL="http://54.161.19.13"
NEW_IP="54.161.19.13"

echo -e "${BLUE}🔧 ATUALIZANDO IP NO DOCKERFILE (SEM PORTA) E FAZENDO DEPLOY${NC}"
echo "=========================================================="

echo -e "\n${YELLOW}🔍 PASSO 1: Verificando Dockerfile atual...${NC}"

# Verificar se o Dockerfile existe
if [ ! -f "Dockerfile" ]; then
    echo -e "   ${RED}❌ Dockerfile não encontrado${NC}"
    exit 1
fi

# Mostrar linha atual com o IP
CURRENT_LINE=$(grep "VITE_API_URL" Dockerfile || echo "Linha não encontrada")
echo -e "   ${CYAN}Linha atual: $CURRENT_LINE${NC}"

# Verificar se contém a URL antiga
if grep -q "$OLD_URL" Dockerfile; then
    echo -e "   ${YELLOW}⚠️  URL antiga encontrada: $OLD_URL${NC}"
    NEEDS_UPDATE=true
elif grep -q "$NEW_URL" Dockerfile; then
    echo -e "   ${GREEN}✅ URL correta já está configurada: $NEW_URL${NC}"
    NEEDS_UPDATE=false
else
    echo -e "   ${YELLOW}⚠️  URL precisa ser atualizada${NC}"
    NEEDS_UPDATE=true
fi

echo -e "\n${YELLOW}🔧 PASSO 2: Fazendo backup e atualizando Dockerfile...${NC}"

# Fazer backup do Dockerfile
cp Dockerfile Dockerfile.backup
echo -e "   ${GREEN}✅ Backup criado: Dockerfile.backup${NC}"

if [ "$NEEDS_UPDATE" = true ]; then
    # Atualizar a URL no Dockerfile (removendo a porta)
    sed -i "s|VITE_API_URL=http://[0-9.]*:[0-9]*|VITE_API_URL=$NEW_URL|g" Dockerfile
    
    echo -e "   ${GREEN}✅ URL atualizada no Dockerfile${NC}"
    
    # Verificar se a alteração foi feita
    NEW_LINE=$(grep "VITE_API_URL" Dockerfile)
    echo -e "   ${CYAN}Nova linha: $NEW_LINE${NC}"
    
    # Confirmar que a URL foi alterada corretamente
    if grep -q "$NEW_URL" Dockerfile; then
        echo -e "   ${GREEN}✅ Alteração confirmada: $NEW_URL${NC}"
    else
        echo -e "   ${RED}❌ Erro na alteração da URL${NC}"
        exit 1
    fi
else
    echo -e "   ${CYAN}ℹ️  Dockerfile já está com a URL correta${NC}"
fi

echo -e "\n${YELLOW}📋 PASSO 3: Mostrando diferenças...${NC}"

# Mostrar diferenças se houver
if [ "$NEEDS_UPDATE" = true ]; then
    echo -e "   ${CYAN}Diferenças no Dockerfile:${NC}"
    echo -e "   ${RED}- RUN cd client && VITE_API_URL=$OLD_URL npm run build${NC}"
    echo -e "   ${GREEN}+ RUN cd client && VITE_API_URL=$NEW_URL npm run build${NC}"
else
    echo -e "   ${CYAN}Nenhuma alteração necessária${NC}"
fi

echo -e "\n${YELLOW}🧪 PASSO 4: Testando configuração...${NC}"

# Verificar se o novo IP está acessível (na porta 80, sem especificar porta)
echo -e "   ${CYAN}Testando conectividade com $NEW_IP (porta 80)...${NC}"

if curl -s --connect-timeout 5 http://$NEW_IP/api/versao >/dev/null 2>&1; then
    echo -e "   ${GREEN}✅ IP $NEW_IP está acessível na porta 80${NC}"
    API_VERSION=$(curl -s http://$NEW_IP/api/versao)
    echo -e "   ${CYAN}Versão da API: $API_VERSION${NC}"
else
    echo -e "   ${YELLOW}⚠️  IP $NEW_IP não está respondendo na porta 80${NC}"
    echo -e "   ${YELLOW}💡 Continuando com o deploy (pode estar temporariamente indisponível)${NC}"
fi

echo -e "\n${YELLOW}🚀 PASSO 5: Executando deploy...${NC}"

# Verificar se o script de deploy existe
if [ ! -f "deploy-fixed.sh" ]; then
    echo -e "   ${RED}❌ Script deploy-fixed.sh não encontrado${NC}"
    exit 1
fi

echo -e "   ${CYAN}Executando deploy com nova URL configurada (sem porta)...${NC}"

# Executar o deploy
if ./deploy-fixed.sh; then
    echo -e "   ${GREEN}✅ Deploy executado com sucesso!${NC}"
else
    echo -e "   ${RED}❌ Erro no deploy${NC}"
    
    # Restaurar backup em caso de erro
    echo -e "   ${YELLOW}🔄 Restaurando Dockerfile original...${NC}"
    cp Dockerfile.backup Dockerfile
    echo -e "   ${GREEN}✅ Dockerfile restaurado${NC}"
    
    exit 1
fi

echo -e "\n${GREEN}🎉 ATUALIZAÇÃO E DEPLOY CONCLUÍDOS!${NC}"
echo ""
echo -e "${CYAN}📋 Resumo das alterações:${NC}"
echo "  ✅ Dockerfile atualizado: $OLD_URL → $NEW_URL"
echo "  ✅ Porta removida da URL (agora usa porta 80 padrão)"
echo "  ✅ Backup salvo: Dockerfile.backup"
echo "  ✅ Build executado com nova URL"
echo "  ✅ Deploy realizado no ECS"
echo "  ✅ Service atualizado"
echo ""
echo -e "${BLUE}🌐 URLs da aplicação:${NC}"
echo "  - Frontend: $NEW_URL"
echo "  - API: $NEW_URL/api/versao"
echo ""
echo -e "${YELLOW}💡 Próximos passos:${NC}"
echo "  - Aguardar alguns minutos para o deploy estabilizar"
echo "  - Testar a aplicação no novo IP (sem porta)"
echo "  - Verificar se o frontend está se comunicando com a API"
echo ""
echo -e "${CYAN}📁 Arquivos:${NC}"
echo "  - Dockerfile (atualizado sem porta)"
echo "  - Dockerfile.backup (backup do original)"
