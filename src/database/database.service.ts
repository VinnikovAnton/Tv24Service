import OracleDB = require('oracledb');
import { Injectable } from '@nestjs/common';
import { appConstants } from './constant';

@Injectable()
export class DatabaseService {
  connection: OracleDB.Connection | null = null;

  async getByQuery<T>(
    query: string, 
    params?: Array<string | number> | { [key: string]: OracleDB.BindParameter }
  ): Promise<OracleDB.Result<T>> {
    try {
      const r: any = await this.connection.execute(query, params);
      await this.connection.commit();
      return r;
    } catch (error) {
      console.log(error);
      await this.onApplicationShutdown();
      await this.onApplicationBootstrap();
      console.log("ORA Reconnected");
      return await this.connection.execute(query, params);
    }
  }

  async onApplicationBootstrap() {
    try {
      this.connection = await OracleDB.getConnection( {
        user: appConstants.db_user,
        password: appConstants.db_password,
        connectString: appConstants.db_host + ":" + appConstants.db_port + "/" + appConstants.db_service
      });
    } catch (error) {
      console.log(error);
    }
  }

  async onApplicationShutdown() {
    if (this.connection) {
      try {
        await this.connection.close();
      } catch (error) {
        console.error(error);
      }
    }
  }
}
