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

CREATE OR REPLACE type tv24_package_rec is object (
   id number,
   parent_id number,
   name varchar2(100),
   description varchar2(1000),
   price number,
   base number
)
/

CREATE OR REPLACE type tv24_package_list is table of tv24_package_rec
/

create or replace package PDriverTv24 as
  function getPackages return tv24_package_list pipelined;
end;
/

create or replace package body PDriverTv24 as

  SERVICE_URL constant varchar2(100) default 'http://127.0.0.1:8092/tv24/'; -- 'http://api.24h.tv/v2/';
  TOKEN constant varchar2(100) default 'b196a328da2c0d8f0b99b589bde39cdacc8a9656';

  procedure getMethod( p_url    in  varchar2
                     , o_out    out nclob 
                     , o_result out number ) as
    vReq  utl_http.req;
    vResp utl_http.resp;
    vBuff raw(32767);
    vCbuf nclob default empty_clob;
  begin
    utl_http.set_response_error_check(FALSE);
    vReq := utl_http.begin_request(SERVICE_URL || p_url || '&token=' || TOKEN , 'GET');
    utl_http.set_header(vReq, 'User-Agent', 'Mozilla/4.0');
    vResp := utl_http.get_response(vReq);
    if vResp.status_code = 200 then
       begin
         loop
           utl_http.read_raw(vResp, vBuff, 32766);
           vCbuf := vCbuf || utl_raw.cast_to_varchar2(vBuff);
         end loop;
       exception
         when utl_http.END_OF_BODY then
           null;
         when others then
           utl_http.end_response(vResp);
           raise;
       end;  
    end if;
    utl_http.end_response(vResp);
    o_out := vCbuf; 
    o_result := vResp.status_code;
  end;

  function conv(pText in varchar2) return varchar2 as
    vRaw raw(32767);
  begin
    vRaw := utl_raw.cast_to_raw(pText);
    vRaw := utl_raw.convert(vRaw,'AMERICAN_AMERICA.CL8MSWIN1251','AMERICAN_AMERICA.UTF8');
    return utl_raw.cast_to_varchar2(vRaw);
  end;
  
  function getPackages return tv24_package_list pipelined as
    vUrl   varchar2(100) default 'packets?includes=availables'; 
    vResp  clob;
    vCode  number;
    vList  JSON_ARRAY_T;
    vAvail JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vRec   tv24_package_rec;
    vPar   number;
    vId    number;
    vName  varchar2(100);
    vDesc  varchar2(2000);
    vPrice number;
  begin
    getMethod(vUrl, vResp, vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vPar    := vNode.get_Number('id');
           vName  := conv(vNode.get_String('name')); 
           vDesc  := conv(vNode.get_String('description'));
           vPrice := vNode.get_Number('price');
           vRec   := tv24_package_rec(vPar, null, vName, vDesc, vPrice, 1);
           pipe row(vRec);
           vAvail := vNode.get_Array('available');
           for xi in 0 .. vAvail.get_size - 1 loop
               vNode  := TREAT(vAvail.get(xi) AS json_object_t);
               vId    := vNode.get_Number('id');
               vName  := conv(vNode.get_String('name')); 
               vDesc  := conv(vNode.get_String('description'));
               vPrice := vNode.get_Number('price');
               vRec   := tv24_package_rec(vId, vPar, vName, vDesc, vPrice, 0);
               pipe row(vRec);
           end loop;
       end loop; 
    end if;
    return;  
  end;

end;
/
