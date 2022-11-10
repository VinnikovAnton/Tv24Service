import { Injectable } from '@nestjs/common';
import { DatabaseService } from './database/database.service';
import { AuthResult } from './interfaces/authresult';
import { ContSuccess } from './interfaces/contsuccess';
import { StatusSuccess } from './interfaces/statussuccess';
import OracleDB = require('oracledb');

@Injectable()
export class AppService {

  constructor(private readonly database: DatabaseService) {}

  async auth(phone: string, logger): Promise<AuthResult> {
    let r: AuthResult = new AuthResult();
    try {
      const sp = await this.database.getByQuery(
        `begin
            Wink.BP_Tv24.auth(
                :phone,
                :stat,
                :id
            );
         end;`, 
         {
            phone: { dir: OracleDB.BIND_IN, val: phone },
            stat: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER },
            id: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER }
         }
      );
      const stat = (<any>sp.outBinds).stat; 
      r.user_id = null;
      if (stat >= 0) {
        r.user_id = (<any>sp.outBinds).id;
      }
      return r;
    } catch (error) {
      console.log(error);
      logger.error(error);
      r = null;
    }
    return r;
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
