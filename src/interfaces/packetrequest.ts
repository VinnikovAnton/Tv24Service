import { ApiProperty } from "@nestjs/swagger";
import { Packet } from "./packet";

export class PacketRequest {
    @ApiProperty({description: 'Пакет'})
    packet: Packet;
}