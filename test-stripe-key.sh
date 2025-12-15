#!/bin/bash

# Script para testar a chave da API do Stripe
# Uso: ./test-stripe-key.sh [sua_chave_aqui]
# Ou defina: export STRIPE_SECRET_KEY='sua_chave'

# Carrega do argumento ou variável de ambiente
# IMPORTANTE: Nunca commite chaves secretas no código!
# Use: export STRIPE_SECRET_KEY="sk_test_..." ou passe como argumento
if [ -n "$1" ]; then
  STRIPE_KEY="$1"
elif [ -n "$STRIPE_SECRET_KEY" ]; then
  STRIPE_KEY="$STRIPE_SECRET_KEY"
else
  echo "❌ Erro: STRIPE_SECRET_KEY não está definida"
  echo "   Use uma das opções:"
  echo "   1. export STRIPE_SECRET_KEY='sk_test_...'"
  echo "   2. ./test-stripe-key.sh 'sk_test_...'"
  exit 1
fi

echo "🔍 Testando chave da API do Stripe..."
echo "📏 Tamanho da chave: ${#STRIPE_KEY} caracteres"
echo ""

# Teste 1: Usando Authorization Bearer header
echo "Teste 1: Authorization Bearer header"
RESPONSE=$(curl -s -X GET "https://api.stripe.com/v1/customers" \
  -H "Authorization: Bearer ${STRIPE_KEY}" \
  -H "Content-Type: application/x-www-form-urlencoded")

echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# Teste 2: Usando Basic Auth
echo "Teste 2: Basic Auth"
RESPONSE=$(curl -s -X GET "https://api.stripe.com/v1/customers" \
  -u "${STRIPE_KEY}:")

echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# Teste 3: Verificar se a chave tem caracteres especiais
echo "Teste 3: Verificando caracteres na chave"
echo "$STRIPE_KEY" | od -c | head -5
echo ""

echo "✅ Testes concluídos"

