import { IsNumber, IsPositive, Min, IsEmail, IsString, IsNotEmpty } from 'class-validator';

export class CreatePixPaymentDto {
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
}

