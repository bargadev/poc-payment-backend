#!/bin/bash

# Exemplos de curl para testar a API do Stripe
# IMPORTANTE: Substitua YOUR_STRIPE_SECRET_KEY pela sua chave secreta real

STRIPE_KEY="${STRIPE_SECRET_KEY:-YOUR_STRIPE_SECRET_KEY}"

echo "🔑 Usando chave: ${STRIPE_KEY:0:20}..."
echo ""

# Exemplo 1: Listar clientes (GET)
echo "📋 Exemplo 1: Listar clientes"
curl -X GET "https://api.stripe.com/v1/customers" \
  -H "Authorization: Bearer ${STRIPE_KEY}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  | python3 -m json.tool
echo ""

# Exemplo 2: Criar um cliente (POST)
echo "➕ Exemplo 2: Criar um cliente"
curl -X POST "https://api.stripe.com/v1/customers" \
  -H "Authorization: Bearer ${STRIPE_KEY}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=customer@example.com" \
  -d "name=Test Customer" \
  | python3 -m json.tool
echo ""

# Exemplo 3: Listar payment intents
echo "💳 Exemplo 3: Listar payment intents"
curl -X GET "https://api.stripe.com/v1/payment_intents" \
  -H "Authorization: Bearer ${STRIPE_KEY}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  | python3 -m json.tool
echo ""

echo "✅ Exemplos concluídos"
echo ""
echo "💡 Dica: Para usar, defina a variável de ambiente:"
echo "   export STRIPE_SECRET_KEY='sua_chave_aqui'"
echo "   ./stripe-curl-examples.sh"

