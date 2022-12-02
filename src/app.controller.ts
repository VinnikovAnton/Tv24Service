import { Controller, HttpStatus, Post, Query, Req, Res, Body } from '@nestjs/common';
import { ApiNotFoundResponse, ApiOkResponse, ApiOperation, ApiQuery, ApiBody, ApiResponse } from '@nestjs/swagger';
import { AppService } from './app.service';
import { AuthError } from './interfaces/autherror';
import { AuthResult } from './interfaces/authresult';
import { ContError } from './interfaces/conterror';
import { ContSuccess } from './interfaces/contsuccess';
import { StatusError } from './interfaces/statuserror';
import { StatusSuccess } from './interfaces/statussuccess';
import { PacketRequest } from './interfaces/packetrequest';
import { DelSubscriptRq } from './interfaces/delsubscriptrq';

var winston = require('winston');
require('winston-daily-rotate-file');

const logFormat = winston.format.combine(
    winston.format.timestamp({
        format: 'HH:mm:ss'
    }),
    winston.format.printf(
        info => `${info.level}: ${info.timestamp} - ${info.message}`
    )
);

var transport = new winston.transports.DailyRotateFile({
//  dirname: '/var/log',
    filename: 'tv24-%DATE%.log',
    datePattern: 'YYYY-MM-DD',
    zippedArchive: true,
    maxSize: '20m',
    maxFiles: '14d'
});

var logger = winston.createLogger({
  format: logFormat,
  transports: [
    transport
  ]
});

@Controller()
export class AppController {
  constructor(private readonly service: AppService) {}

  @Post('auth?')
  @ApiOperation({description: 'Авторизация', summary: 'Авторизация'})
  @ApiQuery({name: 'ip', type: 'string', description: 'IP-адрес', required: false})
  @ApiQuery({name: 'phone', type: 'string', description: 'Телефон', required: true})
  @ApiQuery({name: 'mbr_id', type: 'number', description: 'ID', required: false})
  @ApiResponse({ type: AuthResult })
  @ApiOkResponse({ description: 'Successfully.'})
  @ApiNotFoundResponse({ description: 'Not Found.'})
  async auth(@Res() res, @Query('ip') ip: string, @Query('phone') phone: string, @Query('mbr_id') mbr_id: string): Promise<AuthResult | AuthError> {
    const logStr = 'AUTH: ip = ' + ip + ', phone = ' + phone + ', id = ' + mbr_id;
    console.log(logStr);
    logger.info(logStr);
    let r = await this.service.auth(phone, logger);
    if (r instanceof AuthResult) {
      const logStr = 'SUCCESS: user_id = ' + r.user_id;
      console.log(logStr);
      logger.info(logStr);
    } else {
      const logStr = 'FAIL: status=' + r.status + ', err=' + r.err + ', errmsg=' + r.errmsg;
      console.log(logStr);
      logger.error(logStr);
    }
    return res.status(HttpStatus.OK).json(r);
  }

  @Post('cont?')
  @ApiOperation({description: 'Списание', summary: 'Списание'})
  @ApiQuery({name: 'user_id', type: 'number', description: 'ID пользователя', required: true})
  @ApiQuery({name: 'sum', type: 'number', description: 'Сумма списания', required: true})
  @ApiQuery({name: 'cont_id', type: 'number', description: 'ID списания', required: false})
  @ApiQuery({name: 'trf_id', type: 'number', description: 'ID тарифа', required: false})
  @ApiQuery({name: 'message', type: 'string', description: 'Наименование тарифа', required: false})
  @ApiQuery({name: 'start', type: 'string', description: 'Дата списания (YYYY-MM-DD)', required: true})
  @ApiResponse({ type: ContSuccess })
  @ApiOkResponse({ description: 'Successfully.'})
  async cont(@Res() res, @Query('user_id') user_id: number, @Query('sum') sum: number, @Query('cont_id') cont_id: number, @Query('trf_id') trf_id: number, @Query('message') message: string, @Query('start') start: string): Promise<ContSuccess | ContError> {
    const logStr = 'CONT: user_id = ' + user_id + ', sum = ' + sum + ', cont_id = ' + cont_id + ', tariff = ' + message + '(' + trf_id + '), from = ' + start;
    console.log(logStr);
    logger.info(logStr);
    let r = await this.service.cont(user_id, sum, trf_id, message, start, logger);
    if (r instanceof ContSuccess) {
      const logStr = 'SUCCESS: chr_id = ' + r.id;
      console.log(logStr);
      logger.info(logStr);
    } else {
      const logStr = 'FAIL: status = ' + r.status + ', eeror_message = ' + r.errmsg;
      console.log(logStr);
      logger.error(logStr);
    }
    return res.status(HttpStatus.OK).json(r);
  }

  @Post('packet?')
  @ApiOperation({description: 'Запрос на подключение пакета', summary: 'Запрос на подключение пакета'})
  @ApiQuery({name: 'user_id', type: 'number', description: 'ID пользователя', required: true})
  @ApiQuery({name: 'trf_id', type: 'number', description: 'ID тарифа', required: false})
  @ApiBody({ type: PacketRequest })
  @ApiResponse({ type: StatusSuccess })
  @ApiOkResponse({ description: 'Successfully.'})
  async packet(@Res() res, @Query('user_id') user_id: number, @Query('trf_id') trf_id: number, @Body() body: PacketRequest): Promise<StatusSuccess | StatusError> {
    const price = body.packet.price;
    const logStr = 'PACKET: user_id = ' + user_id + ', tariff = ' + trf_id;
    console.log(logStr);
    logger.info(logStr);
    let r = await this.service.packet(user_id, trf_id, price, logger);
    if (r instanceof StatusSuccess) {
      const logStr = 'SUCCESS';
      console.log(logStr);
      logger.info(logStr);
    } else {
      const logStr = 'FAIL: status = ' + r.status + ', err_message = ' + r.errmsg;
      console.log(logStr);
      logger.error(logStr);
    }
    return res.status(HttpStatus.OK).json(r);
  }

  @Post('delete_subscription?')
  @ApiOperation({description: 'Запрос на удаление подписки', summary: 'Запрос на подключение пакета'})
  @ApiQuery({name: 'user_id', type: 'number', description: 'ID пользователя', required: true})
  @ApiQuery({name: 'sub_id', type: 'number', description: 'ID подписки', required: false})
  @ApiResponse({ type: StatusSuccess })
  @ApiOkResponse({ description: 'Successfully.'})
  async del(@Res() res, @Query('user_id') user_id: number, @Query('sub_id') sub_id: number, @Body() delSubRq: DelSubscriptRq): Promise<StatusSuccess | StatusError> {
    const packetId = delSubRq.subscription.packet.id;
    const logStr = 'DELETE_SUBSCRIPTION: user_id = ' + user_id + ', subscription_id = ' + sub_id + ', packet_id = ' + packetId;
    console.log(logStr);
    logger.info(logStr);
    let r = await this.service.del(user_id, sub_id, packetId, logger);
    if (r instanceof StatusSuccess) {
      const logStr = 'SUCCESS';
      console.log(logStr);
      logger.info(logStr);
    } else {
      const logStr = 'FAIL: status = ' + r.status + ', err_message = ' + r.errmsg;
      console.log(logStr);
      logger.error(logStr);
    }
    return res.status(HttpStatus.OK).json(r);
  }

}
