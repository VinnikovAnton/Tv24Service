import { ApiProperty } from '@nestjs/swagger';

export class AuthResult {
  @ApiProperty({ description: 'ID пользователя в системе провайдера' })
  user_id: number;
}
