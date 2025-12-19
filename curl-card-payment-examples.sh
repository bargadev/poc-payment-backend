#!/bin/bash

# Exemplos diretos de curl para pagamento com cartão
# 
# IMPORTANTE: Você precisa de um token do cartão gerado pelo Mercado Pago SDK
# Substitua 'SEU_TOKEN_AQUI' pelo token real gerado no frontend

BASE_URL="${BASE_URL:-http://localhost:3000}"

echo "=== Exemplos de curl para Pagamento com Cartão ==="
echo ""
echo "URL Base: ${BASE_URL}"
echo ""
echo "⚠️  IMPORTANTE: Substitua 'SEU_TOKEN_AQUI' pelo token real do cartão"
echo ""

# Exemplo 1: Pagamento à vista
echo "=== 1. Pagamento à vista (R$ 100,00) ==="
echo ""
cat << 'EOF'
curl -X POST "http://localhost:3000/payments/card" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.00,
    "email": "test@test.com",
    "description": "Pagamento de teste",
    "token": "SEU_TOKEN_AQUI",
    "installments": 1,
    "payment_method_id": "visa"
  }'
EOF

echo ""
echo ""

# Exemplo 2: Pagamento parcelado
echo "=== 2. Pagamento parcelado (3x de R$ 100,00) ==="
echo ""
cat << 'EOF'
curl -X POST "http://localhost:3000/payments/card" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 300.00,
    "email": "cliente@example.com",
    "description": "Pagamento parcelado em 3x",
    "token": "SEU_TOKEN_AQUI",
    "installments": 3,
    "payment_method_id": "master"
  }'
EOF

echo ""
echo ""

# Exemplo 3: Pagamento com CPF
echo "=== 3. Pagamento com identificação (CPF) ==="
echo ""
cat << 'EOF'
curl -X POST "http://localhost:3000/payments/card" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 150.00,
    "email": "comprador@example.com",
    "description": "Pagamento com CPF",
    "token": "SEU_TOKEN_AQUI",
    "installments": 1,
    "payment_method_id": "visa",
    "payer_identification_type": "CPF",
    "payer_identification_number": "12345678909"
  }'
EOF

echo ""
echo ""

# Exemplo 4: Verificar status
echo "=== 4. Verificar status do pagamento ==="
echo ""
cat << 'EOF'
# Substitua PAYMENT_ID pelo ID retornado ao criar o pagamento
curl -X GET "http://localhost:3000/payments/card/PAYMENT_ID/status" \
  -H "Content-Type: application/json"
EOF

echo ""
echo ""

# Exemplo 5: Com formatação JSON (usando jq)
echo "=== 5. Exemplo com formatação JSON (requer jq) ==="
echo ""
cat << 'EOF'
curl -X POST "http://localhost:3000/payments/card" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.00,
    "email": "test@test.com",
    "description": "Pagamento de teste",
    "token": "SEU_TOKEN_AQUI",
    "installments": 1,
    "payment_method_id": "visa"
  }' | jq '.'
EOF

echo ""
echo ""

echo "=== Cartões de Teste do Mercado Pago ==="
cat << 'EOF'
Visa (Aprovado):
- Número: 4509 9535 6623 3704
- CVV: 123
- Data: 11/25
- Nome: APRO

Visa (Recusado):
- Número: 4013 5406 8274 6260
- CVV: 123
- Data: 11/25
- Nome: OTHE

Mastercard (Aprovado):
- Número: 5031 7557 3453 0604
- CVV: 123
- Data: 11/25
- Nome: APRO

American Express:
- Número: 3711 803032 57522
- CVV: 1234
- Data: 11/25
- Nome: APRO

Para mais cartões de teste:
https://www.mercadopago.com.br/developers/pt/docs/checkout-api/integration-test/test-cards
EOF

