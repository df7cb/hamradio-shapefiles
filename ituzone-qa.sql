\pset title 'Countries not in any ituzone.ctys'

select cty from country where cty not in (select unnest(ctys) from ituzone);

\pset title 'Countries from map0 not in any ituzone.geom (expected: Southern Patagonian Ice Field, Bir Tawil)'

select name from map0 m where not exists (select from ituzone c where st_intersects(st_buffer(m.geom, -0.0001), c.geom));

\pset title 'Entities from map1 not in any ituzone.geom'

select name, admin from map1 m where not exists (select from ituzone c where st_intersects(st_buffer(m.geom, -0.0001), c.geom));

\pset title 'Overlapping zones'

with c as (select itu, st_buffer(geom, -0.0001) as geom from ituzone)
  select c1.itu, c2.itu from c c1, c c2
    where st_intersects(c1.geom, c2.geom) and c1.itu < c2.itu;

