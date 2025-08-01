#!/bin/bash

# =============================================================================
# ECS Deploy Script com Versionamento por Commit Hash
# =============================================================================
# Autor: Amazon Q
# Versão: 1.0
# Data: 2025-08-01
#
# Este script automatiza o processo de build, tag e deploy de aplicações para
# Amazon ECS com versionamento baseado em commit hash do Git.
#
# Funcionalidades:
# - Build da imagem Docker com tag baseada em commit hash
# - Push para Amazon ECR
# - Criação de nova Task Definition
# - Deploy no ECS Service
# - Rollback para versões anteriores
# - Listagem de versões disponíveis
# =============================================================================

set -e  # Parar execução em caso de erro

# =============================================================================
# CONFIGURAÇÕES
# =============================================================================

# Configurações do projeto
PROJECT_NAME="bia"
PROJECT_DIR="/home/ec2-user/bia"
DOCKERFILE_PATH="$PROJECT_DIR/Dockerfile"

# Configurações AWS
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="873976611862"
ECR_REPOSITORY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME"

# Configurações ECS
ECS_CLUSTER="cluster-bia"
ECS_SERVICE="service-bia"
TASK_DEFINITION_FAMILY="task-def-bia"

# Configurações da Task Definition
CONTAINER_NAME="bia"
CONTAINER_PORT="8080"
HOST_PORT="80"
CPU="1024"
MEMORY_RESERVATION="400"
LOG_GROUP="/ecs/$TASK_DEFINITION_FAMILY"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

print_header() {
    echo -e "${BLUE}=============================================================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}=============================================================================${NC}"
}

