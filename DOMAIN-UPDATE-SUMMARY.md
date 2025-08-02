# 🔧 Atualização do Domínio para HTTPS

## 📋 Resumo das Alterações

Foram realizadas as seguintes alterações para migrar do endpoint direto do ALB para o domínio personalizado com HTTPS:

### 🐳 Dockerfile
**Antes:**
```dockerfile
ARG VITE_API_URL=http://bia-alb-690586468.us-east-1.elb.amazonaws.com
```

**Depois:**
```dockerfile
ARG VITE_API_URL=https://formacao.nxt-tse.com
```

### 🚀 GitHub Actions (.github/workflows/deploy.yml)
**Antes:**
```yaml
ALB_URL: bia-alb-690586468.us-east-1.elb.amazonaws.com
```

**Depois:**
```yaml
ALB_URL: formacao.nxt-tse.com
```

**Alterações adicionais:**
- ✅ Comando de build atualizado para usar HTTPS
- ✅ Testes de conectividade atualizados para HTTPS
- ✅ URLs no deployment summary atualizadas para HTTPS

## 🌐 Configuração da Infraestrutura

### ✅ Componentes Já Configurados:
- **Route 53**: `formacao.nxt-tse.com` → ALB
- **Certificado SSL**: `*.nxt-tse.com` (válido)
- **ALB**: Listeners HTTP (80) e HTTPS (443)
- **ECS**: 2 tasks rodando e saudáveis
- **RDS**: PostgreSQL disponível

### 🔒 Security Groups:
- **ALB**: Permite HTTP/HTTPS de qualquer lugar
- **RDS**: Permite PostgreSQL apenas do ECS
- **EC2**: Instâncias ECS com acesso ao RDS

## 🚀 Próximos Passos

1. **Fazer commit das alterações:**
   ```bash
   ./update-domain.sh
   ```

2. **Aguardar o deploy automático** via GitHub Actions

3. **Testar a aplicação:**
   - 🌐 Frontend: https://formacao.nxt-tse.com
   - 🔗 API Versão: https://formacao.nxt-tse.com/api/versao
   - 📋 API Tarefas: https://formacao.nxt-tse.com/api/tarefas

## 🔍 Verificações Pós-Deploy

### ✅ Checklist de Testes:
- [ ] Frontend carrega corretamente
- [ ] API responde em `/api/versao`
- [ ] Conexão com banco de dados funciona
- [ ] CRUD de tarefas funciona
- [ ] Certificado SSL válido
- [ ] Redirecionamento HTTP → HTTPS

### 🐛 Possíveis Problemas:

1. **Cache do Browser:**
   - Limpar cache ou usar modo incógnito

2. **Propagação DNS:**
   - Aguardar alguns minutos para propagação

3. **Conexão com RDS:**
   - Verificar logs do ECS se houver problemas de DB

## 📊 Monitoramento

### 📈 Logs para Verificar:
```bash
# Logs do ECS
aws logs get-log-events --log-group-name "/ecs/task-def-bia-alb" --log-stream-name "STREAM_NAME"

# Status do serviço ECS
aws ecs describe-services --cluster cluster-bia-alb --services service-bia-alb

# Health check do target group
aws elbv2 describe-target-health --target-group-arn "arn:aws:elasticloadbalancing:us-east-1:873976611862:targetgroup/tg-bia/2f1d581fe8fec016"
```

## 🎯 Resultado Esperado

Após o deploy, a aplicação deve estar acessível em:
- **URL Principal**: https://formacao.nxt-tse.com
- **Protocolo**: HTTPS com certificado válido
- **Funcionalidade**: Completa com conexão ao RDS

---

**Data da Atualização**: $(date)
**Responsável**: Amazon Q Assistant
**Status**: ✅ Configurações atualizadas, aguardando deploy
