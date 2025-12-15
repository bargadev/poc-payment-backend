import { IsNumber, IsPositive, Min, IsOptional, IsEnum } from 'class-validator';

export enum PaymentMethod {
  CARD = 'card',
  PIX = 'pix',
}

export class CreatePaymentDto {
  @IsNumber()
  @IsPositive()
  @Min(0.01)
  amount: number;

  @IsOptional()
  @IsEnum(PaymentMethod)
  paymentMethod?: PaymentMethod;
}

