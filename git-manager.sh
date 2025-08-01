#!/bin/bash

# =============================================================================
# Git Manager Script - Gerenciamento Interativo do Git
# =============================================================================
# Autor: Amazon Q
# Versão: 1.0
# Data: 2025-08-01
#
# Este script automatiza o processo de git add, commit e push de forma
# interativa, permitindo ao usuário revisar e controlar cada etapa.
#
# Funcionalidades:
# - Verificação do status do repositório
# - Seleção interativa de branch
# - Adição seletiva de arquivos
# - Commit com mensagem personalizada
# - Push automático para o repositório remoto
# =============================================================================

set -e  # Parar execução em caso de erro

# =============================================================================
# CONFIGURAÇÕES
# =============================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
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

print_question() {
    echo -e "${WHITE}❓ $1${NC}"
}

# =============================================================================
# FUNÇÕES DE VALIDAÇÃO
# =============================================================================

check_git_repository() {
    if [ ! -d ".git" ]; then
        print_error "Este diretório não é um repositório Git!"
        print_info "Execute 'git init' para inicializar um repositório ou navegue para um diretório com Git."
        exit 1
    fi
    print_success "Repositório Git encontrado"
}

check_git_config() {
    local user_name=$(git config user.name 2>/dev/null || echo "")
    local user_email=$(git config user.email 2>/dev/null || echo "")
    
    if [ -z "$user_name" ] || [ -z "$user_email" ]; then
        print_warning "Configuração do Git incompleta"
        print_info "Nome: ${user_name:-'Não configurado'}"
        print_info "Email: ${user_email:-'Não configurado'}"
        echo
        read -p "Deseja configurar agora? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            configure_git
        else
            print_warning "Continuando sem configurar. Commits podem falhar."
        fi
    else
        print_success "Configuração do Git OK"
        print_info "Nome: $user_name"
        print_info "Email: $user_email"
    fi
}

configure_git() {
    echo
    print_step "Configurando Git..."
    
    read -p "Digite seu nome: " git_name
    read -p "Digite seu email: " git_email
    
    git config user.name "$git_name"
    git config user.email "$git_email"
    
    print_success "Git configurado com sucesso!"
    print_info "Nome: $git_name"
    print_info "Email: $git_email"
}

# =============================================================================
# FUNÇÕES DE STATUS E BRANCH
# =============================================================================

show_git_status() {
    print_step "Status atual do repositório:"
    echo
    
    # Mostrar branch atual
    local current_branch=$(git branch --show-current)
    print_info "Branch atual: ${current_branch:-'(detached HEAD)'}"
    
    # Mostrar status dos arquivos
    local status_output=$(git status --porcelain)
    
    if [ -z "$status_output" ]; then
        print_success "Working directory limpo - nenhuma alteração pendente"
        return 0
    fi
    
    echo
    print_info "Arquivos modificados:"
    
    # Contar tipos de alterações
    local modified_count=$(echo "$status_output" | grep "^ M" | wc -l)
    local added_count=$(echo "$status_output" | grep "^A " | wc -l)
    local deleted_count=$(echo "$status_output" | grep "^ D" | wc -l)
    local untracked_count=$(echo "$status_output" | grep "^??" | wc -l)
    local staged_count=$(echo "$status_output" | grep "^[MADRC]" | wc -l)
    
    # Mostrar resumo
    echo -e "${YELLOW}📊 Resumo das alterações:${NC}"
    [ $staged_count -gt 0 ] && echo -e "   ${GREEN}Staged: $staged_count arquivos${NC}"
    [ $modified_count -gt 0 ] && echo -e "   ${YELLOW}Modificados: $modified_count arquivos${NC}"
    [ $added_count -gt 0 ] && echo -e "   ${BLUE}Adicionados: $added_count arquivos${NC}"
    [ $deleted_count -gt 0 ] && echo -e "   ${RED}Deletados: $deleted_count arquivos${NC}"
    [ $untracked_count -gt 0 ] && echo -e "   ${PURPLE}Não rastreados: $untracked_count arquivos${NC}"
    
    echo
    print_info "Detalhes dos arquivos:"
    
    # Mostrar arquivos detalhadamente
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local status_code="${line:0:2}"
            local file_name="${line:3}"
            
            case "$status_code" in
                "M ") echo -e "   ${YELLOW}📝 Modificado (staged):${NC} $file_name" ;;
                " M") echo -e "   ${YELLOW}📝 Modificado:${NC} $file_name" ;;
                "A ") echo -e "   ${GREEN}➕ Adicionado (staged):${NC} $file_name" ;;
                " D") echo -e "   ${RED}🗑️  Deletado:${NC} $file_name" ;;
                "D ") echo -e "   ${RED}🗑️  Deletado (staged):${NC} $file_name" ;;
                "??") echo -e "   ${PURPLE}❓ Não rastreado:${NC} $file_name" ;;
                "R ") echo -e "   ${BLUE}🔄 Renomeado (staged):${NC} $file_name" ;;
                "C ") echo -e "   ${BLUE}📋 Copiado (staged):${NC} $file_name" ;;
                *) echo -e "   ${WHITE}❔ $status_code:${NC} $file_name" ;;
            esac
        fi
    done <<< "$status_output"
    
    return 1  # Indica que há alterações
}

