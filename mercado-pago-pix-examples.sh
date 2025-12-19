#!/bin/bash

# Exemplos de uso da API de PIX via Mercado Pago
# 
# Pré-requisitos:
# - Servidor rodando em http://localhost:3000
# - Variável de ambiente MERCADO_PAGO_ACCESS_TOKEN configurada

BASE_URL="http://localhost:3000"

echo "=== Exemplo 1: Criar pagamento PIX ==="
echo ""
curl -X POST "${BASE_URL}/payments/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 49.90,
    "email": "test@test.com",
    "description": "Pagamento POC PIX"
  }' | jq '.'

echo ""
echo "=== Exemplo 2: Criar pagamento PIX com valor diferente ==="
echo ""
curl -X POST "${BASE_URL}/payments/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.00,
    "email": "cliente@example.com",
    "description": "Pagamento de serviço"
  }' | jq '.'

echo ""
echo "=== Exemplo 3: Testar webhook (simulação) ==="
echo ""
curl -X POST "${BASE_URL}/webhooks/mercadopago" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment.updated",
    "data": {
      "id": "123456789",
      "status": "approved"
    }
  }' | jq '.'

echo ""
echo "=== Exemplo 4: Webhook com payment.created ==="
echo ""
curl -X POST "${BASE_URL}/webhooks/mercadopago" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment.created",
    "data": {
      "id": "987654321",
      "status": "pending"
    }
  }' | jq '.'

echo ""
echo "=== Exemplo usando fetch (JavaScript) ==="
echo ""
cat << 'EOF'
// Criar pagamento PIX
fetch('http://localhost:3000/payments/pix', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    amount: 49.90,
    email: 'test@test.com',
    description: 'Pagamento POC PIX'
  })
})
.then(response => response.json())
.then(data => {
  console.log('QR Code Base64:', data.qr_code_base64);
  console.log('QR Code (copia e cola):', data.qr_code);
  console.log('Payment ID:', data.payment_id);
  console.log('Status:', data.status);
})
.catch(error => console.error('Error:', error));
EOF

