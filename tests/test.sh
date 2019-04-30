#!/bin/bash
export LANGUAGE="en_US.UTF-8"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
service postgresql start || exit 1
sudo -u postgres psql -c "create database gha with lc_collate = 'en_US.UTF-8' lc_ctype = 'en_US.UTF-8' encoding = 'UTF8' template = 'template0'" || exit 2
sudo -u postgres psql gha -c "create user gha_admin with password 'pwd'" || exit 3
sudo -u postgres psql gha -c 'grant all privileges on database "gha" to gha_admin' || exit 4
sudo -u postgres psql gha -c "alter user gha_admin createdb" || exit 5
sudo -u postgres psql gha -c "create user ro_user with password 'pwd'" || exit 6
sudo -u postgres psql gha -c 'grant all privileges on database "gha" to ro_user' || exit 7
sudo -u postgres psql gha -c "create user devstats_team with password 'pwd'" || exit 8
sudo -u postgres psql gha -c 'grant all privileges on database "gha" to devstats_team' || exit 9
go get -u github.com/cncf/devstatscode || exit 10
go get -d github.com/cncf/devstats || exit 11
cd /go/src/github.com/cncf/devstatscode || exit 12
make || exit 13
make test || exit 14
GHA2DB_PROJECT=kubernetes GHA2DB_LOCAL=1 PG_PASS=pwd ./dbtest.sh || exit 15
cd /go/src/github.com/cncf/devstats || exit 16
make check || exit 17
PG_PASS=pwd make test || exit 18
