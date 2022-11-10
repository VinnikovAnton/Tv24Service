import { ApiProperty } from "@nestjs/swagger";

export class StatusSuccess {
    @ApiProperty({description: 'Статус'})
    status: number;
}