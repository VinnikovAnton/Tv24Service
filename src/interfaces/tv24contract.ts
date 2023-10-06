import { ApiProperty } from '@nestjs/swagger';

export class Tv24Contract {
  @ApiProperty({ description: 'ID пользователя в платформе 24часаТВ' })
  id: number;

  @ApiProperty({ description: 'Номер телефона пользователя' })
  phone: number;

  @ApiProperty({
    description: 'Provider user id – id из биллинговой системы провайдера',
  })
  provider_uid: number;
}
