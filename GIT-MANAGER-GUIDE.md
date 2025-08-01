# 🔧 Git Manager - Guia Completo

## 📋 **Visão Geral**

O `git-manager.sh` é um script interativo que automatiza e simplifica o processo de gerenciamento Git, oferecendo uma interface amigável para operações como add, commit e push.

## ✨ **Características Principais**

### 🔍 **Verificação Inteligente**
- **Status detalhado**: Mostra arquivos modificados, adicionados, deletados
- **Configuração Git**: Valida nome e email do usuário
- **Contadores**: Quantifica tipos de alterações
- **Visualização colorida**: Interface clara e organizada

### 🌿 **Gerenciamento de Branches**
- **Lista completa**: Branches locais e remotos
- **Troca interativa**: Mudança segura entre branches
- **Criação automática**: Novas branches locais ou a partir de remotas
- **Branch atual destacada**: Identificação visual clara

### 📁 **Adição Flexível de Arquivos**
- **Todos os arquivos**: `git add .` com confirmação
- **Seleção individual**: Escolha específica de arquivos
- **Por tipo**: Apenas modificados ou apenas novos
- **Arquivos staged**: Usar arquivos já preparados

### 💬 **Commit Inteligente**
- **Visualização prévia**: Arquivos que serão commitados
- **Sugestões de formato**: Padrões de mensagem (feat, fix, docs, etc.)
- **Validação**: Mensagem obrigatória
- **Confirmação**: Revisão antes de executar

### 🚀 **Push Automático**
- **Detecção de remote**: Verifica configuração
- **Branch remota**: Cria se não existir
- **Upstream automático**: Configura tracking
- **Confirmação**: Controle total do usuário

## 🎯 **Como Usar**

### **Execução Básica**
```bash
# Navegar para o projeto
cd /home/ec2-user/bia

# Executar o script
./git-manager.sh
```

### **Ver Ajuda**
```bash
./git-manager.sh help
```

## 📊 **Fluxo Detalhado**

### **1. Verificação Inicial** ⚡
```
✅ Repositório Git encontrado
✅ Configuração do Git OK
ℹ️  Nome: Seu Nome
ℹ️  Email: seu@email.com
```

### **2. Status do Repositório** 📋
```
📊 Resumo das alterações:
   📝 Modificados: 2 arquivos
   ❓ Não rastreados: 3 arquivos

Detalhes dos arquivos:
   📝 Modificado: client/src/components/AddTask.jsx
   📝 Modificado: ecs-deploy.sh
   ❓ Não rastreado: git-manager.sh
```

### **3. Seleção de Branch** 🌿
```
❓ Branch atual: main

Branches locais:
   * main (atual)
     develop
     feature/new-ui

Branches remotos:
     origin/main
     origin/develop
```

### **4. Adição de Arquivos** 📁
```
Opções disponíveis:
   1) Adicionar todos os arquivos (git add .)
   2) Adicionar arquivos seletivamente
   3) Adicionar apenas arquivos modificados
   4) Adicionar apenas arquivos novos
   5) Pular adição (usar arquivos já staged)
```

### **5. Commit** 💬
```
Arquivos staged para commit:
   📝 Modificado: client/src/components/AddTask.jsx
   ❓ Adicionado: git-manager.sh

Sugestões de formato de mensagem:
   feat: nova funcionalidade
   fix: correção de bug
   docs: documentação

Digite a mensagem do commit: feat: add interactive git manager script
```

### **6. Push** 🚀
```
Push para repositório remoto:
Remote: https://github.com/user/repo.git
Branch: main

✅ Push realizado com sucesso!
ℹ️  Branch 'main' atualizada no remote
```

## 🎨 **Interface Visual**

### **Cores e Símbolos**
- 🔵 **Azul**: Cabeçalhos e informações gerais
- 🟢 **Verde**: Sucesso e confirmações
- 🟡 **Amarelo**: Avisos e modificações
- 🔴 **Vermelho**: Erros e deleções
- 🟣 **Roxo**: Informações e arquivos não rastreados
- 🔷 **Ciano**: Passos e processos

### **Símbolos Utilizados**
- ✅ Sucesso
- ⚠️ Aviso
- ❌ Erro
- ℹ️ Informação
- ❓ Pergunta
- 📋 Processo
- 📝 Modificado
- ➕ Adicionado
- 🗑️ Deletado
- 🔄 Renomeado

## 🔧 **Funcionalidades Avançadas**

### **Detecção Automática**
```bash
# O script detecta automaticamente:
- Tipo de alteração em cada arquivo
- Existência de branches remotas
- Configuração de upstream
- Status de staging dos arquivos
```

### **Validações de Segurança**
```bash
# Verificações realizadas:
- Repositório Git válido
- Configuração de usuário
- Mensagem de commit não vazia
- Confirmação antes de operações críticas
```

