update country set geom = st_multi(st_simplifypreservetopology(geom, 0.01));
cluster country using country_pkey;

update cqzone set geom = st_multi(st_simplifypreservetopology(geom, 0.01));
cluster cqzone using cqzone_pkey;
