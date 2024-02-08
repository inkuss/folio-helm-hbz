#!/bin/bash
set +e

log() { date | xargs -IDATE echo DATE $1 ;}

log "Creating vufind database $VUFIND_DB_NAME and Postgres User "$VUFIND_DB_USER" ..."
log "Running: psql -w -v ON_ERROR_STOP=1 -h $VUFIND_DB_HOST -U $POSTGRES_DB_USER  ...";
PGPASSWORD="$POSTGRES_DB_PASSWORD" psql -w -v ON_ERROR_STOP=1 -h "$VUFIND_DB_HOST" -U "$POSTGRES_DB_USER"  <<-EOSQL
CREATE ROLE "$VUFIND_DB_USER" WITH PASSWORD '$VUFIND_DB_PASSWORD' LOGIN CREATEDB;
CREATE DATABASE "$VUFIND_DB_NAME" WITH OWNER "$VUFIND_DB_USER";
EOSQL
if [ $? != 0 ]; then 
    log "Database already existst or other error occurred, not initializing tables." 
    exit 0
fi

set -e

log "Creating Database tables for vufind"

PGPASSWORD="$VUFIND_DB_PASSWORD" \
psql -w -v ON_ERROR_STOP=1 -h "$VUFIND_DB_HOST" -U "$VUFIND_DB_USER" "$VUFIND_DB_NAME" < /usr/local/vufind/module/VuFind/sql/pgsql.sql

log "Init script is completed";