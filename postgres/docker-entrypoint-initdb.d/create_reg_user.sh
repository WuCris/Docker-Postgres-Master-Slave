#!/bin/sh
source /usr/local/bin/docker-entrypoint.sh

set -e

if [ -z "$POSTGRES_MASTER" ]; then

echo "Container designated as master."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE USER $POSTGRES_REG_USER WITH ENCRYPTED PASSWORD '$POSTGRES_REG_USER_PASS';
	CREATE DATABASE $POSTGRES_REG_DB OWNER $POSTGRES_REG_USER;
	GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_REG_DB TO $POSTGRES_REG_USER;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER $POSTGRES_REPLICATION_USER REPLICATION LOGIN ENCRYPTED PASSWORD '$POSTGRES_REPLICATION_PASS';
EOSQL

cat << EOF >> /var/lib/postgresql/data/pg_hba.conf
host    replication     all             10.0.0.0/8              scram-sha-256
host    replication     all             172.16.0.0/12           scram-sha-256
host    replication     all             192.168.0.0/16          scram-sha-256
EOF

fi

if [ ! -z "$POSTGRES_MASTER" ]; then

    echo "Container designated as replica."

    while ! pg_isready -h "$POSTGRES_MASTER"
    do
        echo "waiting for master database to start"
        sleep 2
    done

    docker_temp_server_stop

    rm -Rf /var/lib/postgresql/data/*
    PGPASSWORD=$POSTGRES_REPLICATION_PASS pg_basebackup -h $POSTGRES_MASTER -U $POSTGRES_REPLICATION_USER -D /var/lib/postgresql/data/  -Fp -Xs -P -R
    docker_temp_server_start


fi