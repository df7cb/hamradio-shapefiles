#!/bin/sh

PSQL="psql -X -vON_ERROR_STOP=1"
SHP2PGSQL="shp2pgsql -s 4326 -D -I"
PG_DUMP="pg_dump --data-only --column-inserts --on-conflict-do-nothing --no-owner"

set -eux

export PGDATABASE=country

dropdb --if-exists --force $PGDATABASE
createdb $PGDATABASE

$PSQL -f extensions.sql
$PSQL -f country.sql

$PSQL -c 'drop table if exists map0, map1'
$SHP2PGSQL -s 4326 -D -I ne_10m_admin_0_map_subunits/ne_10m_admin_0_map_subunits map0 | $PSQL
$SHP2PGSQL -s 4326 -D -I ne_10m_admin_1_states_provinces_lakes/ne_10m_admin_1_states_provinces_lakes map1 | sed -e 's/varchar(0)/varchar(1)/' | $PSQL
# FEHLER:  22023: Länge von Typ varchar muss mindestens 1 sein
# ZEILE 90: "fclass_iso" varchar(0),

$PSQL -f country.sql
$PSQL -f locator.sql

$PSQL -f map.sql
$PSQL -f map-qa.sql

$PSQL -f cqzone.sql
$PSQL -f cqzone-qa.sql

$PSQL -f ituzone.sql
$PSQL -f ituzone-qa.sql

$PSQL -f wrapup.sql

# shapefile output
for table in country cqzone ituzone; do
  rm -rf $table $table.zip
  mkdir $table
  pgsql2shp -f $table/$table country $table
  ( cd $table && zip ../$table.zip * )
done

# "insert on conflict" output
(
  $PG_DUMP -t country \
    | sed -e 's/DO NOTHING/(cty) do update set country=excluded.country, official=excluded.official, beam=excluded.beam, cq=excluded.cq, itu=excluded.itu, lat=excluded.lat, lon=excluded.lon, tz=excluded.tz, prefixes=excluded.prefixes, geom=excluded.geom/'
  echo "cluster public.country using country_pkey;"
) | gzip -9 > country-load.sql.gz

for i in cq itu; do
(
  $PG_DUMP -t ${i}zone \
    | sed -e "s/DO NOTHING/($i) do update set ctys=excluded.ctys, geom=excluded.geom/"
  echo "cluster public.${i}zone using ${i}zone_pkey;"
) | gzip -9 > ${i}zone-load.sql.gz
done
