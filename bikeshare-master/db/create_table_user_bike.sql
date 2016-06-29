CREATE TABLE users
  (uid SERIAL,
   username VARCHAR(25) NOT NULL,
   password VARCHAR(25) NOT NULL,
   firstname VARCHAR(255),
   lastname VARCHAR(255),
   email VARCHAR(255) NOT NULL,
   creationDate TIMESTAMPTZ NOT NULL,

   PRIMARY KEY(uid),
   UNIQUE(username),
   UNIQUE(email)
  );

create table bikes
  (
    bid serial,
    uid integer not null,
    model varchar(255) not null,
    status boolean default true,
    price numeric,
    location varchar(255),
    details text,

    primary key(bid),
    foreign key(uid) references users
  )

alter table bikes
  add column address varchar(255),
  add column state varchar(50),
  add column city varchar(255),
  add column postcode varchar(20),
  add column country varchar(50),
  add column lon numeric,
  add column lat numeric

CREATE EXTENSION cube;
CREATE EXTENSION earthdistance;

create table bike_photos
  (
    bid integer,
    pid serial,
    url varchar(255),
    status boolean default true,

    primary key(pid),
    foreign key(bid) references bikes
  )