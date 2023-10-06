import { ApiProperty } from '@nestjs/swagger';
import { Packet } from './packet';
import { Tv24Contract } from './tv24contract';

export class PacketRequest {
  @ApiProperty({ description: 'Пакет' })
  packet: Packet;
  user: Tv24Contract;
}