list_branches() {
    print_step "Branches disponíveis:"
    echo
    
    local current_branch=$(git branch --show-current)
    
    # Listar branches locais
    print_info "Branches locais:"
    git branch --format="%(refname:short)" | while read branch; do
        if [ "$branch" = "$current_branch" ]; then
            echo -e "   ${GREEN}* $branch${NC} (atual)"
        else
            echo -e "   ${WHITE}  $branch${NC}"
        fi
    done
    
    echo
    
    # Listar branches remotos se existirem
    local remote_branches=$(git branch -r 2>/dev/null | grep -v "HEAD" | wc -l)
    if [ $remote_branches -gt 0 ]; then
        print_info "Branches remotos:"
        git branch -r --format="%(refname:short)" | grep -v "HEAD" | while read branch; do
            echo -e "   ${CYAN}  $branch${NC}"
        done
        echo
    fi
}

select_branch() {
    local current_branch=$(git branch --show-current)
    
    print_question "Branch atual: $current_branch"
    echo
    read -p "Deseja trocar de branch? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo
        list_branches
        echo
        read -p "Digite o nome da branch (ou ENTER para manter atual): " target_branch
        
        if [ -n "$target_branch" ] && [ "$target_branch" != "$current_branch" ]; then
            # Verificar se a branch existe
            if git show-ref --verify --quiet refs/heads/$target_branch; then
                print_step "Trocando para branch: $target_branch"
                git checkout $target_branch
                print_success "Branch alterada para: $target_branch"
            elif git show-ref --verify --quiet refs/remotes/origin/$target_branch; then
                print_step "Criando branch local a partir da remota: $target_branch"
                git checkout -b $target_branch origin/$target_branch
                print_success "Branch criada e alterada para: $target_branch"
            else
                print_warning "Branch '$target_branch' não encontrada"
                read -p "Deseja criar uma nova branch? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    git checkout -b $target_branch
                    print_success "Nova branch criada: $target_branch"
                else
                    print_info "Mantendo branch atual: $current_branch"
                fi
            fi
        else
            print_info "Mantendo branch atual: $current_branch"
        fi
    else
        print_info "Mantendo branch atual: $current_branch"
    fi
}

# =============================================================================
# FUNÇÕES DE ADIÇÃO DE ARQUIVOS
# =============================================================================

select_files_to_add() {
    local status_output=$(git status --porcelain)
    
    if [ -z "$status_output" ]; then
        print_info "Nenhum arquivo para adicionar"
        return 0
    fi
    
    print_step "Seleção de arquivos para adicionar:"
    echo
    
    # Opções de adição
    echo -e "${WHITE}Opções disponíveis:${NC}"
    echo -e "   ${GREEN}1)${NC} Adicionar todos os arquivos (git add .)"
    echo -e "   ${GREEN}2)${NC} Adicionar arquivos seletivamente"
    echo -e "   ${GREEN}3)${NC} Adicionar apenas arquivos modificados"
    echo -e "   ${GREEN}4)${NC} Adicionar apenas arquivos novos"
    echo -e "   ${GREEN}5)${NC} Pular adição (usar arquivos já staged)"
    echo
    
    read -p "Escolha uma opção (1-5): " choice
    
    case $choice in
        1)
            print_step "Adicionando todos os arquivos..."
            git add .
            print_success "Todos os arquivos adicionados"
            ;;
        2)
            add_files_selectively
            ;;
        3)
            print_step "Adicionando apenas arquivos modificados..."
            git add -u
            print_success "Arquivos modificados adicionados"
            ;;
        4)
            print_step "Adicionando apenas arquivos novos..."
            git status --porcelain | grep "^??" | cut -c4- | while read file; do
                git add "$file"
                echo -e "   ${GREEN}✅ Adicionado:${NC} $file"
            done
            print_success "Arquivos novos adicionados"
            ;;
        5)
            print_info "Pulando adição - usando arquivos já staged"
            ;;
        *)
            print_warning "Opção inválida. Adicionando todos os arquivos..."
            git add .
            print_success "Todos os arquivos adicionados"
            ;;
    esac
}

