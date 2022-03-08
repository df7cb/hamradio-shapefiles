\pset title 'Countries not in any cqzone.ctys'

select cty from country where cty not in (select unnest(ctys) from cqzone);

\pset title 'Countries from map0 not in any cqzone.geom (expected: Southern Patagonian Ice Field)'

select name from map0 m where not exists (select from cqzone c where st_intersects(st_buffer(m.geom, -0.0001), c.geom));

\pset title 'Entities from map1 not in any cqzone.geom'

select name, admin from map1 m where not exists (select from cqzone c where st_intersects(st_buffer(m.geom, -0.0001), c.geom));

\pset title 'Overlapping zones'

with c as (select cq, st_buffer(geom, -0.0001) as geom from cqzone)
  select c1.cq, c2.cq from c c1, c c2
    where st_intersects(c1.geom, c2.geom) and c1.cq < c2.cq;

