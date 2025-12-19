import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { MercadoPagoConfig, Payment } from 'mercadopago';

export interface PixPaymentResponse {
  qr_code_base64: string;
  qr_code: string;
  payment_id: string;
  status: string;
}

export interface CardPaymentResponse {
  payment_id: string;
  status: string;
  status_detail: string;
  transaction_amount: number;
  installments?: number;
  payment_method_id?: string;
}

@Injectable()
export class MercadoPagoService implements OnModuleInit {
  private readonly logger = new Logger(MercadoPagoService.name);
  private client: MercadoPagoConfig;
  private paymentClient: Payment;
  // Cache em memória para armazenar status atualizados via webhook (para ambiente de teste)
  private paymentStatusCache: Map<string, { status: string; updatedAt: Date }> =
    new Map();

  constructor() {
    const accessToken = process.env.MERCADO_PAGO_ACCESS_TOKEN;

    if (!accessToken) {
      throw new Error(
        'MERCADO_PAGO_ACCESS_TOKEN is not configured. Please set the MERCADO_PAGO_ACCESS_TOKEN environment variable.',
      );
    }

    this.client = new MercadoPagoConfig({ accessToken });
    this.paymentClient = new Payment(this.client);
  }

  onModuleInit() {
    if (!this.client || !this.paymentClient) {
      throw new Error('Failed to initialize Mercado Pago client');
    }
    this.logger.log('Mercado Pago service initialized successfully');
  }

  async createPixPayment(
    amount: number,
    email: string,
    description: string,
  ): Promise<PixPaymentResponse> {
    try {
      this.logger.log(
        `Creating PIX payment: amount=${amount}, email=${email}, description=${description}`,
      );

      // Converter valor para o formato do Mercado Pago (em centavos/reais como float)
      // O Mercado Pago espera o valor como número decimal (ex: 49.90)
      // Nota: currency_id não é necessário para PIX, pois é inferido automaticamente
      const paymentData = {
        transaction_amount: amount,
        description: description,
        payment_method_id: 'pix',
        payer: {
          email: email,
        },
      };

      const payment = await this.paymentClient.create({ body: paymentData });

      this.logger.log(
        `Payment created: ${payment.id}, status: ${payment.status}`,
      );

      // Extrair informações do QR Code do PIX
      const transactionData = payment.point_of_interaction?.transaction_data;
      const qrCodeBase64 = transactionData?.qr_code_base64 || '';
      const qrCode = transactionData?.qr_code || '';

      if (!qrCode && !qrCodeBase64) {
        this.logger.warn(
          'QR code not found in payment response. Payment ID: ' + payment.id,
        );
      }

      return {
        qr_code_base64: qrCodeBase64,
        qr_code: qrCode,
        payment_id: payment.id?.toString() || '',
        status: payment.status || 'pending',
      };
    } catch (error: unknown) {
      this.logger.error('Error creating PIX payment:', error);
      if (
        error &&
        typeof error === 'object' &&
        'response' in error &&
        error.response &&
        typeof error.response === 'object' &&
        'data' in error.response
      ) {
        const apiError = error.response as { data: unknown };
        this.logger.error('Mercado Pago API error:', apiError.data);
        throw new Error(
          `Mercado Pago API error: ${JSON.stringify(apiError.data)}`,
        );
      }
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error creating PIX payment');
    }
  }

  async getPaymentStatus(paymentId: string) {
    try {
      this.logger.log(`Getting payment status for: ${paymentId}`);

      // Primeiro verificar se há um status atualizado no cache (via webhook simulado)
      const cachedStatus = this.paymentStatusCache.get(paymentId);
      if (cachedStatus) {
        this.logger.log(
          `Using cached status for payment ${paymentId}: ${cachedStatus.status}`,
        );
        // Buscar informações básicas do pagamento da API
        const payment = await this.paymentClient.get({ id: paymentId });
        return {
          id: payment.id,
          status: cachedStatus.status, // Usar status do cache
          transaction_amount: payment.transaction_amount,
          date_created: payment.date_created,
          date_approved:
            cachedStatus.status === 'approved'
              ? new Date(cachedStatus.updatedAt)
              : payment.date_approved,
        };
      }

      // Se não houver cache, buscar da API do Mercado Pago
      const payment = await this.paymentClient.get({ id: paymentId });
      return {
        id: payment.id,
        status: payment.status,
        transaction_amount: payment.transaction_amount,
        date_created: payment.date_created,
        date_approved: payment.date_approved,
      };
    } catch (error) {
      this.logger.error(
        `Error getting payment status for ${paymentId}:`,
        error,
      );
      throw error;
    }
  }

