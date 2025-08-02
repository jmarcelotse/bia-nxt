#!/bin/bash

echo "🔄 Atualizando configurações para usar o novo domínio HTTPS..."

# Verificar se estamos no diretório correto
if [ ! -f "Dockerfile" ]; then
    echo "❌ Erro: Execute este script no diretório raiz do projeto"
    exit 1
fi

# Verificar status do git
echo "📋 Status atual do Git:"
git status

echo ""
echo "📝 Arquivos alterados:"
echo "- Dockerfile: http://bia-alb-690586468.us-east-1.elb.amazonaws.com → https://formacao.nxt-tse.com"
echo "- .github/workflows/deploy.yml: Atualizado para usar HTTPS"

echo ""
read -p "🤔 Deseja fazer commit e push das alterações? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Fazendo commit das alterações..."
    
    # Adicionar arquivos alterados
    git add Dockerfile
    git add .github/workflows/deploy.yml
    
    # Fazer commit
    git commit -m "🔧 Update domain configuration to use HTTPS

- Update Dockerfile to use https://formacao.nxt-tse.com
- Update GitHub Actions workflow to use HTTPS
- Fix API URL configuration for production domain

This change ensures the application uses the proper HTTPS domain
instead of the direct ALB endpoint."
    
    # Push para o repositório
    echo "🚀 Fazendo push para o repositório..."
    git push origin main
    
    echo ""
    echo "✅ Alterações enviadas com sucesso!"
    echo "🔄 O GitHub Actions será executado automaticamente"
    echo "🌐 Nova URL: https://formacao.nxt-tse.com"
    
else
    echo "❌ Operação cancelada"
    echo "💡 Para fazer o commit manualmente:"
    echo "   git add Dockerfile .github/workflows/deploy.yml"
    echo "   git commit -m 'Update domain to HTTPS'"
    echo "   git push origin main"
fi

echo ""
echo "📋 Resumo das alterações:"
echo "✅ Dockerfile atualizado"
echo "✅ GitHub Actions atualizado"
echo "🔄 Próximo passo: Aguardar deploy automático"
