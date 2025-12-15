#!/bin/bash

# ✅ CURL FUNCIONANDO - Chave válida testada
# Este curl funciona corretamente com a chave do Stripe
#
# IMPORTANTE: Defina a variável de ambiente STRIPE_SECRET_KEY antes de executar:
#   export STRIPE_SECRET_KEY="sk_test_..."

STRIPE_KEY="${STRIPE_SECRET_KEY:-}"
if [ -z "$STRIPE_KEY" ]; then
  echo "❌ Erro: STRIPE_SECRET_KEY não está definida"
  echo "   Defina a variável de ambiente antes de executar:"
  echo "   export STRIPE_SECRET_KEY='sk_test_...'"
  exit 1
fi

echo "🔍 Testando API do Stripe com chave válida..."
echo ""

# Listar clientes
echo "📋 Listando clientes:"
curl -X GET "https://api.stripe.com/v1/customers" \
  -H "Authorization: Bearer ${STRIPE_KEY}" \
  | python3 -m json.tool
echo ""

# Listar payment intents
echo "💳 Listando payment intents:"
curl -X GET "https://api.stripe.com/v1/payment_intents?limit=5" \
  -H "Authorization: Bearer ${STRIPE_KEY}" \
  | python3 -m json.tool
echo ""

echo "✅ Testes concluídos com sucesso!"