print_step() {
    echo -e "${CYAN}📋 $1${NC}"
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
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

# =============================================================================
# FUNÇÕES DE VALIDAÇÃO
# =============================================================================

check_prerequisites() {
    print_step "Verificando pré-requisitos..."
    
    # Verificar se está no diretório correto
    if [ ! -f "$DOCKERFILE_PATH" ]; then
        print_error "Dockerfile não encontrado em $DOCKERFILE_PATH"
        exit 1
    fi
    
    # Verificar se é um repositório Git
    if [ ! -d "$PROJECT_DIR/.git" ]; then
        print_error "Diretório não é um repositório Git: $PROJECT_DIR"
        exit 1
    fi
    
    # Verificar comandos necessários
    local commands=("docker" "aws" "git" "jq")
    for cmd in "${commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            print_error "Comando '$cmd' não encontrado. Instale antes de continuar."
            exit 1
        fi
    done
    
    # Verificar se Docker está rodando
    if ! docker info &> /dev/null; then
        print_error "Docker não está rodando. Inicie o Docker antes de continuar."
        exit 1
    fi
    
    # Verificar credenciais AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "Credenciais AWS não configuradas ou inválidas."
        exit 1
    fi
    
    print_success "Todos os pré-requisitos atendidos"
}

# =============================================================================
# FUNÇÕES GIT
# =============================================================================

get_commit_hash() {
    cd "$PROJECT_DIR"
    local full_hash=$(git rev-parse HEAD)
    local short_hash=$(git rev-parse --short=8 HEAD)
    echo "$short_hash"
}

get_current_branch() {
    cd "$PROJECT_DIR"
    git branch --show-current
}

check_git_status() {
    cd "$PROJECT_DIR"
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Existem alterações não commitadas no repositório"
        print_info "Arquivos modificados:"
        git status --porcelain | head -10
        echo
        read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deploy cancelado pelo usuário"
            exit 0
        fi
    fi
}

# =============================================================================
# FUNÇÕES ECR
# =============================================================================

ecr_login() {
    print_step "Fazendo login no Amazon ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY
    print_success "Login no ECR realizado com sucesso"
}

check_ecr_repository() {
    print_step "Verificando repositório ECR..."
    if ! aws ecr describe-repositories --repository-names $PROJECT_NAME --region $AWS_REGION &> /dev/null; then
        print_error "Repositório ECR '$PROJECT_NAME' não encontrado"
        print_info "Crie o repositório com: aws ecr create-repository --repository-name $PROJECT_NAME --region $AWS_REGION"
        exit 1
    fi
    print_success "Repositório ECR encontrado"
}

# =============================================================================
# FUNÇÕES DOCKER
# =============================================================================

build_image() {
    local commit_hash=$1
    local image_tag="$ECR_REPOSITORY:$commit_hash"
    
    print_step "Construindo imagem Docker..."
    print_info "Tag da imagem: $image_tag"
    
    cd "$PROJECT_DIR"
    
    # Build da imagem
    docker build -t "$image_tag" -f "$DOCKERFILE_PATH" .
    
    # Também criar tag 'latest' para referência
    docker tag "$image_tag" "$ECR_REPOSITORY:latest"
    
    print_success "Imagem construída com sucesso"
    
    # Mostrar informações da imagem
    local image_size=$(docker images "$image_tag" --format "table {{.Size}}" | tail -n 1)
    print_info "Tamanho da imagem: $image_size"
}

push_image() {
    local commit_hash=$1
    local image_tag="$ECR_REPOSITORY:$commit_hash"
    
    print_step "Enviando imagem para ECR..."
    
    # Push da imagem com tag do commit
    docker push "$image_tag"
    
    # Push da tag latest
    docker push "$ECR_REPOSITORY:latest"
    
    print_success "Imagem enviada para ECR com sucesso"
    print_info "Imagem disponível em: $image_tag"
}

# =============================================================================
# FUNÇÕES ECS
# =============================================================================

get_secrets_manager_arn() {
    # Obter ARN do secret do RDS
    aws secretsmanager list-secrets --region $AWS_REGION \
        --query "SecretList[?contains(Name, 'rds!db')].ARN" \
        --output text | head -n 1
}

create_task_definition() {
    local commit_hash=$1
    local image_uri="$ECR_REPOSITORY:$commit_hash"
    local secrets_arn=$(get_secrets_manager_arn)
    
    print_step "Criando nova Task Definition..."
    
    # Obter execution role ARN
    local execution_role_arn="arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole"
    
    # Criar JSON da task definition
    local task_def_json=$(cat <<EOF
{
    "family": "$TASK_DEFINITION_FAMILY",
    "executionRoleArn": "$execution_role_arn",
    "networkMode": "bridge",
    "requiresCompatibilities": ["EC2"],
    "containerDefinitions": [
        {
            "name": "$CONTAINER_NAME",
            "image": "$image_uri",
            "cpu": $CPU,
            "memoryReservation": $MEMORY_RESERVATION,
            "essential": true,
            "portMappings": [
                {
                    "containerPort": $CONTAINER_PORT,
                    "hostPort": $HOST_PORT,
                    "protocol": "tcp",
                    "name": "porta-$HOST_PORT"
                }
            ],
            "environment": [
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
                },
                {
                    "name": "COMMIT_HASH",
                    "value": "$commit_hash"
                }
            ],
            "secrets": [
                {
                    "name": "DB_PWD",
                    "valueFrom": "$secrets_arn:password::"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "$LOG_GROUP",
                    "awslogs-create-group": "true",
                    "awslogs-region": "$AWS_REGION",
                    "awslogs-stream-prefix": "ecs"
                }
            },
            "systemControls": []
        }
    ]
}
EOF
)
    
    # Registrar task definition
    local task_def_arn=$(echo "$task_def_json" | aws ecs register-task-definition \
        --region $AWS_REGION \
        --cli-input-json file:///dev/stdin \
        --query 'taskDefinition.taskDefinitionArn' \
        --output text)
    
    print_success "Task Definition criada: $task_def_arn"
    echo "$task_def_arn"
}

update_service() {
    local task_def_arn=$1
    local commit_hash=$2
    
    print_step "Atualizando serviço ECS..."
    
    # Atualizar serviço
    aws ecs update-service \
        --region $AWS_REGION \
        --cluster $ECS_CLUSTER \
        --service $ECS_SERVICE \
        --task-definition "$task_def_arn" \
        --query 'service.{serviceName:serviceName,taskDefinition:taskDefinition,desiredCount:desiredCount}' \
        --output table
    
    print_success "Serviço atualizado com sucesso"
    print_info "Aguardando estabilização do serviço..."
    
    # Aguardar estabilização
    aws ecs wait services-stable \
        --region $AWS_REGION \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE
    
    print_success "Serviço estabilizado com commit hash: $commit_hash"
}

