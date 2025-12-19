import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  HttpException,
  Req,
} from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { MercadoPagoService } from './mercado-pago.service';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { CreatePixPaymentDto } from './dto/create-pix-payment.dto';
import { CreateCardPaymentDto } from './dto/create-card-payment.dto';
import Stripe from 'stripe';
import type { Request } from 'express';

@Controller('payments')
export class PaymentsController {
  constructor(
    private readonly paymentsService: PaymentsService,
    private readonly mercadoPagoService: MercadoPagoService,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createPayment(@Body() createPaymentDto: CreatePaymentDto) {
    try {
      const paymentMethod = createPaymentDto.paymentMethod || 'card';
      const paymentIntent = await this.paymentsService.createPaymentIntent(
        createPaymentDto.amount,
        paymentMethod,
      );

      const response: any = {
        id: paymentIntent.id,
        clientSecret: paymentIntent.client_secret,
        amount: paymentIntent.amount / 100, // Converter de centavos para reais
        currency: paymentIntent.currency,
        status: paymentIntent.status,
        paymentMethod: paymentMethod,
      };

      // Se for PIX, adicionar informações do QR Code
      if (paymentMethod === 'pix' && paymentIntent.next_action) {
        const pixAction = paymentIntent.next_action as any;
        if (pixAction?.display_bank_transfer_instructions) {
          response.pixQrCode =
            pixAction.display_bank_transfer_instructions.qr_code;
          response.pixInstructions =
            pixAction.display_bank_transfer_instructions;
        }
      }

      return response;
    } catch (error) {
      // Se for erro específico sobre PIX não habilitado, retornar mensagem mais clara
      if (error.message && error.message.includes('PIX não está habilitado')) {
        throw new HttpException(
          {
            statusCode: 400,
            message: error.message,
            type: 'pix_not_enabled',
            code: 'payment_method_not_available',
            helpUrl: 'https://dashboard.stripe.com/account/payments/settings',
          },
          400,
        );
      }

      if (error instanceof Stripe.errors.StripeError) {
        throw new HttpException(
          {
            statusCode: error.statusCode || 500,
            message: error.message,
            type: error.type,
            code: error.code,
          },
          error.statusCode || 500,
        );
      }
      throw error;
    }
  }

  @Get(':paymentIntentId/status')
  async getPaymentStatus(@Param('paymentIntentId') paymentIntentId: string) {
    try {
      const paymentIntent =
        await this.paymentsService.getPaymentIntentStatus(paymentIntentId);

      const response: any = {
        id: paymentIntent.id,
        amount: paymentIntent.amount / 100,
        currency: paymentIntent.currency,
        status: paymentIntent.status,
        clientSecret: paymentIntent.client_secret,
        paymentMethod: paymentIntent.payment_method,
        lastPaymentError: paymentIntent.last_payment_error,
      };

      // Se for PIX, adicionar informações do QR Code se disponível
      if (paymentIntent.payment_method_types?.includes('pix')) {
        if (paymentIntent.next_action) {
          const pixAction = paymentIntent.next_action as any;
          if (pixAction?.display_bank_transfer_instructions) {
            response.pixQrCode =
              pixAction.display_bank_transfer_instructions.qr_code;
            response.pixInstructions =
              pixAction.display_bank_transfer_instructions;
          }
        }
      }

      return response;
    } catch (error) {
      if (error instanceof Stripe.errors.StripeError) {
        throw new HttpException(
          {
            statusCode: error.statusCode || 500,
            message: error.message,
            type: error.type,
            code: error.code,
          },
          error.statusCode || 500,
        );
      }
      throw error;
    }
  }

  @Post(':paymentIntentId/confirm')
  @HttpCode(HttpStatus.OK)
  async confirmPayment(
    @Param('paymentIntentId') paymentIntentId: string,
    @Body() body?: { paymentMethodId?: string },
  ) {
    try {
      const paymentIntent = await this.paymentsService.confirmPaymentIntent(
        paymentIntentId,
        body?.paymentMethodId,
      );

      return {
        id: paymentIntent.id,
        amount: paymentIntent.amount / 100,
        currency: paymentIntent.currency,
        status: paymentIntent.status,
        clientSecret: paymentIntent.client_secret,
      };
    } catch (error) {
      if (error instanceof Stripe.errors.StripeError) {
        throw new HttpException(
          {
            statusCode: error.statusCode || 500,
            message: error.message,
            type: error.type,
            code: error.code,
          },
          error.statusCode || 500,
        );
      }
      throw error;
    }
  }

  @Post(':paymentIntentId/cancel')
  @HttpCode(HttpStatus.OK)
  async cancelPayment(@Param('paymentIntentId') paymentIntentId: string) {
    try {
      const paymentIntent =
        await this.paymentsService.cancelPaymentIntent(paymentIntentId);

      return {
        id: paymentIntent.id,
        amount: paymentIntent.amount / 100,
        currency: paymentIntent.currency,
        status: paymentIntent.status,
      };
    } catch (error) {
      if (error instanceof Stripe.errors.StripeError) {
        throw new HttpException(
          {
            statusCode: error.statusCode || 500,
            message: error.message,
            type: error.type,
            code: error.code,
          },
          error.statusCode || 500,
        );
      }
      throw error;
    }
  }

  @Post('pix')
  @HttpCode(HttpStatus.CREATED)
  async createPixPayment(@Body() createPixPaymentDto: CreatePixPaymentDto) {
    try {
      const payment = await this.mercadoPagoService.createPixPayment(
        createPixPaymentDto.amount,
        createPixPaymentDto.email,
        createPixPaymentDto.description,
      );

      return {
        qr_code_base64: payment.qr_code_base64,
        qr_code: payment.qr_code,
        payment_id: payment.payment_id,
        status: payment.status,
      };
    } catch (error: any) {
      throw new HttpException(
        {
          statusCode: error.statusCode || 500,
          message: error.message || 'Error creating PIX payment',
        },
        error.statusCode || 500,
      );
    }
  }

  @Get('config')
  getPaymentConfig() {
    // Retornar apenas a chave pública (não sensível)
    const publicKey = process.env.MERCADO_PAGO_PUBLIC_KEY;
    
    return {
      mercadoPagoPublicKey: publicKey || null,
      hasPublicKey: !!publicKey,
    };
  }

  @Get('pix/:paymentId/status')
  async getPixPaymentStatus(@Param('paymentId') paymentId: string) {
    try {
      const payment = await this.mercadoPagoService.getPaymentStatus(paymentId);

      return {
        id: payment.id,
        status: payment.status,
        amount: payment.transaction_amount,
        date_created: payment.date_created,
        date_approved: payment.date_approved,
      };
    } catch (error: any) {
      throw new HttpException(
        {
          statusCode: error.statusCode || 500,
          message: error.message || 'Error getting PIX payment status',
        },
        error.statusCode || 500,
      );
    }
  }

  @Post('card')
  @HttpCode(HttpStatus.CREATED)
  async createCardPayment(@Body() createCardPaymentDto: CreateCardPaymentDto) {
    try {
      const payment = await this.mercadoPagoService.createCardPayment(
        createCardPaymentDto.amount,
        createCardPaymentDto.email,
        createCardPaymentDto.description,
        createCardPaymentDto.token,
        createCardPaymentDto.installments || 1,
        createCardPaymentDto.payment_method_id,
        createCardPaymentDto.issuer_id,
        createCardPaymentDto.payer_identification_type,
        createCardPaymentDto.payer_identification_number,
      );

      return {
        payment_id: payment.payment_id,
        status: payment.status,
        status_detail: payment.status_detail,
        amount: payment.transaction_amount,
        installments: payment.installments,
        payment_method_id: payment.payment_method_id,
      };
    } catch (error: any) {
      throw new HttpException(
        {
          statusCode: error.statusCode || 500,
          message: error.message || 'Error creating card payment',
        },
        error.statusCode || 500,
      );
    }
  }

  @Get('card/:paymentId/status')
  async getCardPaymentStatus(@Param('paymentId') paymentId: string) {
    try {
      const payment = await this.mercadoPagoService.getPaymentStatus(paymentId);

      return {
        id: payment.id,
        status: payment.status,
        amount: payment.transaction_amount,
        date_created: payment.date_created,
        date_approved: payment.date_approved,
      };
    } catch (error: any) {
      throw new HttpException(
        {
          statusCode: error.statusCode || 500,
          message: error.message || 'Error getting card payment status',
        },
        error.statusCode || 500,
      );
    }
  }

  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  async handleWebhook(@Req() req: RawBodyRequest<Request>) {
    // Nota: Para webhooks reais, você precisa verificar a assinatura
    // usando o endpoint secret do Stripe
    // Por enquanto, este é um placeholder
    const event = req.body;

    return {
      received: true,
      event,
    };
  }
}

