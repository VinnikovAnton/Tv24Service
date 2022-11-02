import { Injectable } from '@nestjs/common';
import { DatabaseService } from './database/database.service';
import { AuthResult } from './interfaces/authresult';
import { ContSuccess } from './interfaces/contsuccess';
import OracleDB = require('oracledb');

@Injectable()
export class AppService {

  constructor(private readonly database: DatabaseService) {}

  formatDate(date) {
    let r: string = '';
    let mm = +date.getMonth() + 1;
    if (mm < 10) r = r + '0';
    r = r + mm + '/';
    let dd: number = +date.getDate();
    if (dd < 10) r = r + '0';
    r = r + dd + '/';
    let yy = date.getFullYear();
    r = r + yy;
    return r;
  }

  async auth(phone: string, logger): Promise<AuthResult> {
    let r: AuthResult = new AuthResult();
    try {
      const sp = await this.database.getByQuery(
        `begin
            Wink.BP_Tv24.auth(
                :phone,
                :id
            );
         end;`, 
         {
            phone: { dir: OracleDB.BIND_IN, val: phone },
            id: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER }
         }
      );
      r.user_id = (<any>sp.outBinds).id;
      return r;
    } catch (error) {
      console.log(error);
      logger.error(error);
      r = null;
    }
    return r;
  }

  async cont(id: number, sum: number, tariff: string, start: string, logger) {
    let r: ContSuccess = new ContSuccess();
    try {
      const sp = await this.database.getByQuery(
        `begin
            Wink.BP_Tv24.cont(
                :id,
                :val,
                :tar,
                :start,
                :charge
            );
         end;`, 
         {
          id: { dir: OracleDB.BIND_IN, val: id },
          val: { dir: OracleDB.BIND_IN, val: sum },
          tar: { dir: OracleDB.BIND_IN, val: tariff },
          start: { dir: OracleDB.BIND_IN, val: start },
          charge: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER }
        }
      );
      r.status = 1;
      r.id = (<any>sp.outBinds).charge;
      return r;
    } catch (error) {
      console.log(error);
      logger.error(error);
      r = null;
    }
    return r;
  }

}