  async createCardPayment(
    amount: number,
    email: string,
    description: string,
    token: string,
    installments: number = 1,
    paymentMethodId?: string,
    issuerId?: string,
    payerIdentificationType?: string,
    payerIdentificationNumber?: string,
  ): Promise<CardPaymentResponse> {
    try {
      this.logger.log(
        `Creating card payment: amount=${amount}, email=${email}, installments=${installments}`,
      );

      interface PaymentData {
        transaction_amount: number;
        description: string;
        payment_method_id: string;
        payer: {
          email: string;
          identification?: {
            type: string;
            number: string;
          };
        };
        token: string;
        installments: number;
        issuer_id?: number;
        statement_descriptor?: string;
        capture?: boolean;
      }

      const paymentData: PaymentData = {
        transaction_amount: amount,
        description: description,
        payment_method_id: paymentMethodId || 'visa', // Padrão visa se não especificado
        payer: {
          email: email,
        },
        token: token, // Token do cartão gerado pelo Mercado Pago SDK
        installments: installments,
        statement_descriptor: description.substring(0, 22), // Máximo 22 caracteres
        // Adicionar captura automática para pagamentos aprovados
        capture: true,
      };

      // Adicionar identification do payer se fornecido
      if (payerIdentificationType && payerIdentificationNumber) {
        paymentData.payer.identification = {
          type: payerIdentificationType,
          number: payerIdentificationNumber.replace(/\D/g, ''), // Remove caracteres não numéricos
        };
      }

      // Adicionar issuer_id se fornecido
      if (issuerId) {
        paymentData.issuer_id = parseInt(issuerId, 10);
      }

      this.logger.log(
        `Payment data being sent: ${JSON.stringify(paymentData, null, 2)}`,
      );

      const payment = await this.paymentClient.create({ body: paymentData });

      this.logger.log(
        `Card payment created: ${payment.id}, status: ${payment.status}, status_detail: ${payment.status_detail}`,
      );

      // Log detalhado se for rejeitado
      if (payment.status === 'rejected') {
        this.logger.warn(
          `Payment rejected - ID: ${payment.id}, Status Detail: ${payment.status_detail}`,
        );

        // Log informações adicionais se disponíveis
        if (
          payment &&
          typeof payment === 'object' &&
          'cause' in payment &&
          Array.isArray((payment as { cause: unknown[] }).cause)
        ) {
          (payment as { cause: unknown[] }).cause.forEach(
            (cause: unknown, index: number) => {
              this.logger.warn(
                `Rejection cause ${index + 1}: ${JSON.stringify(cause)}`,
              );
            },
          );
        }

        // Log resposta completa para debug
        this.logger.warn(
          `Full payment response: ${JSON.stringify(payment, null, 2)}`,
        );

        // Log campos adicionais que podem ajudar a diagnosticar
        this.logger.warn(
          `Payment summary: ${JSON.stringify(
            {
              id: payment.id,
              status: payment.status,
              status_detail: payment.status_detail,
              payment_method_id: payment.payment_method_id,
              transaction_amount: payment.transaction_amount,
              installments: payment.installments,
            },
            null,
            2,
          )}`,
        );
      }

      return {
        payment_id: payment.id?.toString() || '',
        status: payment.status || 'pending',
        status_detail: payment.status_detail || '',
        transaction_amount: payment.transaction_amount || amount,
        installments: payment.installments || installments,
        payment_method_id: payment.payment_method_id || paymentMethodId,
      };
    } catch (error: unknown) {
      this.logger.error('Error creating card payment:', error);
      if (
        error &&
        typeof error === 'object' &&
        'response' in error &&
        error.response &&
        typeof error.response === 'object' &&
        'data' in error.response
      ) {
        const apiError = error.response as { data: unknown };
        this.logger.error('Mercado Pago API error:', apiError.data);
        throw new Error(
          `Mercado Pago API error: ${JSON.stringify(apiError.data)}`,
        );
      }
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Unknown error creating card payment');
    }
  }

  async updatePaymentStatus(paymentId: string, status: string) {
    this.logger.log(
      `Updating payment status: paymentId=${paymentId}, status=${status}`,
    );

    // Armazenar no cache em memória (para ambiente de teste)
    // Em produção, você atualizaria o status no banco de dados
    this.paymentStatusCache.set(paymentId, {
      status: status,
      updatedAt: new Date(),
    });

    this.logger.log(
      `Payment status cached: paymentId=${paymentId}, status=${status}`,
    );

    return Promise.resolve({
      payment_id: paymentId,
      status: status,
      updated_at: new Date().toISOString(),
    });
  }
}
