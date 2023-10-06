import { Injectable } from '@nestjs/common';
import OracleDB = require('oracledb');
import { DatabaseService } from './database/database.service';
import { AuthResult } from './interfaces/authresult';
import { AuthError } from './interfaces/autherror';
import { ContSuccess } from './interfaces/contsuccess';
import { ContError } from './interfaces/conterror';
import { StatusSuccess } from './interfaces/statussuccess';
import { StatusError } from './interfaces/statuserror';

@Injectable()
export class AppService {
  constructor(private readonly database: DatabaseService) {}

  async auth(phone: string): Promise<AuthResult | AuthError> {
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
          err_message: { dir: OracleDB.BIND_OUT, type: OracleDB.STRING },
        },
      );
      const stat = (<any>sp.outBinds).stat;
      const errMessage = (<any>sp.outBinds).err_message;
      if (stat >= 0) {
        const r: AuthResult = new AuthResult();
        r.user_id = (<any>sp.outBinds).id;
        await this.database.connection.commit;
        return r;
      } else {
        await this.database.connection.rollback;
        const e: AuthError = new AuthError();
        e.status = -1;
        e.err = stat;
        e.errmsg = errMessage;
        return e;
      }
    } catch (error) {
      await this.database.connection.rollback;
      const e: AuthError = new AuthError();
      e.status = -1;
      e.err = -2;
      e.errmsg = error.message;
      return e;
    }
  }

  async cont(
    id: number,
    sum: number,
    trf_id: number,
    tariff: string,
    start: string,
  ): Promise<ContSuccess | ContError> {
    try {
      const sp = await this.database.getByQuery(
        `begin
            Billing.BP_Tv24.cont(
                :id,
                :val,
                :trf,
                :tar,
                :start,
                :stat,
                :charge,
                :err_message
            );
         end;`,
        {
          id: { dir: OracleDB.BIND_IN, val: id },
          val: { dir: OracleDB.BIND_IN, val: sum },
          trf: { dir: OracleDB.BIND_IN, val: trf_id },
          tar: { dir: OracleDB.BIND_IN, val: tariff },
          start: { dir: OracleDB.BIND_IN, val: start },
          stat: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER },
          charge: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER },
          err_message: { dir: OracleDB.BIND_OUT, type: OracleDB.STRING },
        },
      );
      const status = (<any>sp.outBinds).stat;
      const errMessage = (<any>sp.outBinds).err_message;
      if (status == 1) {
        const r: ContSuccess = new ContSuccess();
        r.status = status;
        r.id = (<any>sp.outBinds).charge;
        return r;
      } else {
        const e: ContError = new ContError();
        e.status = status;
        e.errmsg = errMessage;
        return e;
      }
    } catch (error) {
      const e: ContError = new ContError();
      e.status = -3;
      e.errmsg = error.message;
      return e;
    }
  }

  async packet(
    id: number,
    trf_id,
    price: number,
  ): Promise<StatusSuccess | StatusError> {
    try {
      const sp = await this.database.getByQuery(
        `begin
            Billing.BP_Tv24.pack(
                :id,
                :trf,
                :price,
                :stat,
                :err_message
            );
         end;`,
        {
          id: { dir: OracleDB.BIND_IN, val: id },
          trf: { dir: OracleDB.BIND_IN, val: trf_id },
          price: { dir: OracleDB.BIND_IN, val: price },
          stat: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER },
          err_message: { dir: OracleDB.BIND_OUT, type: OracleDB.STRING },
        },
      );
      const status = (<any>sp.outBinds).stat;
      const err_message = (<any>sp.outBinds).err_message;
      if (status == 1) {
        await this.database.connection.commit;
        const r: StatusSuccess = new StatusSuccess();
        r.status = status;
        return r;
      } else {
        await this.database.connection.rollback;
        const e: StatusError = new StatusError();
        e.status = status;
        e.errmsg = err_message;
        return e;
      }
    } catch (error) {
      await this.database.connection.rollback;
      const e: StatusError = new StatusError();
      e.status = -3;
      e.errmsg = error.message;
      return e;
    }
  }

  async del(
    id: number,
    sub_id: number,
    packet_id: number,
  ): Promise<StatusSuccess | StatusError> {
    try {
      const sp = await this.database.getByQuery(
        `begin
            Billing.BP_Tv24.dels(
                :id,
                :sub,
                :packet_id,
                :stat,
                :err_message
            );
         end;`,
        {
          id: { dir: OracleDB.BIND_IN, val: id },
          sub: { dir: OracleDB.BIND_IN, val: sub_id },
          packet_id: { dir: OracleDB.BIND_IN, val: packet_id },
          stat: { dir: OracleDB.BIND_OUT, type: OracleDB.NUMBER },
          err_message: { dir: OracleDB.BIND_OUT, type: OracleDB.STRING },
        },
      );
      const status = (<any>sp.outBinds).stat;
      if (status == 1) {
        const r: StatusSuccess = new StatusSuccess();
        r.status = status;
        return r;
      } else {
        const e: StatusError = new StatusError();
        e.status = status;
        e.errmsg = (<any>sp.outBinds).err_message;
        return e;
      }
    } catch (error) {
      await this.database.connection.rollback;
      const e: StatusError = new StatusError();
      e.status = -3;
      e.errmsg = error.message;
      return e;
    }
  }

  getHello(): string {
    return 'Hello World!';
  }
}
