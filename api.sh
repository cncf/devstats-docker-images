#!/bin/bash
docker run -p 8080:8080 --env "PG_HOST=172.17.0.1" --env "PG_PASS=Admin123" --env "PG_PASS_RO=Admin123" --env "PG_HOST_RO=172.17.0.1" --env "PG_USER_RO=ro_user" lukaszgryglicki/devstats-api
