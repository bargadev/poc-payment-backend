import {
  Controller,
  Post,
  HttpCode,
  HttpStatus,
  Req,
  Logger,
} from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request } from 'express';
import { MercadoPagoService } from '../payments/mercado-pago.service';

@Controller('webhooks')
export class WebhooksController {
  private readonly logger = new Logger(WebhooksController.name);

  constructor(private readonly mercadoPagoService: MercadoPagoService) {}

  @Post('mercadopago')
  @HttpCode(HttpStatus.OK)
  async handleMercadoPagoWebhook(@Req() req: RawBodyRequest<Request>) {
    try {
      const data = req.body;
      this.logger.log('Webhook received from Mercado Pago:', JSON.stringify(data));

      // O Mercado Pago envia diferentes tipos de eventos
      // Para pagamentos, geralmente vem como 'type' ou podemos verificar o objeto 'data'
      const type = data?.type || data?.action;

      // Tratar eventos de pagamento
      if (type === 'payment.created' || type === 'payment.updated' || data?.data?.id) {
        const paymentData = data?.data || data;
        const paymentId = paymentData?.id?.toString();
        const status = paymentData?.status;

        if (paymentId && status) {
          this.logger.log(
            `Processing payment event: paymentId=${paymentId}, status=${status}, type=${type}`,
          );

          // Atualizar status do pagamento
          await this.mercadoPagoService.updatePaymentStatus(paymentId, status);

          this.logger.log(
            `Payment status updated: paymentId=${paymentId}, status=${status}`,
          );
        } else {
          this.logger.warn(
            'Payment ID or status missing in webhook data',
            JSON.stringify(paymentData),
          );
        }
      } else {
        this.logger.log(`Received webhook type: ${type}, not a payment event`);
      }

      return {
        received: true,
        processed: true,
      };
    } catch (error) {
      this.logger.error('Error processing Mercado Pago webhook:', error);
      // Retornar 200 mesmo em caso de erro para evitar retentativas desnecessárias
      // Em produção, você pode querer fazer log e processar em background
      return {
        received: true,
        processed: false,
        error: error.message,
      };
    }
  }
}

