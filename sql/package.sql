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
   base number,
   http_code number,
   error_message varchar2(1000)
)
/

CREATE OR REPLACE type tv24_package_list is table of tv24_package_rec
/

CREATE OR REPLACE type tv24_abonent_rec is object (
   id number,
   username varchar2(500),
   first_name varchar2(500),
   last_name varchar2(500),
   phone varchar2(100),
   email varchar2(500),
   provider_id number,
   is_active number(1),
   http_code number,
   error_message varchar2(1000)
)
/

CREATE OR REPLACE type tv24_abonent_list is table of tv24_abonent_rec
/

CREATE OR REPLACE type tv24_subscription_rec is object (
   id varchar2(100),
   packet_id number,
   packet varchar2(100),
   price number,
   is_base number(1),
   is_renew number(1),
   is_paused number(1),
   start_at date,
   end_at date,
   http_code number,
   error_message varchar2(1000)
)
/

CREATE OR REPLACE type tv24_subscription_list is table of tv24_subscription_rec
/

CREATE OR REPLACE type tv24_pause_rec is object (
   id varchar2(100),
   start_at date,
   end_at date,
   http_code number,
   error_message varchar2(1000)
)
/

CREATE OR REPLACE type tv24_pause_list is table of tv24_pause_rec
/

create or replace package PDriverTv24 as
  function translit( p_text in varchar2 ) return varchar2;

  function getPackages return tv24_package_list pipelined;
  function getAbonents return tv24_abonent_list pipelined;
  function getAbonentById(pId in number) return tv24_abonent_list pipelined;
  function getAbonentsByPhone(pPhone in varchar2) return tv24_abonent_list pipelined;
  function getAbonentsByUid(pUid in number) return tv24_abonent_list pipelined;
  function getCurrSubscriptions(pId in number) return tv24_subscription_list pipelined;
  function getSubscriptions(pId in number) return tv24_subscription_list pipelined;
  function getPauses(pId in number, pSub in varchar2) return tv24_pause_list pipelined;
  
  function addAbonent(pUsername in varchar2, pFirst in varchar2, pLast in varchar2, pEmail in varchar2, pPhone in varchar2, pUid in number, pActive in number) return tv24_abonent_list pipelined;
  function chgAbonent(pId in number, pUsername in varchar2, pFirst in varchar2, pLast in varchar2, pEmail in varchar2, pPhone in varchar2) return tv24_abonent_list pipelined;
  function setAbonentProvider(pId in number, pUid in number) return tv24_abonent_list pipelined;
  function setAbonentActive(pId in number, pActive in number) return tv24_abonent_list pipelined;
  function setAbonentPacketPrice(pId in number, pPacket in number, pPrice in number) return tv24_package_list pipelined;
  function addSubscription(pId in number, pPacket in number, pRenew in number default 1) return tv24_subscription_list pipelined;
  function delSubscription(pId in number, pSub in number) return tv24_subscription_list pipelined;
  function addPause(pId in number, pSub in number, pStart in date default sysdate, pEnd in date default null) return tv24_pause_list pipelined;
  function addPausesAll(pId in number, pStart in date default sysdate, pEnd in date default null) return tv24_pause_list pipelined;
  function delPause(pId in number, pSub in number, pPause in varchar2) return tv24_pause_list pipelined;
  function delPausesAll(pId in number, pPause in varchar2) return tv24_pause_list pipelined;
end;
/

create or replace package body PDriverTv24 as

  SERVICE_URL constant varchar2(100) default 'http://127.0.0.1:8092/tv24/'; -- 'http://api.24h.tv/v2/';
  TOKEN constant varchar2(100) default 'b196a328da2c0d8f0b99b589bde39cdacc8a9656';
  
  function translit( p_text in varchar2 ) return varchar2 as
    r varchar2(1000);
  begin
    r := translate(p_text, 'ÀÁÂÃÄÅ¨ÇÈÉÊËÌÍÎÏÐÑÒÓÔÛÝàáâãäå¸çèéêëìíîïðñòóôûý', 'ABVGDEEZIYKLMNOPRSTUAYEabvgdeeziyklmnoprstuaye');
    r := replace(r, 'Æ', 'Zh');
    r := replace(r, 'æ', 'zh');
    r := replace(r, 'Õ', 'Kh');
    r := replace(r, 'õ', 'kh');
    r := replace(r, 'Ö', 'Ts');
    r := replace(r, 'ö', 'ts');
    r := replace(r, '×', 'Ch');
    r := replace(r, '÷', 'ch');
    r := replace(r, 'Ø', 'Sh');
    r := replace(r, 'ø', 'sh');
    r := replace(r, 'Ù', 'Shch');
    r := replace(r, 'ù', 'shch');
    r := replace(r, 'Þ', 'Yu');
    r := replace(r, 'þ', 'yu');
    r := replace(r, 'ß', 'Ya');
    r := replace(r, 'ÿ', 'ya');
    return r;
  end;

  procedure getMethod( p_url    in  varchar2
                     , o_out    out nclob 
                     , o_result out number ) as
    vReq  utl_http.req;
    vResp utl_http.resp;
    vBuff raw(32767);
    vCbuf nclob default empty_clob;
  begin
    utl_http.set_response_error_check(FALSE);
    vReq := utl_http.begin_request(SERVICE_URL || p_url || 'token=' || TOKEN , 'GET');
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

  procedure postMethod( pUrl     in  varchar2
                      , pText    in  varchar2 default null
                      , pMethod  in  varchar2 default 'POST'
                      , pFormat  in  varchar2 default 'json'
                      , pCharset in  varchar2 default ';charset=windows-1251'
                      , oOut     out nclob 
                      , oResult  out number ) as
    vReq  utl_http.req;
    vResp utl_http.resp;
    vBuff raw(32767);
    vCbuf nclob default empty_clob;
  begin
    utl_http.set_response_error_check(FALSE);
    vReq := utl_http.begin_request(SERVICE_URL || pUrl || 'token=' || TOKEN, pMethod);
    utl_http.set_header(vReq, 'User-Agent', 'Mozilla/4.0'); 
    utl_http.set_header(vReq, 'Content-Type', 'application/' || pFormat || pCharset);
    if not pText is null then 
       utl_http.set_header(vReq, 'Content-Length', length(pText));
       utl_http.write_text(vReq, pText);
    end if;    
    vResp := utl_http.get_response(vReq);
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
    utl_http.end_response(vResp);
    oOut := vCbuf; 
    oResult := vResp.status_code;
  end;

  function getString(pNode in JSON_OBJECT_T, pName in varchar2) return varchar2 as
    vRes varchar2(1000) default '';
  begin
    if not pNode.get(pName).is_null and pNode.get(pName).is_string then
       vRes := convert(pNode.get_String(pName),'CL8MSWIN1251','UTF8');
    end if;
    return vRes;
  end;
  
  function delSubscription(pId in number, pSub in number) return tv24_subscription_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/subscriptions/' || pSub || '?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vPack  JSON_OBJECT_T;
    vRec   tv24_subscription_rec;
    vId    varchar2(100);
    vPId   number;
    vPName varchar2(100);
    vPrice number;
    vBase  number default 0;
    vRenew number default 0;
    vPause number default 0;
    vStart Date;
    vEnd   Date;
    vDetail varchar2(1000);
  begin
    postMethod(pUrl => vUrl, pText => vBody.stringify, pMethod => 'DELETE', oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := getString(vNode, 'id');
           vStart := vNode.get_Timestamp('start_at');
           vEnd   := vNode.get_Timestamp('end_at');
           if vNode.get_Boolean('renew') then
              vRenew := 1;
           end if;
           if vNode.get_Boolean('is_paused') then
              vPause := 1;
           end if;
           vPack  := vNode.get_Object('packet');
           vPId   := vPack.get_Number('id');
           vPName := getString(vPack, 'name');
           vPrice := vPack.get_Number('price');
           if vPack.get_Boolean('base') then
              vBase := 1;
           end if;
           vRec   := tv24_subscription_rec(vId, vPId, vPName, vPrice, vBase, vRenew, vPause, vStart, vEnd, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_subscription_rec(null, null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;
  
  function addSubscription(pId in number, pPacket in number, pRenew in number default 1) return tv24_subscription_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/subscriptions?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vPack  JSON_OBJECT_T;
    vRec   tv24_subscription_rec;
    vId    varchar2(100);
    vPId   number;
    vPName varchar2(100);
    vPrice number;
    vBase  number default 0;
    vRenew number default 0;
    vPause number default 0;
    vStart Date;
    vEnd   Date;
    vDetail varchar2(1000);
  begin
    vBody.put('packet_id', pPacket);
    vBody.put('renew', pRenew > 0);
    postMethod(pUrl => vUrl, pText => vBody.stringify, oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := getString(vNode, 'id');
           vStart := vNode.get_Timestamp('start_at');
           vEnd   := vNode.get_Timestamp('end_at');
           if vNode.get_Boolean('renew') then
              vRenew := 1;
           end if;
           if vNode.get_Boolean('is_paused') then
              vPause := 1;
           end if;
           vPack  := vNode.get_Object('packet');
           vPId   := vPack.get_Number('id');
           vPName := getString(vPack, 'name');
           vPrice := vPack.get_Number('price');
           if vPack.get_Boolean('base') then
              vBase := 1;
           end if;
           vRec   := tv24_subscription_rec(vId, vPId, vPName, vPrice, vBase, vRenew, vPause, vStart, vEnd, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_subscription_rec(null, null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;
  
  function addAbonent(pUsername in varchar2, pFirst in varchar2, pLast in varchar2, pEmail in varchar2, pPhone in varchar2, pUid in number, pActive in number) return tv24_abonent_list pipelined as
    vUrl   varchar2(100) default 'users?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vNode  JSON_OBJECT_T;
    vRec   tv24_abonent_rec;
    vId    number;
    vUid   number;
    vName  varchar2(500);
    vFirst varchar2(500);
    vLast  varchar2(500);
    vPhone varchar2(100);
    vEMail varchar2(500);
    vActiv number default 0;
    vDetail varchar2(1000);
  begin
    vBody.put('username', translit(pUsername));
    vBody.put('first_name', translit(pFirst));
    vBody.put('last_name', translit(pLast));
    vBody.put('email', pEmail);
    vBody.put('phone', pPhone);
    if not pUid is null then   
       vBody.put('provider_uid', pUid);
    end if;
    vBody.put('is_provider_free', FALSE);
    vBody.put('is_active', pActive > 0);
    postMethod(pUrl => vUrl, pText => vBody.stringify, oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vNode := JSON_OBJECT_T.parse(vResp);
       vId    := vNode.get_Number('id');
       vUid   := vNode.get_Number('provider_uid');
       vName  := getString(vNode, 'username'); 
       vFirst := getString(vNode, 'first_name'); 
       vLast  := getString(vNode, 'last_name');
       vPhone := getString(vNode, 'phone'); 
       vEMail := getString(vNode, 'email');
       if vNode.get_Boolean('is_active') then
          vActiv := 1;
       end if; 
       vRec   := tv24_abonent_rec(vId, vName, vFirst, vLast, vPhone, vEMail, vUid, vActiv, vCode, null);
       pipe row(vRec);
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_abonent_rec(null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;
  end;

  function chgAbonent(pId in number, pUsername in varchar2, pFirst in varchar2, pLast in varchar2, pEmail in varchar2, pPhone in varchar2) return tv24_abonent_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vNode  JSON_OBJECT_T;
    vRec   tv24_abonent_rec;
    vId    number;
    vUid   number;
    vName  varchar2(500);
    vFirst varchar2(500);
    vLast  varchar2(500);
    vPhone varchar2(100);
    vEMail varchar2(500);
    vActiv number default 0;
    vDetail varchar2(1000);
  begin
    if not pUsername is null then
       vBody.put('username', translit(pUsername));
    end if;
    if not pFirst is null then
       vBody.put('first_name', translit(pFirst));
    end if;
    if not pLast is null then
       vBody.put('last_name', translit(pLast));
    end if;
    if not pEmail is null then
       vBody.put('email', pEmail);
    end if;
    if not pPhone is null then
       vBody.put('phone', pPhone);
    end if;
    postMethod(pUrl => vUrl, pText => vBody.stringify, pMethod => 'PATCH', oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vNode := JSON_OBJECT_T.parse(vResp);
       vId    := vNode.get_Number('id');
       vUid   := vNode.get_Number('provider_uid');
       vName  := getString(vNode, 'username'); 
       vFirst := getString(vNode, 'first_name'); 
       vLast  := getString(vNode, 'last_name');
       vPhone := getString(vNode, 'phone'); 
       vEMail := getString(vNode, 'email');
       if vNode.get_Boolean('is_active') then
          vActiv := 1;
       end if; 
       vRec   := tv24_abonent_rec(vId, vName, vFirst, vLast, vPhone, vEMail, vUid, vActiv, vCode, null);
       pipe row(vRec);
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_abonent_rec(null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;
  
  function setAbonentProvider(pId in number, pUid in number) return tv24_abonent_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vNode  JSON_OBJECT_T;
    vRec   tv24_abonent_rec;
    vId    number;
    vUid   number;
    vName  varchar2(500);
    vFirst varchar2(500);
    vLast  varchar2(500);
    vPhone varchar2(100);
    vEMail varchar2(500);
    vActiv number default 0;
    vDetail varchar2(1000);
  begin
    vBody.put('provider_uid', pUid);
    postMethod(pUrl => vUrl, pText => vBody.stringify, pMethod => 'PATCH', oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vNode := JSON_OBJECT_T.parse(vResp);
       vId    := vNode.get_Number('id');
       vUid   := vNode.get_Number('provider_uid');
       vName  := getString(vNode, 'username'); 
       vFirst := getString(vNode, 'first_name'); 
       vLast  := getString(vNode, 'last_name');
       vPhone := getString(vNode, 'phone'); 
       vEMail := getString(vNode, 'email');
       if vNode.get_Boolean('is_active') then
          vActiv := 1;
       end if; 
       vRec   := tv24_abonent_rec(vId, vName, vFirst, vLast, vPhone, vEMail, vUid, vActiv, vCode, null);
       pipe row(vRec);
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_abonent_rec(null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end; 
  
  function setAbonentActive(pId in number, pActive in number) return tv24_abonent_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vNode  JSON_OBJECT_T;
    vRec   tv24_abonent_rec;
    vId    number;
    vUid   number;
    vName  varchar2(500);
    vFirst varchar2(500);
    vLast  varchar2(500);
    vPhone varchar2(100);
    vEMail varchar2(500);
    vActiv number default 0;
    vDetail varchar2(1000);
  begin
    vBody.put('is_active', pActive > 0);
    postMethod(pUrl => vUrl, pText => vBody.stringify, pMethod => 'PATCH', oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vNode := JSON_OBJECT_T.parse(vResp);
       vId    := vNode.get_Number('id');
       vUid   := vNode.get_Number('provider_uid');
       vName  := getString(vNode, 'username'); 
       vFirst := getString(vNode, 'first_name'); 
       vLast  := getString(vNode, 'last_name');
       vPhone := getString(vNode, 'phone'); 
       vEMail := getString(vNode, 'email');
       if vNode.get_Boolean('is_active') then
          vActiv := 1;
       end if; 
       vRec   := tv24_abonent_rec(vId, vName, vFirst, vLast, vPhone, vEMail, vUid, vActiv, vCode, null);
       pipe row(vRec);
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_abonent_rec(null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end; 

  function addPause(pId in number, pSub in number, pStart in date default sysdate, pEnd in date default null) return tv24_pause_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/subscriptions/' || pSub || '/pauses?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vRec   tv24_pause_rec;
    vId    varchar2(100);
    vStart Date;
    vEnd   Date;
    vDetail varchar2(1000);
  begin
    vBody.put('start_at', pStart);
    vBody.put('end_at', pEnd);
    postMethod(pUrl => vUrl, pText => vBody.stringify, oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vNode := JSON_OBJECT_T.parse(vResp);
       vId    := getString(vNode, 'id');
       vStart := vNode.get_Timestamp('start_at');
       vEnd   := vNode.get_Timestamp('end_at');
       vRec   := tv24_pause_rec(vId, vStart, vEnd, vCode, null);
       pipe row(vRec);
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_pause_rec(null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;

  function delPause(pId in number, pSub in number, pPause in varchar2) return tv24_pause_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/subscriptions/' || pSub || '/pauses/' || pPause || '?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vRec   tv24_pause_rec;
    vId    varchar2(100);
    vStart Date;
    vEnd   Date;
    vDetail varchar2(1000);
  begin
    postMethod(pUrl => vUrl, pText => vBody.stringify, pMethod => 'DELETE', oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vNode := JSON_OBJECT_T.parse(vResp);
       vId    := getString(vNode, 'id');
       vStart := vNode.get_Timestamp('start_at');
       vEnd   := vNode.get_Timestamp('end_at');
       vRec   := tv24_pause_rec(vId, vStart, vEnd, vCode, null);
       pipe row(vRec);
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_pause_rec(null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;

  function addPausesAll(pId in number, pStart in date default sysdate, pEnd in date default null) return tv24_pause_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/pauses?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vRec   tv24_pause_rec;
    vId    varchar2(100);
    vStart Date;
    vEnd   Date;
    vDetail varchar2(1000);
  begin
    vBody.put('start_at', pStart);
    vBody.put('end_at', pEnd);
    postMethod(pUrl => vUrl, pText => vBody.stringify, oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := getString(vNode, 'id');
           vStart := vNode.get_Timestamp('start_at');
           vEnd   := vNode.get_Timestamp('end_at');
           vRec   := tv24_pause_rec(vId, vStart, vEnd, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_pause_rec(null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;

  function delPausesAll(pId in number, pPause in varchar2) return tv24_pause_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/pauses/' || pPause || '?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vRec   tv24_pause_rec;
    vId    varchar2(100);
    vStart Date;
    vEnd   Date;
    vDetail varchar2(1000);
  begin
    postMethod(pUrl => vUrl, pText => vBody.stringify, pMethod => 'DELETE', oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := getString(vNode, 'id');
           vStart := vNode.get_Timestamp('start_at');
           vEnd   := vNode.get_Timestamp('end_at');
           vRec   := tv24_pause_rec(vId, vStart, vEnd, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_pause_rec(null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;

  function getPauses(pId in number, pSub in varchar2) return tv24_pause_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/subscriptions/' || pSub || '/pauses?'; 
    vResp  clob;
    vCode  number;
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vRec   tv24_pause_rec;
    vId    varchar2(100);
    vStart Date;
    vEnd   Date;
    vDetail varchar2(1000);
  begin
    getMethod(vUrl, vResp, vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := getString(vNode, 'id');
           vStart := vNode.get_Timestamp('start_at');
           vEnd   := vNode.get_Timestamp('end_at');
           vRec   := tv24_pause_rec(vId, vStart, vEnd, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_pause_rec(null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;
  
  function getCurrSubscriptions(pId in number) return tv24_subscription_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/subscriptions/current?'; 
    vResp  clob;
    vCode  number;
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vPack  JSON_OBJECT_T;
    vRec   tv24_subscription_rec;
    vId    varchar2(100);
    vPId   number;
    vPName varchar2(100);
    vPrice number;
    vBase  number default 0;
    vRenew number default 0;
    vPause number default 0;
    vStart Date;
    vEnd   Date;
    vDetail varchar2(1000);
  begin
    getMethod(vUrl, vResp, vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := getString(vNode, 'id');
           vStart := vNode.get_Timestamp('start_at');
           vEnd   := vNode.get_Timestamp('end_at');
           if vNode.get_Boolean('renew') then
              vRenew := 1;
           end if;
           if vNode.get_Boolean('is_paused') then
              vPause := 1;
           end if;
           vPack  := vNode.get_Object('packet');
           vPId   := vPack.get_Number('id');
           vPName := getString(vPack, 'name');
           vPrice := vPack.get_Number('price');
           if vPack.get_Boolean('base') then
              vBase := 1;
           end if;
           vRec   := tv24_subscription_rec(vId, vPId, vPName, vPrice, vBase, vRenew, vPause, vStart, vEnd, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_subscription_rec(null, null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;

  function getSubscriptions(pId in number) return tv24_subscription_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/subscriptions?'; 
    vResp  clob;
    vCode  number;
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vPack  JSON_OBJECT_T;
    vRec   tv24_subscription_rec;
    vId    varchar2(100);
    vPId   number;
    vPName varchar2(100);
    vPrice number;
    vBase  number default 0;
    vRenew number default 0;
    vPause number default 0;
    vStart Date;
    vEnd   Date;
    vDetail varchar2(1000);
  begin
    getMethod(vUrl, vResp, vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := getString(vNode, 'id');
           vStart := vNode.get_Timestamp('start_at');
           vEnd   := vNode.get_Timestamp('end_at');
           if vNode.get_Boolean('renew') then
              vRenew := 1;
           end if;
           if vNode.get_Boolean('is_paused') then
              vPause := 1;
           end if;
           vPack  := vNode.get_Object('packet');
           vPId   := vPack.get_Number('id');
           vPName := getString(vPack, 'name');
           vPrice := vPack.get_Number('price');
           if vPack.get_Boolean('base') then
              vBase := 1;
           end if;
           vRec   := tv24_subscription_rec(vId, vPId, vPName, vPrice, vBase, vRenew, vPause, vStart, vEnd, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_subscription_rec(null, null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;
  
  function getAbonentsByUid(pUid in number) return tv24_abonent_list pipelined as
    vUrl   varchar2(100) default 'users?provider_uid=' || pUid || '&'; 
    vResp  clob;
    vCode  number;
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vRec   tv24_abonent_rec;
    vId    number;
    vUid   number;
    vName  varchar2(500);
    vFirst varchar2(500);
    vLast  varchar2(500);
    vPhone varchar2(100);
    vEMail varchar2(500);
    vActiv number default 0;
    vDetail varchar2(1000);
  begin
    getMethod(vUrl, vResp, vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := vNode.get_Number('id');
           vUid   := vNode.get_Number('provider_uid');
           vName  := getString(vNode, 'username'); 
           vFirst := getString(vNode, 'first_name'); 
           vLast  := getString(vNode, 'last_name');
           vPhone := getString(vNode, 'phone'); 
           vEMail := getString(vNode, 'email');
           if vNode.get_Boolean('is_active') then
              vActiv := 1;
           end if; 
           vRec   := tv24_abonent_rec(vId, vName, vFirst, vLast, vPhone, vEMail, vUid, vActiv, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_abonent_rec(null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;
  
  function getAbonentsByPhone(pPhone in varchar2) return tv24_abonent_list pipelined as
    vUrl   varchar2(100) default 'users?phone=' || pPhone || '&'; 
    vResp  clob;
    vCode  number;
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vRec   tv24_abonent_rec;
    vId    number;
    vUid   number;
    vName  varchar2(500);
    vFirst varchar2(500);
    vLast  varchar2(500);
    vPhone varchar2(100);
    vEMail varchar2(500);
    vActiv number default 0;
    vDetail varchar2(1000);
  begin
    getMethod(vUrl, vResp, vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := vNode.get_Number('id');
           vUid   := vNode.get_Number('provider_uid');
           vName  := getString(vNode, 'username'); 
           vFirst := getString(vNode, 'first_name'); 
           vLast  := getString(vNode, 'last_name');
           vPhone := getString(vNode, 'phone'); 
           vEMail := getString(vNode, 'email');
           if vNode.get_Boolean('is_active') then
              vActiv := 1;
           end if; 
           vRec   := tv24_abonent_rec(vId, vName, vFirst, vLast, vPhone, vEMail, vUid, vActiv, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_abonent_rec(null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;
  
  function getAbonentById(pId in number) return tv24_abonent_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '?'; 
    vResp  clob;
    vCode  number;
    vNode  JSON_OBJECT_T;
    vRec   tv24_abonent_rec;
    vId    number;
    vUid   number;
    vName  varchar2(500);
    vFirst varchar2(500);
    vLast  varchar2(500);
    vPhone varchar2(100);
    vEMail varchar2(500);
    vActiv number default 0;
    vDetail varchar2(1000);
  begin
    getMethod(vUrl, vResp, vCode);
    if vCode = 200 then
       vNode := JSON_OBJECT_T.parse(vResp);
       vId    := vNode.get_Number('id');
       vUid   := vNode.get_Number('provider_uid');
       vName  := getString(vNode, 'username'); 
       vFirst := getString(vNode, 'first_name'); 
       vLast  := getString(vNode, 'last_name');
       vPhone := getString(vNode, 'phone'); 
       vEMail := getString(vNode, 'email');
       if vNode.get_Boolean('is_active') then
          vActiv := 1;
       end if; 
       vRec   := tv24_abonent_rec(vId, vName, vFirst, vLast, vPhone, vEMail, vUid, vActiv, vCode, null);
       pipe row(vRec);
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_abonent_rec(null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;
  
  function getAbonents return tv24_abonent_list pipelined as
    vUrl   varchar2(100) default 'users?'; 
    vResp  clob;
    vCode  number;
    vList  JSON_ARRAY_T;
    vNode  JSON_OBJECT_T;
    vRec   tv24_abonent_rec;
    vId    number;
    vUid   number;
    vName  varchar2(500);
    vFirst varchar2(500);
    vLast  varchar2(500);
    vPhone varchar2(100);
    vEMail varchar2(500);
    vActiv number default 0;
    vDetail varchar2(1000);
  begin
    getMethod(vUrl, vResp, vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vId    := vNode.get_Number('id');
           vUid   := vNode.get_Number('provider_uid');
           vName  := getString(vNode, 'username'); 
           vFirst := getString(vNode, 'first_name'); 
           vLast  := getString(vNode, 'last_name');
           vPhone := getString(vNode, 'phone'); 
           vEMail := getString(vNode, 'email');
           if vNode.get_Boolean('is_active') then
              vActiv := 1;
           end if; 
           vRec   := tv24_abonent_rec(vId, vName, vFirst, vLast, vPhone, vEMail, vUid, vActiv, vCode, null);
           pipe row(vRec);
       end loop; 
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_abonent_rec(null, null, null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;
  
  function setAbonentPacketPrice(pId in number, pPacket in number, pPrice in number) return tv24_package_list pipelined as
    vUrl   varchar2(100) default 'users/' || pId || '/packets?'; 
    vResp  clob;
    vCode  number;
    vBody  JSON_OBJECT_T := JSON_OBJECT_T();
    vNode  JSON_OBJECT_T;
    vRec   tv24_package_rec;
    vName  varchar2(100);
    vDesc  varchar2(2000);
    vPrice number;
    vDetail varchar2(1000);
  begin
    vBody.put('price', pPrice);
    vBody.put('packet_id', pPacket);
    postMethod(pUrl => vUrl, pText => vBody.stringify, oOut => vResp, oResult => vCode);
    if vCode = 200 then
       vNode := JSON_OBJECT_T.parse(vResp);
       vName  := getString(vNode, 'name'); 
       vDesc  := getString(vNode, 'description');
       vPrice := vNode.get_Number('price');
       vRec   := tv24_package_rec(null, null, vName, vDesc, vPrice, null, vCode, null);
       pipe row(vRec);
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_package_rec(null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end; 
  
  function getPackages return tv24_package_list pipelined as
    vUrl   varchar2(100) default 'packets?includes=availables&'; 
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
    vDetail varchar2(1000);
  begin
    getMethod(vUrl, vResp, vCode);
    if vCode = 200 then
       vList := JSON_ARRAY_T.parse(vResp);
       for ix IN 0 .. vList.get_size - 1 loop
           vNode  := TREAT(vList.get(ix) AS json_object_t);
           vPar   := vNode.get_Number('id');
           vName  := getString(vNode, 'name'); 
           vDesc  := getString(vNode, 'description');
           vPrice := vNode.get_Number('price');
           vRec   := tv24_package_rec(vPar, null, vName, vDesc, vPrice, 1, vCode, null);
           pipe row(vRec);
           vAvail := vNode.get_Array('available');
           for xi in 0 .. vAvail.get_size - 1 loop
               vNode  := TREAT(vAvail.get(xi) AS json_object_t);
               vId    := vNode.get_Number('id');
               vName  := getString(vNode, 'name'); 
               vDesc  := getString(vNode, 'description');
               vPrice := vNode.get_Number('price');
               vRec   := tv24_package_rec(vId, vPar, vName, vDesc, vPrice, 0, vCode, null);
               pipe row(vRec);
           end loop;
       end loop;
    else
       vDetail := getString(vNode, 'detail');
       vRec   := tv24_package_rec(null, null, null, null, null, null, vCode, vDetail);
       pipe row(vRec);
    end if;
    return;  
  end;

end;
/
