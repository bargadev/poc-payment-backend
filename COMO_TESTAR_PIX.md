# Como Finalizar um Pagamento PIX no Ambiente de Teste do Mercado Pago

## ⚠️ Importante: Ambiente de Teste

No ambiente de **teste/sandbox** do Mercado Pago, você **NÃO pode fazer um pagamento PIX real**. O QR Code gerado é apenas para visualização. Para finalizar o teste, você precisa **simular a aprovação** do pagamento através de webhooks.

## 📋 Passo a Passo

### 1. Criar um Pagamento PIX

```bash
curl -X POST "http://localhost:3000/payments/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 49.90,
    "email": "test@test.com",
    "description": "Pagamento POC PIX"
  }'
```

**Resposta esperada:**

```json
{
  "qr_code_base64": "...",
  "qr_code": "00020126...",
  "payment_id": "123456789",
  "status": "pending"
}
```

**⚠️ Anote o `payment_id` retornado!** Você precisará dele para simular a aprovação.

### 2. Simular Aprovação do Pagamento

Use o `payment_id` retornado no passo anterior para simular a aprovação:

```bash
curl -X POST "http://localhost:3000/webhooks/mercadopago" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment.updated",
    "data": {
      "id": "123456789",
      "status": "approved"
    }
  }'
```

**Substitua `123456789` pelo `payment_id` real que você recebeu!**

### 3. Verificar Status do Pagamento

```bash
curl "http://localhost:3000/payments/pix/123456789/status"
```

## 🔄 Fluxo Completo de Teste

### Opção 1: Usando o Script Shell

```bash
# 1. Criar pagamento e salvar o payment_id
PAYMENT_RESPONSE=$(curl -s -X POST "http://localhost:3000/payments/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 49.90,
    "email": "test@test.com",
    "description": "Pagamento POC PIX"
  }')

# 2. Extrair o payment_id
PAYMENT_ID=$(echo $PAYMENT_RESPONSE | jq -r '.payment_id')
echo "Payment ID: $PAYMENT_ID"

# 3. Simular aprovação
curl -X POST "http://localhost:3000/webhooks/mercadopago" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"payment.updated\",
    \"data\": {
      \"id\": \"$PAYMENT_ID\",
      \"status\": \"approved\"
    }
  }"
```

### Opção 2: Usando JavaScript/Fetch

```javascript
// 1. Criar pagamento
const createPayment = async () => {
  const response = await fetch('http://localhost:3000/payments/pix', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      amount: 49.9,
      email: 'test@test.com',
      description: 'Pagamento POC PIX',
    }),
  });

  const data = await response.json();
  console.log('Payment ID:', data.payment_id);
  return data.payment_id;
};

// 2. Simular aprovação
const approvePayment = async (paymentId) => {
  const response = await fetch('http://localhost:3000/webhooks/mercadopago', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      type: 'payment.updated',
      data: {
        id: paymentId,
        status: 'approved',
      },
    }),
  });

  return await response.json();
};

// Usar
const paymentId = await createPayment();
await approvePayment(paymentId);
```

## 📊 Status Possíveis

- `pending` - Pagamento pendente (aguardando pagamento)
- `approved` - Pagamento aprovado ✅
- `rejected` - Pagamento rejeitado ❌
- `cancelled` - Pagamento cancelado
- `in_process` - Pagamento em processamento

## 🎯 Exemplo Prático Completo

```bash
#!/bin/bash

BASE_URL="http://localhost:3000"

echo "=== 1. Criando pagamento PIX ==="
PAYMENT_RESPONSE=$(curl -s -X POST "${BASE_URL}/payments/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 49.90,
    "email": "test@test.com",
    "description": "Pagamento POC PIX"
  }')

echo "$PAYMENT_RESPONSE" | jq '.'

PAYMENT_ID=$(echo "$PAYMENT_RESPONSE" | jq -r '.payment_id')
echo ""
echo "Payment ID: $PAYMENT_ID"
echo ""

echo "=== 2. Aguardando 2 segundos... ==="
sleep 2

echo ""
echo "=== 3. Simulando aprovação do pagamento ==="
curl -X POST "${BASE_URL}/webhooks/mercadopago" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"payment.updated\",
    \"data\": {
      \"id\": \"$PAYMENT_ID\",
      \"status\": \"approved\"
    }
  }" | jq '.'
```

## 🔍 Verificar Logs do Backend

O backend vai logar quando receber o webhook:

```
[WebhooksController] Webhook received from Mercado Pago: {...}
[WebhooksController] Processing payment event: paymentId=123456789, status=approved
[MercadoPagoService] Updating payment status: paymentId=123456789, status=approved
```

## 💡 Dicas

1. **Sempre use o `payment_id` real** retornado ao criar o pagamento
2. **No ambiente de produção**, o Mercado Pago enviará webhooks automaticamente quando o pagamento for confirmado
3. **Para testes locais**, você precisa simular manualmente os webhooks
4. **Use ferramentas como ngrok** se quiser receber webhooks reais do Mercado Pago em desenvolvimento

## 🚀 Script Automatizado

Veja o arquivo `test-pix-complete.sh` para um script completo que faz tudo automaticamente!
