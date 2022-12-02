import { ApiProperty } from "@nestjs/swagger";
import { Subscription} from './subscription';

export class DelSubscriptRq {
    @ApiProperty({description: 'Подписка'})
    subscription: Subscription;
}