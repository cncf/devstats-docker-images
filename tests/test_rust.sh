#!/bin/bash
# Test-suite of the Rust port of devstatscode, run inside the devstats-tests-rust image (images/Dockerfile.tests.rust):
# rust/test.sh = rustfmt + clippy + unit tests + Go<->Rust compatibility tests (PostgreSQL-backed ones included).
# The tests create and drop `dbtest_*` databases (and the `devstats` logs database), so gha_admin needs CREATEDB.
export LANGUAGE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
service postgresql start || exit 1
sudo -u postgres psql -c "create user gha_admin with password 'pwd' createdb" || exit 2
sudo -u postgres psql -c "create database dbtest with owner gha_admin lc_collate = 'en_US.UTF-8' lc_ctype = 'en_US.UTF-8' encoding = 'UTF8' template = 'template0'" || exit 3
git clone https://github.com/cncf/devstatscode || exit 10
# devstats is needed by the Rust port of devstats' metrics_test.go (rust/devstatscode/tests/metrics_yaml.rs):
# it runs tests.yaml (kubernetes metric SQL) against fixtures exactly like `make test` in devstats does under Go.
git clone https://github.com/cncf/devstats || exit 11
cd devstatscode || exit 12
hsh=$(git log -n 1 --pretty=format:"%H")
echo "Using DevStats code hash $hsh"
cd rust || exit 13
DEVSTATS_DIR="$(pwd)/../../devstats" PG_HOST=127.0.0.1 PG_PORT=5432 PG_USER=gha_admin PG_PASS=pwd ./test.sh || exit 14
echo 'All tests OK'
