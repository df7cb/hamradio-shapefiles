update country set geom = null where geom is not null;

-- build countries from pieces from map1 --------------------------------------

drop table if exists import_map1;
create table import_map1 (country text, from_map1 text[]);

insert into import_map1 values
  -- Greece
  ('Crete', array['Kriti']),
  ('Mount Athos', array['Ayion Oros']),
  -- Caribbean Netherlands
  ('Bonaire', array['Bonaire']),
  ('Saba & St. Eustatius', array['Saba', 'St. Eustatius']),
  -- Fr. S. Antarctic Lands
  ('Amsterdam & St. Paul Is.', array['Iles Saint-Paul et Nouvelle-Amsterdam']),
  ('Crozet Island', array['Archipel des Crozet']),
  ('Kerguelen Islands', array['Archipel des Kerguelen']),
  -- Coral Sea Islands are actually a lot of islands besides Willis
  ('Willis Island', array['Coral Sea Islands']),
  --
  ('Crozet Island', array['Archipel des Crozet'])
  ;

update country set geom =
  (select st_multi(st_union(geom)) from map1 where name = any(from_map1))
  from import_map1
  where country.country = import_map1.country;

-- Greece
update country set geom =
  (select st_multi(st_union(geom)) from map1
    where iso_a2 = 'GR' and name not in ('Kriti', 'Ayion Oros'))
  where country = 'Greece';

-- Russia
update country set geom =
  (select st_multi(st_union(geom)) from map1
    where iso_a2 = 'RU' and region in ('Northwestern', 'Central', 'Volga')
          and name not in ('Kaliningrad', 'Bashkortostan', 'Komi', 'Orenburg', 'Perm', 'Perm'''))
  where country = 'European Russia';
update country set geom =
  (select st_multi(st_union(geom)) from map1
    where iso_a2 = 'RU' and (region not in ('Northwestern', 'Central', 'Volga')
          or name in ('Bashkortostan', 'Komi', 'Orenburg', 'Perm', 'Perm''')))
  where country = 'Asiatic Russia';

-- build countries from pieces from map0 --------------------------------------

drop table if exists join_country;
create table join_country (country text, from_ctys text[]);

insert into join_country values
  ('African Italy', array['Isole Pelagie', 'Pantelleria']),
  ('Andaman & Nicobar Is.', array['Andaman Is.', 'Nicobar Is.']),
  ('Antigua & Barbuda', array['Antigua', 'Barbuda']),
  ('Australia', array['Australia', 'Tasmania', 'Ashmore and Cartier Is.' /*, treated as Willis Island: 'Coral Sea Islands'*/]),
  ('Baker & Howland Islands', array['Baker I.', 'Howland I.']),
  ('Brazil', array['Brazil', 'Brazilian I.']),
  ('Ceuta & Melilla', array['Ceuta', 'Melilla']),
  ('Chagos Islands', array['Diego Garcia NSF', 'Br. Indian Ocean Ter.']),
  ('China', array['China', 'Hainan', 'Paracel Is.']),
  ('Cyprus', array['Cyprus', 'Cyprus U.N. Buffer Zone']),
  ('Denmark', array['Denmark', 'Bornholm']),
  ('Equatorial Guinea', array['Bioko', 'Río Muni']),
  ('Georgia', array['Georgia', 'Adjara']),
  ('Guernsey', array['Guernsey', 'Alderney', 'Herm', 'Sark']),
  ('India', array['India', 'Siachen Glacier']),
  ('Iraq', array['Iraq', 'Iraqi Kurdistan']),
  ('Palmyra & Jarvis Islands', array['Palmyra Atoll', 'Jarvis I.', 'Kingman Reef']), -- Kingman Reef removed as DXCC entity in 2016
  ('Ogasawara', array['Bonin Is.', 'Volcano Is.']), -- Japanese islands
  ('Juan de Nova & Europa', array['Juan De Nova I.', 'Europa Island', 'Bassas da India']), -- unclear if Bassas da India belongs here
  ('New Zealand', array['North I.', 'South I.']),
  ('DPR of Korea', array['North Korea', 'Korean DMZ (north)']),
  ('Kazakhstan', array['Kazakhstan', 'Baikonur']),
  ('Republic of Korea', array['South Korea', 'Baengnyeongdo', 'Dokdo', 'Jejudo', 'Ulleungdo', 'Korean DMZ (south)']),
  ('Palestine', array['Gaza', 'West Bank']),
  ('Papua New Guinea', array['Papua New Guinea', 'Bougainville']), -- Bougainville is an autonomous province without assigned prefix
  ('Syria', array['Syria', 'UNDOF Zone']),
  ('Serbia', array['Serbia', 'Vojvodina']),
  ('Tanzania', array['Tanzania', 'Zanzibar']),
  ('Trinidad & Tobago', array['Trinidad', 'Tobago']),
  ('UK Base Areas on Cyprus', array['Akrotiri', 'Dhekelia']),
  ('Yemen', array['Yemen', 'Socotra']);

update country set geom =
  (select st_multi(st_union(geom)) from map0 where name = any(from_ctys))
  from join_country
  where country.country = join_country.country;

drop table if exists join_sovereignt;
create table join_sovereignt (country text, from_sovts text[]);

insert into join_sovereignt values
  ('Belgium', array['Belgium']),
  ('Bosnia-Herzegovina', array['Bosnia and Herzegovina']),
  ('Timor - Leste', array['East Timor']),
  ('Sao Tome & Principe', array['São Tomé and Principe']),
  ('Somalia', array['Somalia', 'Somaliland']);

update country set geom =
  (select st_multi(st_union(geom)) from map0 where sovereignt = any(from_sovts))
  from join_sovereignt
  where country.country = join_sovereignt.country;

update country set geom =
  (select st_multi(st_union(geom)) from map0 where sovereignt = 'Japan' and name not in ('Bonin Is.', 'Volcano Is.'))
  where country.country = 'Japan';

-- import countries from map0 -------------------------------------------------

update country
  set geom = map0.geom
  from map0
  where regexp_replace(country.country, ' Islands?', '')
      = replace(regexp_replace(map0.name, ' (Is?\.|Islands?)', ''), ' and ', ' & ')
    and country.geom is null;

-- import to-be-renamed countries from map0
drop table if exists rename;
create table rename (rename_to text, rename_from text);

insert into rename values
  -- simple renames
  ('Aland Islands', 'Åland'),
  ('Annobon Island', 'Annobón'),
  ('Brunei Darussalam', 'Brunei'),
  ('Cape Verde', 'Cabo Verde'),
  ('Central African Republic', 'Central African Rep.'),
  ('Cocos (Keeling) Islands', 'Cocos Is.'),
  ('Cote d''Ivoire', 'Côte d''Ivoire'),
  ('Curacao', 'Curaçao'),
  ('Czech Republic', 'Czechia'),
  ('Dem. Rep. of the Congo', 'Dem. Rep. Congo'),
  ('Dominican Republic', 'Dominican Rep.'),
  ('Faroe Islands', 'Faeroe Is.'),
  ('Fed. Rep. of Germany', 'Germany'),
  ('French Polynesia', 'Fr. Polynesia'),
  ('Galapagos Islands', 'Galápagos Is.'),
  ('Guantanamo Bay', 'USNB Guantanamo Bay'),
  ('Heard Island', 'Heard I. and McDonald Is.'),
  ('Johnston Island', 'Johnston Atoll'),
  ('Kingdom of Eswatini', 'eSwatini'),
  ('Mariana Islands', 'N. Mariana Is.'),
  ('Northern Cyprus', 'N. Cyprus'),
  ('Northern Ireland', 'N. Ireland'),
  ('N.Z. Subantarctic Is.', 'N.Z. SubAntarctic Is.'),
  ('Peter 1 Island', 'Peter I I.'),
  ('Pr. Edward & Marion Is.', 'Prince Edward Is.'),
  ('Republic of Kosovo', 'Kosovo'),
  ('Republic of South Sudan', 'S. Sudan'),
  ('Republic of the Congo', 'Congo'),
  ('Reunion Island', 'Réunion'),
  ('Slovak Republic', 'Slovakia'),
  ('South Georgia Island', 'S. Georgia'),
  ('South Orkney Islands', 'S. Orkney Is.'),
  ('South Sandwich Islands', 'S. Sandwich Is.'),
  ('St. Barthelemy', 'St-Barthélemy'),
  ('St. Lucia', 'Saint Lucia'),
  ('St. Martin', 'St-Martin'),
  ('St. Vincent', 'St. Vin. and Gren.'),
  ('The Gambia', 'Gambia'),
  ('Timor - Leste', 'Timor-Leste'),
  ('Tristan da Cunha & Gough Islands', 'Tristan da Cunha'),
  ('United States', 'United States of America'),
  ('US Virgin Islands', 'U.S. Virgin Is.'),
  ('Vatican City', 'Vatican'),
  ('Wake Island', 'Wake Atoll'),
  ('Western Sahara', 'W. Sahara'),

  -- countries split further below
  ('Asiatic Turkey', 'Turkey'),
  ('East Malaysia', 'Malaysia'),
  ('Eastern Kiribati', 'Kiribati'),
  ('North Cook Islands', 'Cook Is.');

update country
  set geom = map0.geom
  from map0 join rename on map0.name = rename_from
  where country.country = rename_to and country.geom is null;

create or replace function split_country(old_cty text, new_cty text, selector geometry)
  returns void
  begin atomic
    with parts as (select d.geom as part from country, st_dump(geom) d where country = old_cty),
    new_part as (select st_multi(st_union(part)) as geom from parts where st_intersects(part, selector)),
    old_part as (select st_multi(st_union(part)) as geom from parts where not st_intersects(part, selector)),
    update_new_part as
      (update country set geom = new_part.geom from new_part where country = new_cty)
       update country set geom = old_part.geom from old_part where country = old_cty;
  end;

-- Countries
select split_country('East Malaysia', 'West Malaysia', st_setsrid('Polygon((90 0,108 0,108 10,90 10,90 0))'::geometry, 4326));
select split_country('Asiatic Turkey', 'European Turkey', st_collect(st_locator('KN20'), st_locator('KN31')));

-- Islands
select split_country('American Samoa', 'Swains Island', ST_Locator('AH48'));
select split_country('Antarctica', 'South Shetland Islands', ST_SetSRID('POLYGON((-63 -64,-52 -61,-54 -60,-64 -63,-63 -64))'::geometry, 4326));
select split_country('Australia', 'Lord Howe Island', ST_Locator('QF98'));
select split_country('Brazil', 'St. Peter & St. Paul', ST_Locator('HJ50'));
select split_country('Brazil', 'Fernando de Noronha', ST_SetSRID('POLYGON((-33 -4,-32 -4,-32 -3,-33 -3,-33 -4))'::geometry, 4326));
select split_country('Brazil', 'Trindade & Martim Vaz', ST_Locator('HG59'));
select split_country('Canada', 'Sable Island', ST_Locator('GN03'));
select split_country('Colombia', 'Malpelo Island', ST_Locator('EJ'));
select split_country('North Cook Islands', 'South Cook Islands', ST_SetSRID('POLYGON((-162 -17,-162 -24,-154 -24,-154 -17,-162 -17))'::geometry, 4326));
select split_country('Costa Rica', 'Cocos Island', ST_Locator('EJ65'));
select split_country('Greece', 'Dodecanese', ST_SetSRID('POLYGON((26.2 35.4,30 35.4,30 37.5,26.2 37.5,26.2 35.4))'::geometry, 4326));
select split_country('Fiji', 'Rotuma Island', ST_Locator('RH87'));
select split_country('Fiji', 'Conway Reef', ST_Locator('RG78'));
select split_country('French Polynesia', 'Austral Islands', ST_SetSRID('POLYGON((-141 -27,-152 -18,-157 -23,-143 -31,-141 -27))'::geometry, 4326));
select split_country('French Polynesia', 'Marquesas Islands', ST_SetSRID('POLYGON((-145 -12,-130 -12,-130 -5,-145 -5,-145 -12))'::geometry, 4326));
select split_country('Hawaii', 'Kure Island', ST_Locator('AL08'));
select split_country('Japan', 'Minami Torishima', ST_Locator('QL64'));
select split_country('Eastern Kiribati', 'Banaba Island', ST_Locator('RI49'));
select split_country('Eastern Kiribati', 'Western Kiribati', ST_Collect(ST_Locator('RI'), ST_Locator('RJ')));
select split_country('Eastern Kiribati', 'Central Kiribati', ST_Locator('AI'));
select split_country('Mauritius', 'Agalega & St. Brandon', ST_Collect(ST_Locator('LH89'), ST_Locator('LH93'))); -- St. Brandon is not present in NE
select split_country('Mauritius', 'Rodriguez Island', ST_Locator('MH10'));
select split_country('Mexico', 'Revillagigedo', ST_Collect(ST_Collect(ST_Locator('DK28'), ST_Locator('DK48')), ST_Locator('DK49'))); -- Roca Partida is not present in NE
select split_country('Pitcairn Island', 'Ducie Island', ST_Locator('CG75'));
select split_country('European Russia', 'Franz Josef Land', ST_SetSRID('POLYGON((35 79,70 79,70 83,35 83,35 79))'::geometry, 4326));
select split_country('Scotland', 'Shetland Islands', ST_Collect(ST_Collect(ST_Locator('IO99'), ST_Locator('IP90')), ST_Locator('IP80')));
select split_country('Solomon Islands', 'Temotu Province', ST_SetSRID('POLYGON((164 -13,171 -13,171 -8,164 -8,164 -13))'::geometry, 4326));
select split_country('Svalbard', 'Bear Island', ST_Locator('JQ94'));
select split_country('Venezuela', 'Aves Island', ST_Locator('FK85'));

-- Split San Andres & Providencia off Colombia, and then join Bajo Nuevo Bank and Serranilla Bank to it
select split_country('Colombia', 'San Andres & Providencia', ST_Collect(ST_Locator('EK92'), ST_Locator('EK93')));
update country set geom = st_union(geom, (select st_union(geom) from map0 where name in ('Bajo Nuevo Bank', 'Serranilla Bank')))
  where country = 'San Andres & Providencia';

-- Chilean islands
update country set geom = (select st_intersection(geom, st_setsrid('MultiPolygon(((-82 -22.75,-80.5 -30.25,-76 -26,-82 -22.75)))'::geometry, 4326)) from map1 where name = 'Valparaíso')
  where country = 'San Felix & San Ambrosio';
update country set geom = (select st_intersection(geom, st_setsrid('MultiPolygon(((-75 -29.625,-77 -40,-86.5 -32.75,-75 -29.625)))'::geometry, 4326)) from map1 where name = 'Valparaíso')
  where country = 'Juan Fernandez Islands';

-- Countries not present in source data ---------------------------------------

/*
 * Not present in cty.csv:
 * N. Cyprus
 *
 * Not present in Natural Earth:
 * Chesterfield Islands (QH90)
 * Desecheo Island (FK68GJ)
 * Market Reef (JP90NH)
 * Mellish Reef (QH72)
 * Pratas Island
 * St. Paul Island (FN97WE)
 * Willis Island (QH43XR)
 */

