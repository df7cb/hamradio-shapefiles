-- helper table checks: map1

select * from import_map1 where country not in (select country from country);
select * from import_map1, unnest(from_map1) u(part) where part not in (select name from map1);

-- helper table checks: map0

select * from join_country where country not in (select country from country);
select * from join_country, unnest(from_ctys) u(part) where part not in (select name from map0);

select * from join_sovereignt where country not in (select country from country);
select * from join_sovereignt, unnest(from_sovts) u(part) where part not in (select sovereignt from map0);

\pset title 'To-be-renamed countries missing in country'
select rename_to as "missing in country.cty" from rename
  where not exists (select from country where country.country = rename.rename_to);

\pset title 'To-be-renamed countries missing in map0'

select rename_from as "missing in map0.name" from rename
  where not exists (select from map0 where map0.name = rename.rename_from);

-- general QA

\pset title 'Countries from map0 not in any country.geom (expected: Southern Patagonian Ice Field, Bir Tawil)'

select name from map0 m where not exists (select from country c where st_intersects(st_buffer(m.geom, -0.0001), c.geom));

\pset title 'Countries from map1 not in any country.geom'

select name, admin from map1 m where not exists (select from country c where st_intersects(st_buffer(m.geom, -0.0001), c.geom));

\pset title 'Overlapping countries'

with c as (select cty, country, st_buffer(geom, -0.0001) as geom from country)
  select c1.cty, c1.country, c2.cty, c2.country from c c1, c c2
    where st_intersects(c1.geom, c2.geom) and c1.cty < c2.cty;