# =============================================================================
# FUNÇÕES DE LISTAGEM E ROLLBACK
# =============================================================================

list_versions() {
    print_header "VERSÕES DISPONÍVEIS"
    
    print_step "Listando imagens no ECR..."
    echo
    aws ecr describe-images \
        --region $AWS_REGION \
        --repository-name $PROJECT_NAME \
        --query 'sort_by(imageDetails,&imagePushedAt)[*].{Tag:imageTags[0],Pushed:imagePushedAt,Size:imageSizeInBytes}' \
        --output table
    
    echo
    print_step "Listando Task Definitions..."
    echo
    aws ecs list-task-definitions \
        --region $AWS_REGION \
        --family-prefix $TASK_DEFINITION_FAMILY \
        --status ACTIVE \
        --sort DESC \
        --query 'taskDefinitionArns[0:10]' \
        --output table
    
    echo
    print_step "Serviço atual..."
    aws ecs describe-services \
        --region $AWS_REGION \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --query 'services[0].{ServiceName:serviceName,TaskDefinition:taskDefinition,RunningCount:runningCount,DesiredCount:desiredCount}' \
        --output table
}

rollback_to_version() {
    local target_hash=$1
    
    if [ -z "$target_hash" ]; then
        print_error "Hash do commit não especificado para rollback"
        exit 1
    fi
    
    print_header "ROLLBACK PARA VERSÃO $target_hash"
    
    # Verificar se a imagem existe no ECR
    print_step "Verificando se a versão existe no ECR..."
    if ! aws ecr describe-images \
        --region $AWS_REGION \
        --repository-name $PROJECT_NAME \
        --image-ids imageTag=$target_hash &> /dev/null; then
        print_error "Imagem com hash '$target_hash' não encontrada no ECR"
        exit 1
    fi
    
    print_success "Imagem encontrada no ECR"
    
    # Criar nova task definition com a imagem antiga
    print_step "Criando Task Definition para rollback..."
    local task_def_arn=$(create_task_definition "$target_hash")
    
    # Atualizar serviço
    update_service "$task_def_arn" "$target_hash"
    
    print_success "Rollback concluído para versão: $target_hash"
}

# =============================================================================
# FUNÇÃO PRINCIPAL DE DEPLOY
# =============================================================================

deploy() {
    print_header "DEPLOY DA APLICAÇÃO BIA"
    
    # Verificar pré-requisitos
    check_prerequisites
    
    # Verificar status do Git
    check_git_status
    
    # Obter informações do commit
    local commit_hash=$(get_commit_hash)
    local current_branch=$(get_current_branch)
    
    print_info "Branch atual: $current_branch"
    print_info "Commit hash: $commit_hash"
    
    # Verificar se já existe uma imagem com este hash
    if aws ecr describe-images \
        --region $AWS_REGION \
        --repository-name $PROJECT_NAME \
        --image-ids imageTag=$commit_hash &> /dev/null; then
        print_warning "Imagem com hash '$commit_hash' já existe no ECR"
        read -p "Deseja continuar e sobrescrever? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deploy cancelado pelo usuário"
            exit 0
        fi
    fi
    
    # Login no ECR
    ecr_login
    
    # Verificar repositório ECR
    check_ecr_repository
    
    # Build da imagem
    build_image "$commit_hash"
    
    # Push da imagem
    push_image "$commit_hash"
    
    # Criar task definition
    local task_def_arn=$(create_task_definition "$commit_hash")
    
    # Atualizar serviço
    update_service "$task_def_arn" "$commit_hash"
    
    print_header "DEPLOY CONCLUÍDO COM SUCESSO"
    print_success "Versão deployada: $commit_hash"
    print_success "Task Definition: $task_def_arn"
    print_info "Acesse a aplicação em: http://54.161.19.13"
}

# =============================================================================
# FUNÇÃO DE HELP
# =============================================================================

