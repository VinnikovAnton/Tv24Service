import { ApiProperty } from '@nestjs/swagger';

export class ContSuccess {
  @ApiProperty({ description: 'ID списания' })
  id: number;

  @ApiProperty({ description: 'Статус' })
  status: number;
}
