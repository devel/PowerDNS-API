create table `accounts` (
   `id` int unsigned not null auto_increment primary key,
   `name` varchar(40) not null,
   `password_sha` varchar(60) default null,
   `api_key` varchar(32),
   `api_secret` varchar(32),
   unique key (`name`),
   unique key (`api_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

