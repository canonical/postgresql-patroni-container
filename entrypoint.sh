#!/bin/bash
cat > /var/lib/postgresql/data/patroni.yml <<__EOF__
bootstrap:
  dcs:
    postgresql:
      use_pg_rewind: true
  initdb:
  - auth-host: md5
  - auth-local: trust
  - encoding: UTF8
  - locale: en_US.UTF-8
  - data-checksums
  pg_hba:
  - host all all 0.0.0.0/0 md5
  - host replication ${PATRONI_REPLICATION_USERNAME} ${PATRONI_KUBERNETES_POD_IP}/16 md5
restapi:
  connect_address: '${PATRONI_KUBERNETES_POD_IP}:8008'
  listen: 0.0.0.0:8008
pod_ip: '${PATRONI_KUBERNETES_POD_IP}'
postgresql:
  connect_address: '${PATRONI_KUBERNETES_POD_IP}:5432'
  data_dir: /var/lib/postgresql/data/pgdata
  listen: 0.0.0.0:5432
use_endpoints: true
__EOF__

/usr/bin/python3 /usr/local/bin/patroni /var/lib/postgresql/data/patroni.yml