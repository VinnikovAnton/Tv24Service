import { ApiProperty } from "@nestjs/swagger";

export class Packet {

    @ApiProperty({description: 'ID канала'})
    id: number;

    @ApiProperty({description: 'Цена'})
    price: number;
}