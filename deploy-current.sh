#!/bin/bash

# ============================================================================
# SCRIPT DE DEPLOY ATUALIZADO - PROJETO BIA
# Data: 02/08/2025
# Autor: Jose Marcelo Tse
# Descrição: Deploy automatizado do projeto BIA no ECS com configurações atuais
# ============================================================================

set -e

# Configurações atuais (baseadas no estado real da infraestrutura)
REGION="us-east-1"
CLUSTER_NAME="cluster-bia-alb"
SERVICE_NAME="service-bia-alb"
TASK_DEFINITION="task-def-bia-alb"
ECR_REPOSITORY="873976611862.dkr.ecr.us-east-1.amazonaws.com/bia"
APPLICATION_URL="http://bia-alb-690586468.us-east-1.elb.amazonaws.com"
LOG_GROUP="/ecs/task-def-bia-alb"

# Configurações do banco de dados
DB_HOST="bia.ccxceeiycgx6.us-east-1.rds.amazonaws.com"
DB_PORT="5432"
DB_USER="postgres"
DB_SECRET_ARN="arn:aws:secretsmanager:us-east-1:873976611862:secret:rds!db-351c97aa-df32-43ee-8182-b2872962dbb7-mHDOMB"

# IAM Role
EXECUTION_ROLE_ARN="arn:aws:iam::873976611862:role/ecsTaskExecutionRole"

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

# Função para verificar pré-requisitos
check_prerequisites() {
    print_info "Verificando pré-requisitos..."
    
    # Verificar se está no diretório correto
    if [ ! -f "package.json" ]; then
        print_error "Execute este script no diretório raiz do projeto BIA"
        exit 1
    fi
    
    # Verificar se Docker está rodando
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker não está rodando"
        exit 1
    fi
    
    # Verificar se AWS CLI está configurado
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS CLI não está configurado"
        exit 1
    fi
    
    # Verificar se há mudanças não commitadas
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Há mudanças não commitadas. Fazendo commit automático..."
        git add .
        git commit -m "Deploy: Atualizações automáticas $(date)"
    fi
    
    print_success "Pré-requisitos verificados"
}

# Função principal de deploy
deploy() {
    print_header "INICIANDO DEPLOY DO PROJETO BIA"
    
    # Verificar pré-requisitos
    check_prerequisites
    
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
    "executionRoleArn": "$EXECUTION_ROLE_ARN",
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
                    "hostPort": 0,
                    "protocol": "tcp",
                    "name": "porta-aleatoria"
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
                    "value": "$DB_HOST"
                },
                {
                    "name": "DB_PORT",
                    "value": "$DB_PORT"
                },
                {
                    "name": "DB_USER",
                    "value": "$DB_USER"
                }
            ],
            "secrets": [
                {
                    "name": "DB_PWD",
                    "valueFrom": "$DB_SECRET_ARN:password::"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "$LOG_GROUP",
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
    print_warning "Isso pode levar alguns minutos..."
    
    # Aguardar com timeout de 15 minutos
    timeout 900 aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION || print_warning "Timeout aguardando estabilização, mas continuando..."
    
    # 7. Verificar status
    print_info "Verificando status do serviço..."
    SERVICE_INFO=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION)
    
    SERVICE_STATUS=$(echo $SERVICE_INFO | jq -r '.services[0].deployments[0].rolloutState')
    RUNNING_COUNT=$(echo $SERVICE_INFO | jq -r '.services[0].runningCount')
    DESIRED_COUNT=$(echo $SERVICE_INFO | jq -r '.services[0].desiredCount')
    
    print_info "Status do deployment: $SERVICE_STATUS"
    print_info "Tasks rodando: $RUNNING_COUNT/$DESIRED_COUNT"
    
    if [ "$SERVICE_STATUS" = "COMPLETED" ]; then
        print_success "Deploy concluído com sucesso!"
    else
        print_warning "Deploy em andamento. Status: $SERVICE_STATUS"
    fi
    
    # 8. Verificar health do ALB
    print_info "Verificando health do Application Load Balancer..."
    sleep 30
    
    HEALTHY_TARGETS=$(aws elbv2 describe-target-health \
        --target-group-arn arn:aws:elasticloadbalancing:us-east-1:873976611862:targetgroup/tg-bia/2f1d581fe8fec016 \
        --region $REGION \
        --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' \
        --output text)
    
    print_info "Targets saudáveis no ALB: $HEALTHY_TARGETS"
    
    # 9. Teste de conectividade
    print_info "Testando conectividade da aplicação..."
    sleep 10
    
    for i in {1..5}; do
        if curl -f -s $APPLICATION_URL/api/versao > /dev/null; then
            print_success "Aplicação respondendo corretamente"
            VERSION=$(curl -s $APPLICATION_URL/api/versao)
            print_info "Versão da aplicação: $VERSION"
            break
        else
            print_warning "Tentativa $i/5: Aplicação ainda não está respondendo..."
            sleep 30
        fi
    done
    
    # 10. Salvar informações do deploy
    print_info "Salvando informações do deploy..."
    cat > deploy-info-$COMMIT_HASH.json << EOF
{
    "deploy_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "commit_hash": "$COMMIT_HASH",
    "task_definition_arn": "$TASK_DEF_ARN",
    "image": "$ECR_REPOSITORY:$COMMIT_HASH",
    "cluster": "$CLUSTER_NAME",
    "service": "$SERVICE_NAME",
    "application_url": "$APPLICATION_URL",
    "deployment_status": "$SERVICE_STATUS",
    "running_tasks": "$RUNNING_COUNT/$DESIRED_COUNT",
    "healthy_targets": "$HEALTHY_TARGETS"
}
EOF
    
    # Limpeza
    rm -f /tmp/task-definition-$COMMIT_HASH.json
    
    print_header "DEPLOY CONCLUÍDO"
    print_success "Commit deployado: $COMMIT_HASH"
    print_success "Task Definition: $TASK_DEF_ARN"
    print_success "Imagem: $ECR_REPOSITORY:$COMMIT_HASH"
    print_info "Acesse a aplicação em: $APPLICATION_URL"
    print_info "Informações salvas em: deploy-info-$COMMIT_HASH.json"
}

# Função para rollback
rollback() {
    print_header "INICIANDO ROLLBACK"
    
    if [ -z "$1" ]; then
        print_error "Uso: $0 rollback <task-definition-arn>"
        exit 1
    fi
    
    ROLLBACK_TASK_DEF="$1"
    
    print_info "Fazendo rollback para: $ROLLBACK_TASK_DEF"
    
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --task-definition $ROLLBACK_TASK_DEF \
        --region $REGION > /dev/null
    
    print_success "Rollback iniciado"
    
    print_info "Aguardando rollback ser concluído..."
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION
    
    print_success "Rollback concluído"
}

# Verificar argumentos
case "${1:-deploy}" in
    "deploy")
        deploy
        ;;
    "rollback")
        rollback "$2"
        ;;
    *)
        echo "Uso: $0 [deploy|rollback <task-definition-arn>]"
        exit 1
        ;;
esac

print_success "Script finalizado!"
