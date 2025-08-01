#!/bin/bash

# Deploy script corrigido para o projeto Bia
# Cluster: cluster-bia
# Service: service-bia
# Profile: nxt

set -e

echo "🚀 Iniciando deploy da aplicação Bia..."

# Executar build
echo "📦 Executando build da aplicação..."
./build.sh

# Verificar se o build foi bem-sucedido
if [ $? -eq 0 ]; then
    echo "✅ Build executado com sucesso!"
else
    echo "❌ Erro no build. Abortando deploy."
    exit 1
fi

# Fazer deploy no ECS
echo "🔄 Fazendo deploy no ECS..."
aws --profile nxt ecs update-service \
    --cluster cluster-bia \
    --service service-bia \
    --force-new-deployment

# Verificar se o comando foi bem-sucedido
if [ $? -eq 0 ]; then
    echo "✅ Deploy iniciado com sucesso!"
    echo "⏳ Aguardando service estabilizar..."
    
    # Aguardar service estabilizar
    aws --profile nxt ecs wait services-stable \
        --cluster cluster-bia \
        --services service-bia
    
    echo "🎉 Deploy concluído com sucesso!"
    
    # Mostrar status final
    echo "📊 Status final do service:"
    aws --profile nxt ecs describe-services \
        --cluster cluster-bia \
        --services service-bia \
        --query 'services[0].{Name:serviceName,Status:status,Running:runningCount,Desired:desiredCount,TaskDefinition:taskDefinition}' \
        --output table
        
else
    echo "❌ Erro no deploy."
    exit 1
fi
