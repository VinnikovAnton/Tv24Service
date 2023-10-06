import { ApiProperty } from '@nestjs/swagger';

export class ContError {
  @ApiProperty({ description: 'Код ошибки' })
  status: number;

  @ApiProperty({ description: 'Описание ошибки' })
  errmsg: string;
}
