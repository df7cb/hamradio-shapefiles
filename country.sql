drop function if exists split_country(text,text,geometry);
drop table if exists prefix;
drop table if exists country;

-- 1A,Sov Mil Order of Malta,246,EU,15,28,41.90,-12.43,-1.0,1A;

create table country (
  cty text primary key,
  country text not null,
  official boolean,
  beam int,
  continent text not null,
  cq int not null,
  itu int not null,
  lat numeric not null,
  lon numeric not null,
  tz numeric not null,
  prefixes text not null,
  geom geometry(MultiPolygon, 4326)
);

\copy country (cty, country, beam, continent, cq, itu, lat, lon, tz, prefixes) from 'cty.csv' (format csv, delimiter ',')

update country set
  cty = regexp_replace(cty, '^\*', ''),
  official = cty !~ '^\*',
  lon = -lon,
  tz = -tz;
  --prefixes = regexp_replace(prefixes, ';$', '');

-- unofficial country
insert into country (cty, country, official, continent, cq, itu, lat, lon, tz, prefixes)
  values ('1B', 'Northern Cyprus', false, 'AS', 20, 39, 35.2, 33.6, 2, '1B');

--select '''' || string_agg(cty, ''',''') || '''' as cty from country \gset
--create type cty as enum(:cty);

create table prefix (
  exact boolean,
  prefix text,
  cty text not null references country(cty),
  official boolean,
  cq int,
  itu int
);

insert into prefix
  select m[1] is not null, m[2], cty, official, coalesce(m[3]::int, cq), coalesce(m[4]::int, itu)
  from country,
       string_to_table(prefixes, ' ') s(pfx),
       regexp_matches(pfx, '(=)?([^([;]*)(?:\((\d+)\))?(?:\[(\d+)\])?') m(m);

create index on prefix (exact, prefix);

create or replace function lookup(call text, exact out bool, cty out text, cq out int, itu out int)
  stable
  strict
  language plpgsql
as $$
begin
  select p.exact, p.cty, p.cq, p.itu into exact, cty, cq, itu
    from prefix p
    where p.exact and prefix = call
    order by official;
  if found then return; end if;

  select p.exact, p.cty, p.cq, p.itu into exact, cty, cq, itu
    from prefix p
    where not p.exact and call >= prefix
    order by prefix desc, official;
  if found then return; end if;
end;
$$;

--alter table country drop column prefixes;

cluster country using country_pkey;
