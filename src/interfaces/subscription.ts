import { ApiProperty } from '@nestjs/swagger';
import { Packet } from './packet';

export class Subscription {
  @ApiProperty({ description: 'Пакет' })
  packet: Packet;
}