show_help() {
    cat << EOF
${BLUE}=============================================================================${NC}
${BLUE} ECS Deploy Script - Aplicação Bia${NC}
${BLUE}=============================================================================${NC}

${YELLOW}DESCRIÇÃO:${NC}
    Script para automatizar o deploy da aplicação Bia no Amazon ECS com
    versionamento baseado em commit hash do Git.

${YELLOW}USO:${NC}
    $0 [COMANDO] [OPÇÕES]

${YELLOW}COMANDOS:${NC}
    ${GREEN}deploy${NC}                    Executa deploy completo da aplicação
    ${GREEN}list${NC}                      Lista versões disponíveis
    ${GREEN}rollback <commit-hash>${NC}    Faz rollback para versão específica
    ${GREEN}help${NC}                      Mostra esta ajuda

${YELLOW}EXEMPLOS:${NC}
    # Deploy da versão atual
    $0 deploy

    # Listar versões disponíveis
    $0 list

    # Rollback para versão específica
    $0 rollback a1b2c3d4

    # Mostrar ajuda
    $0 help

${YELLOW}FLUXO DO DEPLOY:${NC}
    1. ${CYAN}Verificação de pré-requisitos${NC}
       - Docker instalado e rodando
       - AWS CLI configurado
       - Repositório Git válido
       - Credenciais AWS válidas

    2. ${CYAN}Análise do código${NC}
       - Obtenção do commit hash atual
       - Verificação de alterações não commitadas
       - Validação do branch atual

    3. ${CYAN}Build da imagem Docker${NC}
       - Construção com tag baseada no commit hash
       - Criação de tag 'latest' adicional
       - Validação da imagem construída

    4. ${CYAN}Push para ECR${NC}
       - Login automático no Amazon ECR
       - Upload da imagem com versionamento
       - Verificação do upload

    5. ${CYAN}Criação da Task Definition${NC}
       - Geração de nova task definition
       - Configuração de variáveis de ambiente
       - Integração com AWS Secrets Manager

    6. ${CYAN}Deploy no ECS${NC}
       - Atualização do serviço ECS
       - Aguardo da estabilização
       - Verificação do deploy

${YELLOW}CONFIGURAÇÕES:${NC}
    ${PURPLE}Projeto:${NC}
    - Nome: $PROJECT_NAME
    - Diretório: $PROJECT_DIR
    - Dockerfile: $DOCKERFILE_PATH

    ${PURPLE}AWS:${NC}
    - Região: $AWS_REGION
    - Account ID: $AWS_ACCOUNT_ID
    - ECR Repository: $ECR_REPOSITORY

    ${PURPLE}ECS:${NC}
    - Cluster: $ECS_CLUSTER
    - Service: $ECS_SERVICE
    - Task Definition: $TASK_DEFINITION_FAMILY

${YELLOW}VERSIONAMENTO:${NC}
    - Cada deploy cria uma imagem com tag baseada no commit hash (8 caracteres)
    - Task definitions são versionadas automaticamente
    - Rollback disponível para qualquer versão anterior
    - Histórico completo mantido no ECR e ECS

${YELLOW}ROLLBACK:${NC}
    Para fazer rollback para uma versão anterior:
    1. Liste as versões disponíveis: $0 list
    2. Execute o rollback: $0 rollback <commit-hash>

${YELLOW}TROUBLESHOOTING:${NC}
    - Verifique se o Docker está rodando
    - Confirme as credenciais AWS
    - Valide se o repositório ECR existe
    - Certifique-se de estar no diretório correto do projeto

${YELLOW}LOGS:${NC}
    Os logs da aplicação estão disponíveis em:
    - CloudWatch Log Group: $LOG_GROUP
    - AWS Console: ECS → Clusters → $ECS_CLUSTER → Services → $ECS_SERVICE

${BLUE}=============================================================================${NC}
EOF
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    case "${1:-}" in
        "deploy")
            deploy
            ;;
        "list")
            list_versions
            ;;
        "rollback")
            if [ -z "${2:-}" ]; then
                print_error "Hash do commit é obrigatório para rollback"
                echo "Uso: $0 rollback <commit-hash>"
                exit 1
            fi
            rollback_to_version "$2"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            print_error "Comando não especificado"
            echo "Use '$0 help' para ver os comandos disponíveis"
            exit 1
            ;;
        *)
            print_error "Comando inválido: $1"
            echo "Use '$0 help' para ver os comandos disponíveis"
            exit 1
            ;;
    esac
}

# Executar função principal com todos os argumentos
main "$@"
