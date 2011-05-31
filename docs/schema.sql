create table `accounts` (
   `id` int unsigned not null auto_increment primary key,
   `name` varchar(40) character set latin1 not null,
   `password_sha` varchar(60) default null,
   `api_key` varchar(32),
   `api_secret` varchar(32),
   unique key (`name`),
   unique key (`api_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

alter table records charset = utf8;
alter table domains set default charset = utf8;

insert ignore into accounts (name) select distinct account from domains where account is not null;
alter table domains add key (`account`);
alter table domains
  add constraint foreign key (`account`) references accounts (`name`) on delete cascade;

alter table domains
  add cas  varchar(10) not null default '';
update domains set cas = SUBSTRING( RAND(), 3, 10 );

