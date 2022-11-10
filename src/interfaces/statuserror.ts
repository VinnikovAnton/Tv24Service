import { ApiProperty } from "@nestjs/swagger";

export class StatusError {
    @ApiProperty({description: 'Код ошибки'})
    status: number;

    @ApiProperty({description: 'Описание ошибки'})
    errmsg: string;
}