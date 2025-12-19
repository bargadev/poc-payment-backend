import {
  IsNumber,
  IsPositive,
  Min,
  IsEmail,
  IsString,
  IsNotEmpty,
  IsOptional,
  IsInt,
  MinLength,
  MaxLength,
} from 'class-validator';

export class CreateCardPaymentDto {
  @IsNumber()
  @IsPositive()
  @Min(0.01)
  amount: number;

  @IsEmail()
  @IsNotEmpty()
  email: string;

  @IsString()
  @IsNotEmpty()
  description: string;

  @IsString()
  @IsNotEmpty()
  token: string; // Token do cartão gerado pelo Mercado Pago SDK

  @IsOptional()
  @IsInt()
  @Min(1)
  installments?: number; // Número de parcelas (padrão: 1)

  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(10) // Aceita valores como 'master', 'hipercard', etc.
  payment_method_id?: string; // Ex: 'visa', 'master', 'amex', 'elo', 'hipercard', etc.

  @IsOptional()
  @IsString()
  issuer_id?: string; // ID do banco emissor do cartão

  @IsOptional()
  payer_identification_type?: string; // Tipo de documento (CPF, CNPJ)

  @IsOptional()
  payer_identification_number?: string; // Número do documento
}

