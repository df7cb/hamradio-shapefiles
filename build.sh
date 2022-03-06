#!/bin/sh

PSQL="psql -X -vON_ERROR_STOP=1"
SHP2PGSQL="shp2pgsql -s 4326 -D -I"

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

pgsql2shp -f country/country country country
