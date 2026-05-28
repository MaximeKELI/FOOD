#!/usr/bin/env bash
# Crée le rôle et la base PostgreSQL pour Food.
# Usage : sudo -u postgres bash setup_db.sh
set -e

DB_NAME="${DB_NAME:-food_db}"
DB_USER="${DB_USER:-food_user}"
DB_PASSWORD="${DB_PASSWORD:-food_pass}"

psql <<SQL
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASSWORD}';
   END IF;
END
\$\$;

-- Force le mot de passe et le droit de créer des bases (idempotent).
ALTER ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASSWORD}' CREATEDB;

SELECT 'CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\gexec

GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
SQL

echo "OK: base '${DB_NAME}' et rôle '${DB_USER}' prêts."
