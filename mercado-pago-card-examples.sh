#!/bin/bash

# Exemplos de uso da API de Cartão de Crédito via Mercado Pago
# 
# Pré-requisitos:
# - Servidor rodando em http://localhost:3000
# - Variável de ambiente MERCADO_PAGO_ACCESS_TOKEN configurada
# - Token do cartão gerado pelo Mercado Pago SDK (veja documentação)

BASE_URL="http://localhost:3000"

echo "=== IMPORTANTE ==="
echo "Para usar pagamentos com cartão de crédito, você precisa:"
echo "1. Integrar o Mercado Pago SDK no frontend"
echo "2. Gerar um token do cartão usando o SDK"
echo "3. Enviar esse token para o backend"
echo ""
echo "Documentação: https://www.mercadopago.com.br/developers/pt/docs/checkout-api/integration-test/test-cards"
echo ""

echo "=== Exemplo 1: Criar pagamento com cartão de crédito ==="
echo ""
echo "Nota: Substitua 'SEU_TOKEN_AQUI' pelo token real gerado pelo Mercado Pago SDK"
echo ""
curl -X POST "${BASE_URL}/payments/card" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.00,
    "email": "test@test.com",
    "description": "Pagamento com cartão de crédito",
    "token": "SEU_TOKEN_AQUI",
    "installments": 1,
    "payment_method_id": "visa"
  }' | jq '.'

echo ""
echo "=== Exemplo 2: Pagamento parcelado (3x) ==="
echo ""
curl -X POST "${BASE_URL}/payments/card" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 300.00,
    "email": "cliente@example.com",
    "description": "Pagamento parcelado",
    "token": "SEU_TOKEN_AQUI",
    "installments": 3,
    "payment_method_id": "master"
  }' | jq '.'

echo ""
echo "=== Exemplo 3: Verificar status do pagamento ==="
echo ""
echo "Substitua PAYMENT_ID pelo ID retornado ao criar o pagamento"
echo ""
curl "${BASE_URL}/payments/card/PAYMENT_ID/status" | jq '.'

echo ""
echo "=== Cartões de Teste do Mercado Pago ==="
echo ""
cat << 'EOF'
Cartões de teste disponíveis:

Visa:
- Número: 4509 9535 6623 3704
- CVV: 123
- Data: 11/25

Mastercard:
- Número: 5031 7557 3453 0604
- CVV: 123
- Data: 11/25

American Express:
- Número: 3711 803032 57522
- CVV: 1234
- Data: 11/25

Para mais cartões de teste, consulte:
https://www.mercadopago.com.br/developers/pt/docs/checkout-api/integration-test/test-cards
EOF

