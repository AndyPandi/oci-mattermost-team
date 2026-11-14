#!/bin/sh
# Sourced by the official PostgreSQL entrypoint only for an empty PGDATA.
# Do not enable tracing: SQL includes a generated application secret.
set -eu
case "$MM_APP_PASSWORD" in
  ''|*[!0123456789abcdef]*) echo 'Invalid application secret' >&2; exit 1 ;;
esac
[ "${#MM_APP_PASSWORD}" -eq 64 ] || exit 1
# Never pass passwords through argv, echo SQL, or log failing SQL statements.
# The official entrypoint uses psql ON_ERROR_STOP; suppression also covers errors.
if ! PGOPTIONS='-c log_statement=none -c log_min_error_statement=panic -c log_min_messages=panic' psql -X -q -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres >/dev/null 2>&1 <<SQL
CREATE ROLE mmuser LOGIN PASSWORD '$MM_APP_PASSWORD' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE DATABASE mattermost OWNER mmuser;
REVOKE ALL ON DATABASE mattermost FROM PUBLIC;
SQL
then
  echo 'Application database initialization failed; inspect privately, do not reset PGDATA' >&2
  exit 1
fi
