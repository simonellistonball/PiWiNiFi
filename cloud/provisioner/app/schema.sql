drop table if exists devices;
create table devices (
  id char(32),
  mac char(12),
  name varchar(50),
  keystorePasswd varchar(32),
  truststorePasswd varchar(32),
  keyPasswd varchar(32),
  trustStore blob,
  clientKeystore blob,
  serverKeystore blob,
  primary key (id)
)
