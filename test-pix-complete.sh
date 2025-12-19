#!/bin/bash

# Script completo para testar pagamento PIX no Mercado Pago
# Este script cria um pagamento e simula a aprovação automaticamente

BASE_URL="http://localhost:3000"

echo "═══════════════════════════════════════════════════════════"
echo "  Teste Completo de Pagamento PIX - Mercado Pago"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Criar pagamento PIX
echo -e "${BLUE}📱 Passo 1: Criando pagamento PIX...${NC}"
echo ""

PAYMENT_RESPONSE=$(curl -s -X POST "${BASE_URL}/payments/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 49.90,
    "email": "test@test.com",
    "description": "Pagamento POC PIX"
  }')

# Verificar se houve erro
if echo "$PAYMENT_RESPONSE" | jq -e '.statusCode' > /dev/null 2>&1; then
  echo -e "${YELLOW}❌ Erro ao criar pagamento:${NC}"
  echo "$PAYMENT_RESPONSE" | jq '.'
  exit 1
fi

# Exibir resposta
echo "$PAYMENT_RESPONSE" | jq '.'
echo ""

# Extrair payment_id
PAYMENT_ID=$(echo "$PAYMENT_RESPONSE" | jq -r '.payment_id')

if [ -z "$PAYMENT_ID" ] || [ "$PAYMENT_ID" = "null" ]; then
  echo -e "${YELLOW}❌ Erro: Payment ID não encontrado na resposta${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Pagamento criado com sucesso!${NC}"
echo -e "${BLUE}Payment ID: ${GREEN}$PAYMENT_ID${NC}"
echo ""

# 2. Aguardar um pouco
echo -e "${BLUE}⏳ Aguardando 2 segundos...${NC}"
sleep 2
echo ""

# 3. Simular aprovação
echo -e "${BLUE}✅ Passo 2: Simulando aprovação do pagamento...${NC}"
echo ""

WEBHOOK_RESPONSE=$(curl -s -X POST "${BASE_URL}/webhooks/mercadopago" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"payment.updated\",
    \"data\": {
      \"id\": \"$PAYMENT_ID\",
      \"status\": \"approved\"
    }
  }")

echo "$WEBHOOK_RESPONSE" | jq '.'
echo ""

if echo "$WEBHOOK_RESPONSE" | jq -e '.processed' > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Webhook processado com sucesso!${NC}"
else
  echo -e "${YELLOW}⚠️  Webhook pode não ter sido processado corretamente${NC}"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo -e "${GREEN}✨ Teste concluído!${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "💡 Dica: Verifique os logs do backend para ver o processamento do webhook"
echo ""

