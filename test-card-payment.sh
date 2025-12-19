#!/bin/bash

# Script para testar pagamento de cartão via curl
# 
# IMPORTANTE: Este script requer um token do cartão gerado pelo Mercado Pago SDK
# O token é gerado no frontend usando o SDK do Mercado Pago
# 
# Para obter o token:
# 1. Integre o Mercado Pago SDK no seu frontend
# 2. Use o SDK para tokenizar os dados do cartão
# 3. Use o token retornado neste script

# Configurações
BASE_URL="${BASE_URL:-http://localhost:3000}"
CARD_TOKEN="${CARD_TOKEN:-}"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Script de Teste - Pagamento com Cartão ===${NC}\n"

# Verificar se o token foi fornecido
if [ -z "$CARD_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  ATENÇÃO: Token do cartão não fornecido${NC}"
    echo ""
    echo "Para usar este script, você precisa:"
    echo "1. Gerar um token do cartão usando o Mercado Pago SDK no frontend"
    echo "2. Exportar a variável CARD_TOKEN antes de executar:"
    echo "   export CARD_TOKEN='seu_token_aqui'"
    echo "   ./test-card-payment.sh"
    echo ""
    echo "Ou passe o token como parâmetro:"
    echo "   CARD_TOKEN='seu_token_aqui' ./test-card-payment.sh"
    echo ""
    echo -e "${YELLOW}Exemplo de uso do SDK no frontend:${NC}"
    echo "const mp = new MercadoPago('YOUR_PUBLIC_KEY');"
    echo "const cardForm = mp.fields({"
    echo "  amount: '100.00',"
    echo "  iframe: 'cardNumber',"
    echo "});"
    echo "// Após preencher o formulário, obter o token"
    echo "const token = await cardForm.createCardToken({"
    echo "  cardNumber: '4509 9535 6623 3704',"
    echo "  cardholderName: 'APRO',"
    echo "  cardExpirationMonth: '11',"
    echo "  cardExpirationYear: '25',"
    echo "  securityCode: '123',"
    echo "  identificationType: 'CPF',"
    echo "  identificationNumber: '12345678909'"
    echo "});"
    echo ""
    exit 1
fi

echo -e "${GREEN}Token do cartão configurado${NC}"
echo -e "${GREEN}URL base: ${BASE_URL}${NC}\n"

# Função para fazer requisição e formatar resposta
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    
    echo -e "${YELLOW}${description}${NC}"
    echo "Endpoint: ${method} ${endpoint}"
    if [ -n "$data" ]; then
        echo "Payload: $(echo $data | jq -c . 2>/dev/null || echo $data)"
    fi
    echo ""
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            "${BASE_URL}${endpoint}" \
            -H "Content-Type: application/json" \
            -d "$data")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            "${BASE_URL}${endpoint}" \
            -H "Content-Type: application/json")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    echo "Status HTTP: $http_code"
    echo "Resposta:"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    echo ""
    
    # Extrair payment_id se existir
    if echo "$body" | jq -e '.payment_id' > /dev/null 2>&1; then
        PAYMENT_ID=$(echo "$body" | jq -r '.payment_id')
        echo -e "${GREEN}✓ Payment ID: ${PAYMENT_ID}${NC}\n"
    fi
}

# Exemplo 1: Pagamento simples (à vista)
echo -e "${GREEN}=== Exemplo 1: Pagamento à vista (R$ 100,00) ===${NC}\n"
make_request "POST" "/payments/card" \
    "{
        \"amount\": 100.00,
        \"email\": \"test@test.com\",
        \"description\": \"Pagamento de teste - Cartão à vista\",
        \"token\": \"${CARD_TOKEN}\",
        \"installments\": 1,
        \"payment_method_id\": \"visa\"
    }" \
    "Criando pagamento à vista"

# Aguardar um pouco antes do próximo exemplo
sleep 2

# Exemplo 2: Pagamento parcelado (3x)
echo -e "${GREEN}=== Exemplo 2: Pagamento parcelado (3x de R$ 100,00) ===${NC}\n"
make_request "POST" "/payments/card" \
    "{
        \"amount\": 300.00,
        \"email\": \"cliente@example.com\",
        \"description\": \"Pagamento parcelado em 3x\",
        \"token\": \"${CARD_TOKEN}\",
        \"installments\": 3,
        \"payment_method_id\": \"master\"
    }" \
    "Criando pagamento parcelado"

# Aguardar um pouco
sleep 2

# Exemplo 3: Pagamento com identificação do pagador
echo -e "${GREEN}=== Exemplo 3: Pagamento com CPF do pagador ===${NC}\n"
make_request "POST" "/payments/card" \
    "{
        \"amount\": 150.00,
        \"email\": \"comprador@example.com\",
        \"description\": \"Pagamento com identificação\",
        \"token\": \"${CARD_TOKEN}\",
        \"installments\": 1,
        \"payment_method_id\": \"visa\",
        \"payer_identification_type\": \"CPF\",
        \"payer_identification_number\": \"12345678909\"
    }" \
    "Criando pagamento com CPF"

# Se tivermos um payment_id, verificar o status
if [ -n "$PAYMENT_ID" ]; then
    echo -e "${GREEN}=== Verificando status do último pagamento ===${NC}\n"
    make_request "GET" "/payments/card/${PAYMENT_ID}/status" \
        "" \
        "Consultando status do pagamento ${PAYMENT_ID}"
fi

echo -e "${GREEN}=== Testes concluídos ===${NC}"
echo ""
echo -e "${YELLOW}Cartões de teste do Mercado Pago:${NC}"
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

