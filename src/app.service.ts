import { Injectable } from '@nestjs/common';
import { DatabaseService } from './database/database.service';
import { AuthResult } from './interfaces/authresult';
import { AuthError } from './interfaces/autherror';
import { ContSuccess } from './interfaces/contsuccess';
import { StatusSuccess } from './interfaces/statussuccess';
import OracleDB = require('oracledb');

@Injectable()
export class AppService {

  constructor(private readonly database: DatabaseService) {}

  async auth(phone: string, logger): Promise<AuthResult | AuthError> {
    try {
      const sp = await this.database.getByQuery(
        `begin
            Billing.BP_Tv24.auth(
                :phone,
                :id,
                :stat,
                :err_message
            );
         end;`, 
         {
            phone: { dir: OracleDB.BIND_IN, val: phone },
            id: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER },
            stat: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER },
            err_message: { dir: OracleDB.BIND_OUT, type: OracleDB.STRING }
         }
      );
      const stat = (<any>sp.outBinds).stat; 
      const errMessage = (<any>sp.outBinds).err_message;
      if (stat >= 0) {
        let r: AuthResult = new AuthResult();
        r.user_id = (<any>sp.outBinds).id;
        console.log('SUCCESS: user_id = ' + r.user_id);
        logger.info('SUCCESS: user_id = ' + r.user_id);
          return r;
      } else {
        let e: AuthError = new AuthError();
        console.log(errMessage);
        logger.log(errMessage);
        e.status = -1;
        e.err = stat;
        e.errmsg = errMessage;
        return e;
      }
    } catch (error) {
      console.log(error);
      logger.error(error);
      let e: AuthError = new AuthError();
      e.status = -1;
      e.err = -2;
      e.errmsg = error.message;
      return e;
    }
  }

  async cont(id: number, sum: number, trf_id: number, tariff: string, start: string, logger): Promise<ContSuccess> {
    let r: ContSuccess = new ContSuccess();
    try {
      const sp = await this.database.getByQuery(
        `begin
            Wink.BP_Tv24.cont(
                :id,
                :val,
                :trf,
                :tar,
                :start,
                :stat,
                :charge
            );
         end;`, 
         {
          id: { dir: OracleDB.BIND_IN, val: id },
          val: { dir: OracleDB.BIND_IN, val: sum },
          trf: { dir: OracleDB.BIND_IN, val: trf_id },
          tar: { dir: OracleDB.BIND_IN, val: tariff },
          start: { dir: OracleDB.BIND_IN, val: start },
          stat: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER },
          charge: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER }
        }
      );
      r.status = (<any>sp.outBinds).stat;
      if (r.status >= 0) {
        r.id = (<any>sp.outBinds).charge;
      }
      return r;
    } catch (error) {
      console.log(error);
      logger.error(error);
      r.status = -1;
    }
    return r;
  }

  async packet(id: number, trf_id: number, logger): Promise<StatusSuccess> {
    let r: StatusSuccess = new StatusSuccess();
    try {
      const sp = await this.database.getByQuery(
        `begin
            Wink.BP_Tv24.pack(
                :id,
                :trf,
                :stat
            );
         end;`, 
         {
          id: { dir: OracleDB.BIND_IN, val: id },
          trf: { dir: OracleDB.BIND_IN, val: trf_id },
          stat: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER }
        }
      );
      r.status = (<any>sp.outBinds).stat;
    } catch (error) {
      console.log(error);
      logger.error(error);
      r = null;
    }
    return r;
  }

  async del(id: number, sub_id: number, logger): Promise<StatusSuccess> {
    let r: StatusSuccess = new StatusSuccess();
    try {
      const sp = await this.database.getByQuery(
        `begin
            Wink.BP_Tv24.dels(
                :id,
                :sub,
                :stat
            );
         end;`, 
         {
          id: { dir: OracleDB.BIND_IN, val: id },
          sub: { dir: OracleDB.BIND_IN, val: sub_id },
          stat: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER }
        }
      );
      r.status = (<any>sp.outBinds).stat;
    } catch (error) {
      console.log(error);
      logger.error(error);
      r = null;
    }
    return r;
  }

}
