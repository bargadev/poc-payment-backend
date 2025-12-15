#!/bin/bash

# Script para testar o fluxo completo de pagamento
# Use este script após criar um PaymentIntent
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
BASE_URL="${API_URL:-http://localhost:3000}"

# PaymentIntent ID do exemplo
PAYMENT_INTENT_ID="pi_3Se6nLQ2ZR2RvASJ2PjN6GeO"

echo "🔍 Testando fluxo de pagamento..."
echo ""

# 1. Verificar status do PaymentIntent via API do Stripe
echo "1️⃣ Verificando status do PaymentIntent (via Stripe API):"
curl -s -X GET "https://api.stripe.com/v1/payment_intents/${PAYMENT_INTENT_ID}" \
  -H "Authorization: Bearer ${STRIPE_KEY}" \
  | python3 -m json.tool | grep -E "(id|status|amount|currency|client_secret)" | head -10
echo ""

# 2. Verificar status via seu backend (se estiver rodando)
echo "2️⃣ Verificando status via seu backend:"
curl -s -X GET "${BASE_URL}/payments/${PAYMENT_INTENT_ID}/status" \
  | python3 -m json.tool 2>/dev/null || echo "⚠️  Backend não está rodando ou endpoint não disponível"
echo ""

echo "📝 Próximos passos:"
echo ""
echo "Para concluir o pagamento, você precisa:"
echo ""
echo "1. No Frontend:"
echo "   - Usar o clientSecret: pi_3Se6nLQ2ZR2RvASJ2PjN6GeO_secret_6ANmbw1AmtaWbi5FB3H87HFBE"
echo "   - Coletar dados do cartão usando Stripe.js"
echo "   - Confirmar o pagamento com stripe.confirmCardPayment()"
echo ""
echo "2. Ou via Backend (menos comum):"
echo "   curl -X POST ${BASE_URL}/payments/${PAYMENT_INTENT_ID}/confirm \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"paymentMethodId\": \"pm_card_visa\"}'"
echo ""
echo "3. Verificar status atualizado:"
echo "   curl ${BASE_URL}/payments/${PAYMENT_INTENT_ID}/status"
echo ""

