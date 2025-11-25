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
git clone https://github.com/cncf/devstatscode || exit 10
git clone https://github.com/cncf/devstats || exit 11
cd devstatscode || exit 12
hsh=$(git log -n 1 --pretty=format:"%H")
echo "Using DevStats code hash $hsh"
go mod tidy || exit 13
make || exit 14
make test || exit 15
GHA2DB_PROJECT=kubernetes GHA2DB_LOCAL=1 PG_PASS=pwd ./dbtest.sh || exit 16
cd ../devstats || exit 17
# vim -c '%s/github.com\/cncf\/devstatscode \(.*\)$/github.com\/cncf\/devstatscode master/g' -c wq go.mod
go get "github.com/cncf/devstatscode@${hsh}" || exit 18
cat go.mod | grep devstatscode
make check || exit 19
PG_PASS=pwd make test || exit 20
echo 'All tests OK'
