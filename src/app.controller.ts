import { Controller, HttpStatus, Post, Query, Res } from '@nestjs/common';
import { ApiNotFoundResponse, ApiOkResponse, ApiOperation, ApiQuery, ApiResponse } from '@nestjs/swagger';
import { AppService } from './app.service';
import { AuthError } from './interfaces/autherror';
import { AuthResult } from './interfaces/authresult';
import { ContError } from './interfaces/conterror';
import { ContSuccess } from './interfaces/contsuccess';

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
    console.log('AUTH: ip = ' + ip + ', phone = ' + phone + ', id = ' + mbr_id);
    logger.info('AUTH: ip = ' + ip + ', phone = ' + phone + ', id = ' + mbr_id);
    const r = await this.service.auth(phone, logger);
    if (r === null) {
      let e: AuthError = new AuthError();
      e.status = -1;
      e.err = 404;
      e.errmsg = 'Абонент [' + phone + '] не найден';
      console.log('FAIL: ' + e.errmsg);
      logger.info('FAIL: ' + e.errmsg);
      return res.status(HttpStatus.NOT_FOUND).json(e);
    }
    console.log('SUCCESS: user_id = ' + r.user_id);
    logger.info('SUCCESS: user_id = ' + r.user_id);
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
    console.log('CONT: user_id = ' + user_id + ', sum = ' + sum + ', id = ' + cont_id + ', tariff = ' + message + '(' + trf_id + '), from = ' + start);
    logger.info('CONT: user_id = ' + user_id + ', sum = ' + sum + ', id = ' + cont_id + ', tariff = ' + message + '(' + trf_id + '), from = ' + start);
    let r = await this.service.cont(user_id, sum, message, start, logger);
    if (r === null) {
      let e: ContError = new ContError();
      e.status = -2;
      e.errmsg = 'Недостаточно денежных средств';
      console.log('FAIL: ' + e.errmsg);
      logger.info('FAIL: ' + e.errmsg);
      return res.status(HttpStatus.OK).json(e);
    }
    return res.status(HttpStatus.OK).json(r);
  }
}