add_files_selectively() {
    print_step "Adição seletiva de arquivos:"
    echo
    
    local files_to_process=()
    
    # Coletar arquivos não staged
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local status_code="${line:0:2}"
            local file_name="${line:3}"
            
            # Apenas arquivos não staged
            if [[ "$status_code" =~ ^.[MD?]$ ]]; then
                files_to_process+=("$file_name")
            fi
        fi
    done <<< "$(git status --porcelain)"
    
    if [ ${#files_to_process[@]} -eq 0 ]; then
        print_info "Nenhum arquivo disponível para adição seletiva"
        return
    fi
    
    print_info "Arquivos disponíveis para adição:"
    for i in "${!files_to_process[@]}"; do
        echo -e "   ${WHITE}$((i+1)))${NC} ${files_to_process[i]}"
    done
    
    echo
    echo -e "${WHITE}Opções:${NC}"
    echo -e "   ${GREEN}a)${NC} Adicionar todos listados"
    echo -e "   ${GREEN}n)${NC} Números separados por espaço (ex: 1 3 5)"
    echo -e "   ${GREEN}q)${NC} Cancelar"
    echo
    
    read -p "Sua escolha: " selection
    
    case $selection in
        a|A)
            for file in "${files_to_process[@]}"; do
                git add "$file"
                echo -e "   ${GREEN}✅ Adicionado:${NC} $file"
            done
            print_success "Todos os arquivos listados foram adicionados"
            ;;
        q|Q)
            print_info "Adição cancelada"
            ;;
        *)
            # Processar números
            for num in $selection; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#files_to_process[@]} ]; then
                    local file="${files_to_process[$((num-1))]}"
                    git add "$file"
                    echo -e "   ${GREEN}✅ Adicionado:${NC} $file"
                else
                    print_warning "Número inválido ignorado: $num"
                fi
            done
            print_success "Arquivos selecionados adicionados"
            ;;
    esac
}

# =============================================================================
# FUNÇÕES DE COMMIT E PUSH
# =============================================================================

show_staged_files() {
    local staged_files=$(git diff --cached --name-only)
    
    if [ -z "$staged_files" ]; then
        print_warning "Nenhum arquivo staged para commit"
        return 1
    fi
    
    print_step "Arquivos staged para commit:"
    echo
    
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            local status=$(git diff --cached --name-status | grep "^[MADRC].*$file" | cut -f1)
            case "$status" in
                M) echo -e "   ${YELLOW}📝 Modificado:${NC} $file" ;;
                A) echo -e "   ${GREEN}➕ Adicionado:${NC} $file" ;;
                D) echo -e "   ${RED}🗑️  Deletado:${NC} $file" ;;
                R*) echo -e "   ${BLUE}🔄 Renomeado:${NC} $file" ;;
                C*) echo -e "   ${BLUE}📋 Copiado:${NC} $file" ;;
                *) echo -e "   ${WHITE}❔ $status:${NC} $file" ;;
            esac
        fi
    done <<< "$staged_files"
    
    return 0
}

create_commit() {
    if ! show_staged_files; then
        print_error "Não é possível fazer commit sem arquivos staged"
        return 1
    fi
    
    echo
    print_step "Criação do commit:"
    echo
    
    # Sugestões de mensagem
    print_info "Sugestões de formato de mensagem:"
    echo -e "   ${GREEN}feat:${NC} nova funcionalidade"
    echo -e "   ${GREEN}fix:${NC} correção de bug"
    echo -e "   ${GREEN}docs:${NC} documentação"
    echo -e "   ${GREEN}style:${NC} formatação, espaços"
    echo -e "   ${GREEN}refactor:${NC} refatoração de código"
    echo -e "   ${GREEN}test:${NC} testes"
    echo -e "   ${GREEN}chore:${NC} tarefas de manutenção"
    echo
    
    # Obter mensagem do commit
    local commit_message=""
    while [ -z "$commit_message" ]; do
        read -p "Digite a mensagem do commit: " commit_message
        if [ -z "$commit_message" ]; then
            print_warning "Mensagem não pode estar vazia!"
        fi
    done
    
    # Confirmar commit
    echo
    print_question "Mensagem do commit: \"$commit_message\""
    read -p "Confirma o commit? (Y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Commit cancelado"
        return 1
    fi
    
    # Executar commit
    print_step "Executando commit..."
    git commit -m "$commit_message"
    
    local commit_hash=$(git rev-parse --short HEAD)
    print_success "Commit criado com sucesso!"
    print_info "Hash: $commit_hash"
    print_info "Mensagem: $commit_message"
    
    return 0
}