-- islands
update country set geom = 'MultiPolygon(((158.6171875 -20.125,159.140625 -19.46875,159.25 -19.15625,159.2265625 -19.015625,159.0625 -18.796875,158.9375 -18.734375,158.3203125 -18.84375,158.15625 -19,157.9765625 -19.609375,158.0078125 -19.765625,158.1796875 -20.046875,158.4609375 -20.1875,158.6171875 -20.125)))'
  where country = 'Chesterfield Islands';

update country set geom = 'MultiPolygon(((-67.48779296875 18.3848876953125,-67.48486328125 18.3885498046875,-67.48046875 18.389892578125,-67.47265625 18.3831787109375,-67.47705078125 18.377685546875,-67.48583984375 18.380615234375,-67.48779296875 18.3848876953125)))'
  where country = 'Desecheo Island';

update country set geom = 'MultiPolygon(((19.1294 60.302,19.1297 60.3008,19.1312 60.3001,19.1355 60.2999,19.1351 60.300700000000006,19.1294 60.302)))'
  where country = 'Market Reef';

update country set geom = 'MultiPolygon(((155.8360595703125 -17.34912109375,155.85205078125 -17.343994140625,155.8792724609375 -17.3817138671875,155.8836669921875 -17.4007568359375,155.8675537109375 -17.4385986328125,155.8543701171875 -17.4427490234375,155.8525390625 -17.41796875,155.86181640625 -17.401123046875,155.8421630859375 -17.372802734375,155.8360595703125 -17.34912109375)))'
  where country = 'Mellish Reef';

update country set geom = 'MultiPolygon(((116.71142578125 20.7109375,116.73486328125 20.7021484375,116.7333984375 20.6962890625,116.7099609375 20.7021484375,116.71142578125 20.7109375)))'
  where country = 'Pratas Island';

update country set geom = 'MultiPolygon(((-60.138671875 47.2265625,-60.166015625 47.197265625,-60.1640625 47.1875,-60.158203125 47.181640625,-60.14453125 47.189453125,-60.134765625 47.20703125,-60.138671875 47.2265625)))'
  where country = 'St. Paul Island';

-- buildings
\set geom 'SRID=4326;MultiPolygon(((12.47760009765625 41.88330078125,12.47735595703125 41.88330078125,12.47723388671875 41.88330078125,12.47747802734375 41.883544921875,12.47760009765625 41.88330078125)),((12.480712890625 41.905517578125,12.4808349609375 41.9052734375,12.48052978515625 41.905029296875,12.4803466796875 41.9052734375,12.480712890625 41.905517578125)))'
update country set geom = :'geom' where country = 'Sov Mil Order of Malta';
update country set geom = st_difference(geom, :'geom') where country = 'Italy';

\set geom 'SRID=4326;MultiPolygon(((6.137939453125 46.221923828125,6.1396484375 46.221435546875,6.13720703125 46.2197265625,6.13623046875 46.220458984375,6.137939453125 46.221923828125)))'
update country set geom = :'geom' where country = 'ITU HQ';
update country set geom = st_multi(st_difference(geom, :'geom')) where country = 'Switzerland';

\set geom 'SRID=4326;MULTIPOLYGON(((-73.966796875 40.752197265625,-73.96435546875 40.751220703125,-73.966796875 40.74755859375,-73.96923828125 40.748779296875,-73.966796875 40.752197265625)))'
update country set geom = :'geom' where country = 'United Nations HQ';
update country set geom = st_difference(geom, :'geom') where country = 'United States';

\set geom 'SRID=4326;MULTIPOLYGON(((16.414306640625 48.236328125,16.4154052734375 48.237060546875,16.41650390625 48.237060546875,16.419921875 48.23486328125,16.4168701171875 48.23291015625,16.414794921875 48.233154296875,16.4140625 48.23388671875,16.4158935546875 48.23486328125,16.414306640625 48.236328125)))'
update country set geom = :'geom' where country = 'Vienna Intl Ctr';
update country set geom = st_multi(st_difference(geom, :'geom')) where country = 'Austria';

create index if not exists country_geom_idx on country using gist (geom);
