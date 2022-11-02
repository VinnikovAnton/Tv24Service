create or replace package bp_tv24 as
    procedure auth( pPhone in varchar2
                  , pId out number);
    procedure cont( pId in number
                  , pVal in number
                  , pTariff in varchar2
                  , pDate in varchar2
                  , pOut out number);
end bp_tv24;
/

create or replace package body bp_tv24 as

    procedure auth(pPhone in varchar2, pId out number) as
      lId number;
    begin
      select max(id) into lId
      from TV24_ACCOUNTS where phone = pPhone;
      if lId is null then
         insert into TV24_ACCOUNTS(id, phone) values (TV24_ACCOUNTS_SEQ.nextval, pPhone)
         returning id into lId;
      end if;
      pId := lId;
    end;

    procedure cont(pId in number, pVal in number, pTariff in varchar2, pDate in varchar2, pOut out number) as
    begin
      insert into TV24_CHARGES(id, acc_id, val, tariff, start_date) values(TV24_CHARGES_SEQ.nextval, pId, pVal, pTariff, to_date(pDate, 'YYYY-MM-DD'))
      returning id into pOut;
    end;

end bp_tv24;
/