push_to_remote() {
    local current_branch=$(git branch --show-current)
    
    # Verificar se existe remote
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -z "$remote_url" ]; then
        print_warning "Nenhum remote configurado"
        print_info "Configure um remote com: git remote add origin <URL>"
        return 1
    fi
    
    print_step "Push para repositório remoto:"
    print_info "Remote: $remote_url"
    print_info "Branch: $current_branch"
    echo
    
    read -p "Deseja fazer push? (Y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Push cancelado"
        return 0
    fi
    
    print_step "Executando push..."
    
    # Verificar se a branch existe no remote
    if git ls-remote --heads origin $current_branch | grep -q $current_branch; then
        # Branch existe, fazer push normal
        git push origin $current_branch
    else
        # Branch não existe, fazer push com --set-upstream
        print_info "Branch não existe no remote. Criando..."
        git push --set-upstream origin $current_branch
    fi
    
    print_success "Push realizado com sucesso!"
    print_info "Branch '$current_branch' atualizada no remote"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    print_header "GIT MANAGER - Gerenciamento Interativo do Git"
    
    # Verificações iniciais
    check_git_repository
    check_git_config
    
    echo
    
    # Mostrar status atual
    if show_git_status; then
        print_info "Repositório está limpo. Nada para fazer."
        exit 0
    fi
    
    echo
    
    # Seleção de branch
    select_branch
    
    echo
    
    # Seleção de arquivos para adicionar
    select_files_to_add
    
    echo
    
    # Criar commit
    if create_commit; then
        echo
        # Push para remote
        push_to_remote
    fi
    
    echo
    print_header "PROCESSO CONCLUÍDO"
    
    # Status final
    print_step "Status final do repositório:"
    git status --short
    
    local current_branch=$(git branch --show-current)
    local last_commit=$(git log -1 --oneline)
    
    print_success "Branch atual: $current_branch"
    print_success "Último commit: $last_commit"
    
    print_info "Use 'git log --oneline -5' para ver os últimos commits"
}

# =============================================================================
# FUNÇÃO DE HELP
# =============================================================================

show_help() {
    cat << EOF
${BLUE}=============================================================================${NC}
${BLUE} Git Manager - Gerenciamento Interativo do Git${NC}
${BLUE}=============================================================================${NC}

${YELLOW}DESCRIÇÃO:${NC}
    Script interativo para gerenciar operações Git de forma guiada e segura.

${YELLOW}USO:${NC}
    $0 [OPÇÃO]

${YELLOW}OPÇÕES:${NC}
    ${GREEN}(sem parâmetros)${NC}    Executa o processo interativo completo
    ${GREEN}help, -h, --help${NC}    Mostra esta ajuda

${YELLOW}FUNCIONALIDADES:${NC}
    ✅ Verificação automática do status do repositório
    ✅ Seleção interativa de branch
    ✅ Adição seletiva ou completa de arquivos
    ✅ Commit com mensagem personalizada
    ✅ Push automático para repositório remoto
    ✅ Validações de segurança em cada etapa

${YELLOW}FLUXO DO PROCESSO:${NC}
    1. ${CYAN}Verificação inicial${NC}
       - Valida se é um repositório Git
       - Verifica configuração do usuário
       - Mostra status atual dos arquivos

    2. ${CYAN}Seleção de branch${NC}
       - Lista branches disponíveis
       - Permite trocar ou criar nova branch
       - Suporte a branches remotas

    3. ${CYAN}Adição de arquivos${NC}
       - Adicionar todos os arquivos
       - Seleção interativa de arquivos
       - Apenas modificados ou apenas novos
       - Usar arquivos já staged

    4. ${CYAN}Criação do commit${NC}
       - Mostra arquivos que serão commitados
       - Sugestões de formato de mensagem
       - Confirmação antes de executar

    5. ${CYAN}Push para remote${NC}
       - Verifica configuração do remote
       - Cria branch remota se necessário
       - Confirmação antes do push

${YELLOW}EXEMPLOS DE USO:${NC}
    # Processo completo interativo
    $0

    # Ver ajuda
    $0 help

${YELLOW}TIPOS DE MENSAGEM DE COMMIT:${NC}
    ${GREEN}feat:${NC}     Nova funcionalidade
    ${GREEN}fix:${NC}      Correção de bug
    ${GREEN}docs:${NC}     Documentação
    ${GREEN}style:${NC}    Formatação, espaços em branco
    ${GREEN}refactor:${NC} Refatoração de código
    ${GREEN}test:${NC}     Adição ou correção de testes
    ${GREEN}chore:${NC}    Tarefas de manutenção

${YELLOW}SEGURANÇA:${NC}
    - Confirmação em cada etapa crítica
    - Visualização de arquivos antes do commit
    - Validação de configurações Git
    - Suporte a cancelamento em qualquer etapa

${BLUE}=============================================================================${NC}
EOF
}

# =============================================================================
# EXECUÇÃO PRINCIPAL
# =============================================================================

case "${1:-}" in
    "help"|"-h"|"--help")
        show_help
        ;;
    "")
        main
        ;;
    *)
        print_error "Opção inválida: $1"
        echo "Use '$0 help' para ver as opções disponíveis"
        exit 1
        ;;
esac
