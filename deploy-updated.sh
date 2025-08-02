#!/bin/bash

# ============================================================================
# SCRIPT DE DEPLOY - PROJETO BIA
# Data: 01/08/2025
# Autor: Jose Marcelo Tse
# Descrição: Deploy automatizado do projeto BIA no ECS
# ============================================================================

set -e

# Configurações
REGION="us-east-1"
CLUSTER_NAME="cluster-bia"
SERVICE_NAME="service-bia"
TASK_DEFINITION="task-def-bia"
ECR_REPOSITORY="873976611862.dkr.ecr.us-east-1.amazonaws.com/bia"
APPLICATION_URL="http://54.227.222.64"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Função para obter commit hash
get_commit_hash() {
    git rev-parse --short HEAD
}

# Função principal de deploy
deploy() {
    print_header "INICIANDO DEPLOY DO PROJETO BIA"
    
    # Obter commit hash
    COMMIT_HASH=$(get_commit_hash)
    print_info "Commit Hash: $COMMIT_HASH"
    
    # 1. Login no ECR
    print_info "Fazendo login no ECR..."
    aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY
    print_success "Login no ECR realizado"
    
    # 2. Build da imagem
    print_info "Fazendo build da imagem Docker..."
    docker build -t bia:$COMMIT_HASH .
    docker tag bia:$COMMIT_HASH $ECR_REPOSITORY:$COMMIT_HASH
    docker tag bia:$COMMIT_HASH $ECR_REPOSITORY:latest
    print_success "Build da imagem concluído"
    
    # 3. Push para ECR
    print_info "Enviando imagem para ECR..."
    docker push $ECR_REPOSITORY:$COMMIT_HASH
    docker push $ECR_REPOSITORY:latest
    print_success "Imagem enviada para ECR"
    
    # 4. Criar nova task definition
    print_info "Criando nova task definition..."
    cat > /tmp/task-definition-$COMMIT_HASH.json << EOF
{
    "family": "$TASK_DEFINITION",
    "executionRoleArn": "arn:aws:iam::873976611862:role/ecsTaskExecutionRole",
    "networkMode": "bridge",
    "requiresCompatibilities": ["EC2"],
    "containerDefinitions": [
        {
            "name": "bia",
            "image": "$ECR_REPOSITORY:$COMMIT_HASH",
            "cpu": 1024,
            "memoryReservation": 400,
            "portMappings": [
                {
                    "containerPort": 8080,
                    "hostPort": 80,
                    "protocol": "tcp",
                    "name": "porta-80"
                }
            ],
            "essential": true,
            "environment": [
                {
                    "name": "COMMIT_HASH",
                    "value": "$COMMIT_HASH"
                },
                {
                    "name": "DB_HOST",
                    "value": "bia.ccxceeiycgx6.us-east-1.rds.amazonaws.com"
                },
                {
                    "name": "DB_PORT",
                    "value": "5432"
                },
                {
                    "name": "DB_USER",
                    "value": "postgres"
                }
            ],
            "secrets": [
                {
                    "name": "DB_PWD",
                    "valueFrom": "arn:aws:secretsmanager:us-east-1:873976611862:secret:rds!db-351c97aa-df32-43ee-8182-b2872962dbb7-mHDOMB:password::"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/task-def-bia",
                    "awslogs-create-group": "true",
                    "awslogs-region": "$REGION",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
}
EOF
    
    # Registrar task definition
    TASK_DEF_ARN=$(aws ecs register-task-definition \
        --cli-input-json file:///tmp/task-definition-$COMMIT_HASH.json \
        --region $REGION \
        --query 'taskDefinition.taskDefinitionArn' \
        --output text)
    
    print_success "Task definition criada: $TASK_DEF_ARN"
    
    # 5. Atualizar serviço
    print_info "Atualizando serviço ECS..."
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --task-definition $TASK_DEF_ARN \
        --region $REGION > /dev/null
    
    print_success "Serviço atualizado"
    
    # 6. Aguardar deployment
    print_info "Aguardando deployment ser concluído..."
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION
    
    # 7. Verificar status
    print_info "Verificando status do serviço..."
    SERVICE_STATUS=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --query 'services[0].deployments[0].rolloutState' \
        --output text)
    
    if [ "$SERVICE_STATUS" = "COMPLETED" ]; then
        print_success "Deploy concluído com sucesso!"
    else
        print_warning "Deploy em andamento. Status: $SERVICE_STATUS"
    fi
    
    # 8. Teste de conectividade
    print_info "Testando conectividade..."
    sleep 10
    
    if curl -f -s $APPLICATION_URL/api/versao > /dev/null; then
        print_success "Aplicação respondendo corretamente"
        VERSION=$(curl -s $APPLICATION_URL/api/versao)
        print_info "Versão: $VERSION"
    else
        print_warning "Aplicação ainda não está respondendo. Aguarde alguns minutos."
    fi
    
    # Limpeza
    rm -f /tmp/task-definition-$COMMIT_HASH.json
    
    print_header "DEPLOY CONCLUÍDO"
    print_success "Commit deployado: $COMMIT_HASH"
    print_success "Task Definition: $TASK_DEF_ARN"
    print_info "Acesse a aplicação em: $APPLICATION_URL"
}

# Verificar se está no diretório correto
if [ ! -f "package.json" ]; then
    print_error "Execute este script no diretório raiz do projeto BIA"
    exit 1
fi

# Executar deploy
deploy

print_success "Script de deploy finalizado!"
