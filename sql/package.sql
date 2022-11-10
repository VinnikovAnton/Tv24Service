create or replace package bp_tv24 as
    procedure auth( pPhone in varchar2
                  , pStatus out number
                  , pId out number);
    procedure cont( pId in number
                  , pVal in number
                  , pTarId in number
                  , pTariff in varchar2
                  , pDate in varchar2
                  , pStatus out number
                  , pOut out number);
    procedure pack( pId in number
                  , pTarId in number
                  , pStatus out number);
    procedure dels( pId in number
                  , pSubId in number
                  , pStatus out number);
end bp_tv24;
/

create or replace package body bp_tv24 as

    procedure auth(pPhone in varchar2, pStatus out number, pId out number) as
      lId number;
    begin
      select max(id) into lId
      from TV24_ACCOUNTS where phone = pPhone;
      if lId is null then
         insert into TV24_ACCOUNTS(id, phone) values (TV24_ACCOUNTS_SEQ.nextval, pPhone)
         returning id into lId;
      end if;
      pId := lId;
      pStatus := 1;
    end;

    procedure cont(pId in number, pVal in number, pTarId in number, pTariff in varchar2, pDate in varchar2, pStatus out number, pOut out number) as
    begin
      insert into TV24_CHARGES(id, acc_id, val, tariff, start_date) values(TV24_CHARGES_SEQ.nextval, pId, pVal, pTariff, to_date(pDate, 'YYYY-MM-DD'))
      returning id into pOut;
      pStatus := 1;
    end;

    procedure pack( pId in number, pTarId in number, pStatus out number) as
    begin
      pStatus := 1;
    end;

    procedure dels( pId in number, pSubId in number, pStatus out number) as
    begin
      pStatus := 1;
    end;

end bp_tv24;
/