### **Suporte a Cenários Complexos**
```bash
# Cenários suportados:
- Branches que não existem no remote
- Primeiro push de uma branch
- Arquivos renomeados ou movidos
- Repositórios sem remote configurado
```

## 📚 **Exemplos Práticos**

### **Cenário 1: Commit Simples**
```bash
./git-manager.sh

# Fluxo:
# 1. Status mostrado automaticamente
# 2. Branch mantida (main)
# 3. Adicionar todos os arquivos (opção 1)
# 4. Mensagem: "fix: correct button text"
# 5. Push confirmado
```

### **Cenário 2: Nova Feature Branch**
```bash
./git-manager.sh

# Fluxo:
# 1. Status mostrado
# 2. Trocar branch → criar "feature/new-ui"
# 3. Seleção específica de arquivos (opção 2)
# 4. Mensagem: "feat: add new UI components"
# 5. Push com upstream automático
```

### **Cenário 3: Correção Rápida**
```bash
./git-manager.sh

# Fluxo:
# 1. Status mostrado
# 2. Branch mantida
# 3. Apenas arquivos modificados (opção 3)
# 4. Mensagem: "fix: resolve login issue"
# 5. Push para branch existente
```

## ⚙️ **Configuração e Personalização**

### **Configuração Inicial do Git**
```bash
# O script pode configurar automaticamente:
git config user.name "Seu Nome"
git config user.email "seu@email.com"
```

### **Variáveis de Ambiente**
```bash
# Cores podem ser personalizadas modificando:
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# ... etc
```

## 🚨 **Troubleshooting**

### **Problema: "Não é um repositório Git"**
```bash
# Solução:
cd /caminho/para/projeto
git init  # ou navegar para pasta com .git
```

### **Problema: "Configuração incompleta"**
```bash
# O script oferece configuração automática
# Ou configure manualmente:
git config user.name "Seu Nome"
git config user.email "seu@email.com"
```

### **Problema: "Nenhum remote configurado"**
```bash
# Adicionar remote:
git remote add origin https://github.com/user/repo.git
```

### **Problema: "Branch não existe no remote"**
```bash
# O script cria automaticamente com:
git push --set-upstream origin nome-da-branch
```

## 🎯 **Boas Práticas**

### **Mensagens de Commit**
```bash
# Formatos recomendados:
feat: adicionar nova funcionalidade
fix: corrigir bug na autenticação
docs: atualizar documentação da API
style: corrigir formatação do código
refactor: reorganizar estrutura de pastas
test: adicionar testes unitários
chore: atualizar dependências
```

### **Fluxo de Trabalho**
```bash
# Sequência recomendada:
1. Fazer alterações no código
2. Executar ./git-manager.sh
3. Revisar status e arquivos
4. Selecionar branch apropriada
5. Adicionar arquivos relevantes
6. Commit com mensagem descritiva
7. Push para remote
```

### **Organização de Branches**
```bash
# Convenções sugeridas:
main          # Branch principal
develop       # Branch de desenvolvimento
feature/nome  # Novas funcionalidades
fix/nome      # Correções de bugs
hotfix/nome   # Correções urgentes
```

## 📈 **Vantagens do Script**

### **Para Iniciantes**
- ✅ Interface guiada e intuitiva
- ✅ Explicações claras de cada etapa
- ✅ Prevenção de erros comuns
- ✅ Aprendizado dos comandos Git

### **Para Experientes**
- ✅ Automação de tarefas repetitivas
- ✅ Visualização rápida do status
- ✅ Seleção eficiente de arquivos
- ✅ Padronização de mensagens

### **Para Equipes**
- ✅ Consistência nos commits
- ✅ Redução de erros
- ✅ Processo padronizado
- ✅ Facilita code review

## 🔄 **Integração com Outros Scripts**

### **Com ECS Deploy**
```bash
# Fluxo completo:
1. Fazer alterações no código
2. ./git-manager.sh (commit e push)
3. ./ecs-deploy.sh deploy (deploy automático)
```

### **Com CI/CD**
```bash
# O script prepara commits que podem disparar:
- GitHub Actions
- GitLab CI
- Jenkins
- AWS CodePipeline
```

## 🎉 **Conclusão**

O **Git Manager** oferece uma experiência completa e segura para gerenciamento Git, combinando:

- ✅ **Simplicidade**: Interface intuitiva
- ✅ **Segurança**: Validações e confirmações
- ✅ **Flexibilidade**: Múltiplas opções de uso
- ✅ **Eficiência**: Automação de tarefas repetitivas

**🚀 Pronto para usar! Execute `./git-manager.sh` e experimente!**

---

**📅 Criado**: 2025-08-01  
**🔧 Versão**: 1.0  
**👨‍💻 Autor**: Amazon Q  
**📍 Localização**: `/home/ec2-user/bia/git-manager.sh`
