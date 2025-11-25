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
    loop_wait: ${PATRONI_LOOP_WAIT}
    ttl: ${PATRONI_TTL}
    retry_timeout: ${PATRONI_RETRY_TIMEOUT}
    primary_start_timeout: ${PATRONI_MASTER_START_TIMEOUT}
    maximum_lag_on_failover: ${PATRONI_MAXIMUM_LAG_ON_FAILOVER}
    postgresql:
      use_pg_rewind: true
      use_slots: ${PATRONI_POSTGRES_USE_SLOTS}

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
  parameters:
    hot_standby: '${PATRONI_POSTGRES_HOT_STANDBY}'
    hot_standby_feedback: '${PATRONI_POSTGRES_HOT_STANDBY_FEEDBACK}'
    wal_log_hints: '${PATRONI_POSTGRES_WAL_LOG_HINTS}'
    wal_keep_segments: ${PATRONI_POSTGRES_WAL_KEEP_SEGMENTS}
    wal_keep_size: ${PATRONI_POSTGRES_WAL_KEEP_SIZE}
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
    wal_buffers: '${PATRONI_POSTGRES_WAL_BUFFERS}'
    maintenance_work_mem: '${PATRONI_POSTGRES_MAINTENANCE_WORK_MEM}'
    idle_in_transaction_session_timeout: '${PATRONI_POSTGRES_IDLE_TRANSACTION_TIMEOUT}'
    max_wal_size: '${PATRONI_POSTGRES_MAX_WAL_SIZE}'
    min_wal_size: '${PATRONI_POSTGRES_MIN_WAL_SIZE}'
    checkpoint_completion_target: '${PATRONI_POSTGRES_CHECKPOINT_COMPLETION_TARGET}'
    default_statistics_target: '${PATRONI_POSTGRES_DEFAULT_STATISTICS_TARGET}'
    effective_cache_size: '${PATRONI_POSTGRES_CACHE_SIZE}'
    effective_io_concurrency: '${PATRONI_POSTGRES_IO_CONCURRENCY}'
    random_page_cost: '${PATRONI_POSTGRES_RANDOM_PAGE_COST}'
    synchronous_commit: 'off'
    autovacuum_max_workers: '${PATRONI_POSTGRES_AUTOVACUUM_MAX_WORKERS}'
    autovacuum_naptime: '${PATRONI_POSTGRES_AUTOVACUUM_NAPTIME}'
    autovacuum_vacuum_cost_limit: '${PATRONI_POSTGRES_AUTOVACUUM_VACUUM_COST_LIMIT}'
    autovacuum_vacuum_threshold: '${PATRONI_POSTGRES_AUTOVACUUM_VACUUM_THRESHOLD}'
    autovacuum_vacuum_scale_factor: '${PATRONI_POSTGRES_AUTOVACUUM_VACUUM_SCALE_FACTOR}'
    autovacuum_analyze_threshold: '${PATRONI_POSTGRES_AUTOVACUUM_ANALYZE_THRESHOLD}'
    autovacuum_analyze_scale_factor: '${PATRONI_POSTGRES_AUTOVACUUM_ANALYZE_SCALE_FACTOR}'
tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
__EOF__

unset PATRONI_SUPERUSER_PASSWORD PATRONI_REPLICATION_PASSWORD
export KUBERNETES_NAMESPACE=$PATRONI_KUBERNETES_NAMESPACE
export POD_NAME=$PATRONI_NAME

chown -R postgres /home/postgres/pgdata
chmod -R 0700 /home/postgres/pgdata

# Disable core dumps
ulimit -c 0

exec /usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml
