import { Injectable, OnModuleInit } from '@nestjs/common';
import Stripe from 'stripe';

@Injectable()
export class PaymentsService implements OnModuleInit {
  private stripe: Stripe;

  constructor() {
    const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
    
    if (!stripeSecretKey) {
      throw new Error(
        'STRIPE_SECRET_KEY is not configured. Please set the STRIPE_SECRET_KEY environment variable.',
      );
    }

    this.stripe = new Stripe(stripeSecretKey);
  }

  onModuleInit() {
    // Additional validation when initializing the module
    if (!this.stripe) {
      throw new Error('Failed to initialize Stripe client');
    }
  }

  async createPaymentIntent(
    amount: number,
    paymentMethod?: 'card' | 'pix',
  ): Promise<Stripe.PaymentIntent> {
    // Convert amount to cents (Stripe works with cents)
    const amountInCents = Math.round(amount * 100);

    const paymentIntentParams: Stripe.PaymentIntentCreateParams = {
      amount: amountInCents,
      currency: 'brl',
    };

    if (paymentMethod === 'pix') {
      // Configurar para PIX
      paymentIntentParams.payment_method_types = ['pix'];
    } else {
      // Configurar para cartão (padrão)
      paymentIntentParams.automatic_payment_methods = {
        enabled: true,
      };
    }

    try {
      const paymentIntent = await this.stripe.paymentIntents.create(
        paymentIntentParams,
      );

      return paymentIntent;
    } catch (error) {
      // Melhorar mensagem de erro específica para PIX não habilitado
      if (
        error instanceof Stripe.errors.StripeInvalidRequestError &&
        error.message.includes('pix') &&
        error.message.includes('invalid')
      ) {
        throw new Error(
          `PIX não está habilitado na sua conta Stripe. ` +
          `Para habilitar PIX:\n` +
          `1. Acesse: https://dashboard.stripe.com/account/payments/settings\n` +
          `2. Ative o método de pagamento "PIX" nas configurações\n` +
          `3. Certifique-se de que sua conta está configurada para operar no Brasil\n\n` +
          `Erro original: ${error.message}`,
        );
      }
      throw error;
    }
  }

  async getPaymentIntentStatus(
    paymentIntentId: string,
  ): Promise<Stripe.PaymentIntent> {
    const paymentIntent = await this.stripe.paymentIntents.retrieve(
      paymentIntentId,
    );
    return paymentIntent;
  }

  async confirmPaymentIntent(
    paymentIntentId: string,
    paymentMethodId?: string,
  ): Promise<Stripe.PaymentIntent> {
    const confirmParams: Stripe.PaymentIntentConfirmParams = {};

    if (paymentMethodId) {
      confirmParams.payment_method = paymentMethodId;
    }

    const paymentIntent = await this.stripe.paymentIntents.confirm(
      paymentIntentId,
      confirmParams,
    );

    return paymentIntent;
  }

  async cancelPaymentIntent(
    paymentIntentId: string,
  ): Promise<Stripe.PaymentIntent> {
    const paymentIntent = await this.stripe.paymentIntents.cancel(
      paymentIntentId,
    );
    return paymentIntent;
  }
}

