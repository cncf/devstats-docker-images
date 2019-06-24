#!/bin/bash

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
  use_slots: ${PATRONI_POSTGRES_USE_SLOTS}
  connect_address: '${PATRONI_KUBERNETES_POD_IP}:5432'
  authentication:
    superuser:
      password: '${PATRONI_SUPERUSER_PASSWORD}'
    replication:
      password: '${PATRONI_REPLICATION_PASSWORD}'
  parameters:
    hot_standby: '${PATRONI_POSTGRES_HOT_STANDBY}'
    wal_log_hints: '${PATRONI_POSTGRES_WAL_LOG_HINTS}'
    wal_keep_segments: ${PATRONI_POSTGRES_WAL_KEEP_SEGMENTS}
    wal_level: '${PATRONI_POSTGRES_WAL_LEVEL}'
    max_wal_senders: ${PATRONI_POSTGRES_MAX_WAL_SENDERS}
    max_replication_slots: ${PATRONI_POSTGRES_MAX_REPLICATION_SLOTS}
    shared_buffers: '${PATRONI_POSTGRES_BUFFERS}'
    max_connections: '${PATRONI_POSTGRES_MAX_CONN}'
    max_parallel_workers_per_gather: '${PATRONI_POSTGRES_MAX_PARALLEL_WORKERS_PER_GATHER}'
    max_worker_processes: '${PATRON_POSTGRES_MAX_WORKER_PROCESSES}'
    max_parallel_workers: '${PATRON_POSTGRES_MAX_PARALLEL_WORKERS}'
    work_mem: '${PATRONI_POSTGRES_WORK_MEM}'
    temp_file_limit: '${PATRONI_POSTGRES_MAX_TEMP_FILE}'
    idle_in_transaction_session_timeout: '60min'
    wal_buffers: '${PATRONI_POSTGRES_WAL_BUFFERS}'
    synchronous_commit: 'off'
__EOF__

unset PATRONI_SUPERUSER_PASSWORD PATRONI_REPLICATION_PASSWORD
export KUBERNETES_NAMESPACE=$PATRONI_KUBERNETES_NAMESPACE
export POD_NAME=$PATRONI_NAME

chown -R postgres /home/postgres/pgdata
chmod -R 0700 /home/postgres/pgdata

exec /usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml
