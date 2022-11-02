create sequence TV24_ACCOUNTS_SEQ;

create table TV24_ACCOUNTS (
  ID         NUMBER                     NOT NULL,
  PHONE      VARCHAR2(100)              NOT NULL
);

create unique index TV24_ACCOUNTS_PK on TV24_ACCOUNTS(ID);

create index TV24_ACCOUNTS_IX on TV24_ACCOUNTS(PHONE);

alter table TV24_ACCOUNTS add (
  constraint TV24_ACCOUNTS_PK primary key (ID));

create sequence TV24_CHARGES_SEQ;

create table TV24_CHARGES (
  ID         NUMBER                     NOT NULL,
  ACC_ID     NUMBER                     NOT NULL,
  VAL        NUMBER                     NOT NULL,
  TARIFF     VARCHAR2(1000),
  START_DATE DATE                       NOT NULL
);

create unique index TV24_CHARGES_PK on TV24_CHARGES(ID);

create index TV24_CHARGES_FK on TV24_CHARGES(ACC_ID);

alter table TV24_CHARGES add (
  constraint TV24_CHARGES_PK primary key (ID));

alter table TV24_CHARGES add
  constraint TV24_CHARGES_FK foreign key (ACC_ID) 
    references TV24_ACCOUNTS(id);
