import { ApiProperty } from '@nestjs/swagger';

export class AuthError {
  @ApiProperty({ description: 'Статус' })
  status: number;

  @ApiProperty({ description: 'Код ошибки' })
  err: number;

  @ApiProperty({ description: 'Описание ошибки' })
  errmsg: string;
}
