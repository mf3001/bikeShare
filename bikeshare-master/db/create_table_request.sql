create table requests
  (
    rid serial,
    uid integer not null,
    ownerid integer not null,
    bid integer not null,
    status varchar(25) default 'pending',
    from_date TIMESTAMPTZ NOT NULL,
    to_date TIMESTAMPTZ NOT NULL,

    primary key(rid),
    foreign key(uid) references users,
    foreign key(ownerid) references users,
    foreign key(bid) references bikes
  )