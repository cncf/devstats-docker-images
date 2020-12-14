!/bin/bash

if [[ $UID -ge 10000 ]]; then
    GID=$(id -g)
    sed -e "s/^postgres:x:[^:]*:[^:]*:/postgres:x:$UID:$GID:/" /etc/passwd > /tmp/passwd
    cat /tmp/passwd > /etc/passwd
    rm /tmp/passwd
fi

cat > /home/postgres/patroni.yml <<__EOF__
bootstrap:
  dcs:
    postgresql:
      use_pg_rewind: true
    parameters:
      shared_buffers: '32GB'
      max_connections: 300
      max_worker_processes: 56
      max_parallel_workers: 56
      max_parallel_workers_per_gather: 28
      work_mem: '1GB'
      maintenance_work_mem: '1GB'
      temp_file_limit: '20GB'
      idle_in_transaction_session_timeout = '60min'
      wal_buffers: '128MB'
      max_wal_size: '8GB'
      min_wal_size: '1GB'
      checkpoint_completion_target: 0.9
      default_statistics_target: 1000
      effective_cache_size: '192GB'
      effective_io_concurrency: 8
      random_page_cost: 1.5
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
postgresql:
  connect_address: '${PATRONI_KUBERNETES_POD_IP}:5432'
  authentication:
    superuser:
      password: '${PATRONI_SUPERUSER_PASSWORD}'
    replication:
      password: '${PATRONI_REPLICATION_PASSWORD}'
__EOF__

unset PATRONI_SUPERUSER_PASSWORD PATRONI_REPLICATION_PASSWORD
export KUBERNETES_NAMESPACE=$PATRONI_KUBERNETES_NAMESPACE
export POD_NAME=$PATRONI_NAME

chmod -R 0700 /home/postgres/pgdata
chmod 0700 /home/postgres/pgdata/pgroot/data

exec /usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml
