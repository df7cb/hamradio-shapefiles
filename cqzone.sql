drop table if exists cqzone;

create table cqzone (
  cq int primary key,
  ctys text[],
  geom geometry(MultiPolygon,4326)
);

insert into cqzone
  select cq, array_agg(cty), st_multi(st_union(geom))
  from country
  where cq not in (
    1, 5, -- K, VE (zones 2/3/4 are empty as by country.cq)
    17, 23, 24, -- UA9, BY
    -- 21, 37, TODO: move Socotra to 21 to 37
    34, -- contains Bir Tawil
    12, 13, 38, 39, 29, 30, 32 -- CE9, VK
  )
  group by cq;

\set newfoundland 'SRID=4326;MULTIPOLYGON(((-54.82123866832431 52.3851362350971,-60.425873767409676 49.414004375341,-55.60453706771455 40.514113940889786,-51.823096518934065 47.61782011467027,-54.82123866832431 52.3851362350971)))'

insert into cqzone
  select 1, array_agg(distinct cty), st_multi(st_union(geom))
  from (
    -- Alaska
    select cty, geom from country
    where cq = 1
    union all
    -- Yukon, Northwest Territories
    select 'VE', geom from map1
    where iso_3166_2 in ('CA-YT', 'CA-NT')
    union all
    -- Nunavut west of 102°W
    -- FIXME: some islands need more attention
    select 'VE', st_intersection(geom, 'SRID=4326;POLYGON((-140 60,-102 60,-102 85,-140 85,-140 60))')
      from map1
    where iso_3166_2 in ('CA-NU')
  ) sub;

insert into cqzone
  select 2, '{VE}', st_multi(st_union(geom))
  from (
    -- Nunavut east of 102°W
    select st_difference(geom, 'SRID=4326;POLYGON((-140 60,-102 60,-102 85,-140 85,-140 60))') as geom
      from map1
    where iso_3166_2 in ('CA-NU')
    union all
    -- Quebec north of 50°N
    select st_difference(geom, 'SRID=4326;POLYGON((-85 50,-50 50,-50 40,-85 40,-85 50))')
      from map1
    where iso_3166_2 in ('CA-QC')
    union all
    -- Labrador part of NL
    select st_difference(geom, :'newfoundland')
      from map1
    where iso_3166_2 in ('CA-NL')
  ) sub;

insert into cqzone
  select 3, '{K, VE}', st_multi(st_union(geom))
  from map1
  where iso_3166_2 in (
    'CA-BC',
    'US-WA', 'US-OR', 'US-ID', 'US-CA', 'US-NV', 'US-UT', 'US-AZ'
  );

insert into cqzone
  select 4, '{K, VE}', st_multi(st_union(geom))
  from map1
  where iso_3166_2 in (
    'CA-AB', 'CA-SK', 'CA-MB', 'CA-ON',
    'US-MT', 'US-WY', 'US-CO', 'US-NM', 'US-TX', 'US-ND', 'US-SD', 'US-NE', 'US-KS', 'US-OK', 'US-MN', 'US-IA', 'US-MO', 'US-AR', 'US-LA', 'US-WI', 'US-MI', 'US-IL', 'US-IN', 'US-OH', 'US-KY', 'US-TN', 'US-MS', 'US-AL'
  );

insert into cqzone
  select 5, array_agg(distinct cty), st_multi(st_union(geom))
  from (
    -- zone 5 except Canada and the US
    select cty, geom from country
    where cq = 5 and cty not in ('K', 'VE')
    union all
    -- zone 5 part of the US
    select 'K', geom from map1
    where iso_3166_2 in (
      'CA-NB', 'CA-NS', 'CA-PE',
      'US-CT', 'US-DC', 'US-DE', 'US-FL', 'US-GA', 'US-MA', 'US-MD', 'US-ME', 'US-NC', 'US-NH', 'US-NJ', 'US-NY', 'US-PA', 'US-RI', 'US-SC', 'US-VA', 'US-VT', 'US-WV'
    )
    union all
    -- Quebec south of 50°N
    select 'VE', st_intersection(geom, 'SRID=4326;POLYGON((-85 50,-50 50,-50 40,-85 40,-85 50))')
      from map1
    where iso_3166_2 in ('CA-QC')
    union all
    -- Newfoundland part of NL
    select 'VE', st_intersection(geom, :'newfoundland')
      from map1
    where iso_3166_2 in ('CA-NL')
  ) sub;

-- insert into cqzone
--   select 16, array_agg(distinct cty), st_multi(st_union(geom))
--   from (
--     -- zone 16 except Russia
--     select cty, geom from country
--     where cq = 16 and cty not in ('UA')
--     union all
--     -- zone 16 part of Russia
--     select 'UA', geom from map1
--     where iso_3166_2 in (
--       'RU-PSK', 'RU-KDA', 'RU-KC', 'RU-KB', 'RU-SE', 'RU-IN', 'RU-CE', 'RU-DA', 'RU-MUR', 'RU-KR', 'RU-LEN', 'RU-SMO', 'RU-BRY', 'RU-KRS', 'RU-BEL', 'RU-VOR', 'RU-ROS', 'RU-ORE', 'RU-SAR', 'RU-AST', 'RU-VGG', 'RU-NEN', 'RU-SPE', 'RU-ARK', 'RU-KL', 'RU-BA', 'RU-LIP', 'RU-TAM', 'RU-TA', 'RU-ULY', 'RU-PNZ', 'RU-ORL', 'RU-MO', 'RU-KLU', 'RU-KOS', 'RU-YAR', 'RU-VLA', 'RU-RYA', 'RU-IVA', 'RU-NIZ', 'RU-TUL', 'RU-CU', 'RU-VLG', 'RU-NGR', 'RU-TVE', 'RU-MOW', 'RU-MOS', 'RU-ME', 'RU-KIR', 'RU-UD', 'RU-SAM', 'RU-STA', 'RU-AD',
--       'UA-43', 'UA-40' /* Crimea, Sevastopol */
--     )
--   ) sub;

