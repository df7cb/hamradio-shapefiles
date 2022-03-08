drop table if exists ituzone;

create table ituzone (
  itu int primary key,
  ctys text[],
  geom geometry(MultiPolygon,4326)
);

delete from ituzone;

-- Zones with countries that span several zones and need clipping
insert into ituzone
  select z.itu, array_agg(distinct cty), st_multi(st_union(sub.geom))
  from (values
    (1, st_union(box(-180, -141, 50, 80), box(170, 180, 50, 80)), array['KL']::text[]),
    (2, box(-141, -110, 40, 80), array['KL', 'VE']),
    (3, box(-110, -90, 40, 80), array['VE']),
    (4, st_union(box(-90, -70, 40, 80), box(-70, -50, 61.1, 80)), array['VE']),
    (5, box(-75, -10, 55, 80), array['OX']),
    (6, st_difference(box(-130, -110, 30, 50), (select geom from map1 where name = 'Wyoming')), array['K']),
    (7, st_union(box(-110, -90, 20, 50), (select geom from map1 where name = 'Wyoming')), array['K']),
    (8, box(-90, -60, 20, 50), '{K, 4U1U}'),
    (9, box(-70, -45, 40, 61.1), '{CY0, CY9, FP, VE}'),
    (12, box(-95, -50, -20, 15), array['FY', 'HC', 'HC8', 'HK', 'HK0/m', 'OA', 'PZ', 'YV', '8R']), -- full countries in zone 12
    (12, box(-95, -60, -16.5, 15), array['CP', 'PY']), -- clipped countries in zone 12
    (13, box(-60, -25, -16.5, 5), '{PY, PY0F, PY0S}'),
    (14, box(-95, -50, -40, -16.5), array['CE', 'CE0X', 'CE0Z', 'CP', 'CX', 'LU', 'ZP']),
    (15, box(-60, -25, -40, -16.5), array['PY', 'PY0T']),
    (16, box(-80, -55, -60, -40), null),
    (18, box(-10, 32, 50, 80), array['JW', 'JX', 'JW/b', 'LA', 'OH', 'OH0', 'OJ0', 'OY', 'OZ', 'SM']),
    (19, box(20, 50, 60, 80), array['UA', 'UA9']),
      (29, box(15, 50, 30, 60), array['EK', 'ER', 'ES', 'EU', 'LY', 'UA', 'UA2', 'UA9', 'UN', 'UR', 'YL', '4J', '4L']),
    (20, box(50, 75, 60, 80), null),
      (30, box(50, 75, 30, 60), array['EX', 'EY', 'EZ', 'UA', 'UA9', 'UK', 'UN']),
    (21, box(75, 90, 60, 80), null),
      (31, box(75, 90, 30, 60), array['EX', 'UA9', 'UN']),
    (22, box(90, 110, 60, 80), null),
      (32, box(80, 110, 30, 60), array['JT']),
      (32, box(90, 110, 30, 60), array['UA9']),
    (23, box(110, 135, 60, 80), null),
      (33, box(110, 135, 44, 60), array['BY']),
      (33, box(110, 135, 30, 60), array['JT', 'UA9']),
    (24, box(135, 155, 60, 80), null),
      (34, 'SRID=4326;POLYGON((135 60,158.5 60,135 36.5,135 60))', array['UA9']),
    (25, box(155, 170, 60, 80), null),
      (35, 'SRID=4326;POLYGON((157 60,142 41,171 47,171 60,157 60))', array['UA9']),
    (26, box(170, 180, 60, 80), null),
    (26, box(-180, -170, 60, 80), array['UA9']),
    (42, box(70, 90, 20, 50), '{BY, 9N}'),
    (43, box(90, 110, 20.2, 50), '{BY}'),
    (44, box(110, 140, 10, 44), '{BV, BY, BV9P, HL, P5, VR, XX9}'),
    (44, box(90, 140, 10, 20.2), '{BY}'), -- Hainan Island
    (47, box(5, 30, 0, 30), '{ST, S9, TJ, TL, TT, Z8, 3C}'),
    (48, box(30, 62, -10, 30), '{ET, E3, J2, ST, T5, Z8, 5Z}'), -- TODO: Socatra and Abd al Kuri islands
    (48, box(25, 62, -10, 30), '{5X}'),
    (51, box(130, 170, -15, 5), '{H4, H40, P2, YB}'),
    (54, box(90, 130, -15, 20), '{V8, VK9C, VK9X, YB, 4W, 9M2, 9M6, 9V}'),
    -- TODO:
    -- 61: Palmyra Island – but not Jarvis Island
    --     Eastern Kiribati – Northern Line Is. only
    -- 62: Jarvis Island – but not Palmyra Island
    -- 63: Easter Island – but not Salas y Gomez Island
    --     Eastern Kiribati – Central and Southern Line Is. only
    (64, box(130, 150, 2, 22), null),
    (65, box(150, 180, -10, 22), '{C2, KH9, T2, T30, T33, V6, V7}'),
    (67, box(-20, 40, -80, -50), null),
    (69, box(40, 100, -80, -60), null),
    (70, box(100, 160, -80, -60), null),
    (71, box(160, 180, -80, -60), null),
    (71, box(-180, -140, -80, -60), null),
    (72, box(-140, -80, -80, -60), null),
    (73, box(-55, -20, -60, -50), null),
    (73, box(-80, -20, -80, -60), null),
    (74, box(-180, 180, -90, -80), null),
    (75, box(-180, 180, 80, 90), null)
  ) z(itu, boundary, ctys),
  lateral (
    select cty, st_intersection(c.geom, boundary) as geom from country c
    where st_intersects(c.geom, boundary)
      and case when z.ctys is not null then c.cty = any(z.ctys) else true end
  ) sub
  group by z.itu;

-- Australia
insert into ituzone
  select itu, ctys, st_multi(st_union(geom))
  from (values
    (55, '{VK, VK9W}'::text[], '{Northern Territory, Queensland, Coral Sea Islands}'::text[]),
    (58, '{VK}', '{Western Australia, Ashmore and Cartier Islands}'),
    (59, '{VK}', '{South Australia, New South Wales, Australian Capital Territory, Jervis Bay Territory, Victoria, Tasmania}')
  ) z(itu, ctys, names),
  lateral (
    select geom from map1 where name = any(z.names)
      and admin <> 'Malta' -- there is a Victoria on Malta
  ) sub
  group by itu, ctys;

-- Zones with only countries that don't need clipping
insert into ituzone
  select itu, array_agg(cty), st_multi(st_union(geom))
  from country
  where itu not in (select itu from ituzone)
  group by itu;

create index if not exists ituzone_geom_idx on ituzone using gist (geom);