insert into cqzone
  select 17, array_agg(distinct cty), st_multi(st_union(geom))
  from (
    -- zone 17 except Russia
    select cty, geom from country
    where cq = 17 and cty not in ('UA9')
    union all
    -- zone 17 part of Russia
    select 'UA9', geom from map1
    where iso_3166_2 in (
      'RU-BA', 'RU-ORE', 'RU-TYU', 'RU-KGN', 'RU-OMS', 'RU-CHE', 'RU-YAN', 'RU-SVE', 'RU-KHM', 'RU-KO', 'RU-PER', 'RU-X01~' -- tiny island in Eastern RU-YAN
    )
  ) sub;

insert into cqzone
  select 18, array_agg(distinct cty), st_multi(st_union(geom))
  from (
    -- zone 18 except Russia
    select cty, geom from country
    where cq = 18 and cty not in ('UA9')
    union all
    -- zone 18 part of Russia
    select 'UA9', geom from map1
    where iso_3166_2 in (
      'RU-AL', 'RU-BU', 'RU-ZAB', 'RU-NVS', 'RU-ALT', 'RU-KYA', 'RU-TOM', 'RU-KEM', 'RU-IRK', 'RU-KK'
    )
  ) sub;

insert into cqzone
  select 19, array_agg(distinct cty), st_multi(st_union(geom))
  from (
    -- zone 19 except Russia
    select cty, geom from country
    where cq = 19 and cty not in ('UA9')
    union all
    -- zone 19 part of Russia
    select 'UA9', geom from map1
    where iso_3166_2 in (
      'RU-AMU', 'RU-YEV', 'RU-KHA', 'RU-PRI', 'RU-MAG', 'RU-SAK', 'RU-CHU', 'RU-SA', 'RU-KAM'
    )
  ) sub;

insert into cqzone
  select 23, array_agg(distinct cty), st_multi(st_union(geom))
  from (
    -- zone 23
    select cty, geom from country
    where cq = 23
    union all
    -- zone 23 part of Russia
    select 'UA9', geom from map1
    where iso_3166_2 in ('RU-TY')
    union all
    -- zone 23 part of China
    select 'BY', geom from map1
    where iso_3166_2 in ('CN-NM', 'CN-XJ', 'CN-GS', 'CN-NX', 'CN-SN', 'CN-QH', 'CN-XZ')
  ) sub;

insert into cqzone
  select 24, array_agg(distinct cty), st_multi(st_union(geom))
  from (
    -- zone 24 except China
    select cty, geom from country
    where cq = 24 and cty not in ('BY')
    union all
    -- zone 24 part of China
    select 'BY', geom from map1
    where admin = 'China' and iso_3166_2 not in ('CN-NM', 'CN-XJ', 'CN-GS', 'CN-NX', 'CN-SN', 'CN-QH', 'CN-XZ')
  ) sub;

insert into cqzone
  select 34, array_agg(distinct cty), st_multi(st_union(geom))
  from (
    -- zone 34
    select cty, geom from country
    where cq = 34
    union all
    -- Bir Tawil, the world's only nowhere land
    select 'ST', geom from map0 where name = 'Bir Tawil'
  ) sub;

--delete from cqzone where cq in (12, 13, 38, 39, 29, 30, 32);
insert into cqzone
  select z.cq, array_agg(distinct cty), st_multi(st_union(sub.geom))
  from (values
    (12, 'SRID=4326;POLYGON((-120 -90,-120 -60,-65 -60,-65 -90,-120 -90))'::geometry),
    (13, 'SRID=4326;POLYGON((-65 -90,-65 -60,-25 -60,-25 -90,-65 -90))'),
    (38, 'SRID=4326;POLYGON((-25 -90,-25 -60,35 -60,35 -90,-25 -90))'),
    (39, 'SRID=4326;POLYGON((35 -90,35 -60,90 -60,90 -90,35 -90))'),
    (29, 'SRID=4326;POLYGON((90 -90,90 -60,129 -60,129 -90,90 -90))'),
    (30, 'SRID=4326;POLYGON((129 -90,129 -60,171 -60,171 -90,129 -90))'),
    (32, 'SRID=4326;MULTIPOLYGON(((-180 -90,-180 -60,-120 -60,-120 -90,-180 -90)),((171 -90,171 -60,180 -60,180 -90,171 -90)))')
  ) z(cq, geom),
  lateral (
    -- zone except CE9
    select cty, c.geom from country c
    where c.cq = z.cq and cty not in ('CE9', 'VK')
    union all
    -- zone part of CE9
    select 'CE9', st_intersection(c.geom, z.geom)
    from country c where cty = 'CE9'
    union all
    -- zone part of VK
    select 'VK', m.geom
    from map1 m
    where case z.cq
      when 29 then iso_3166_2 in ('AU-WA', 'AU-NT', 'AU-X04~') -- Ashmore
      when 30 then iso_3166_2 in ('AU-QLD', 'AU-SA', 'AU-NSW', 'AU-ACT', 'AU-VIC', 'AU-TAS', 'AU-X02~') -- Jervis Bay Territory
    end
  ) sub
  group by z.cq;

create index if not exists cqzone_geom_idx on cqzone using gist (geom);
