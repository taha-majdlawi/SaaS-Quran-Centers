#!/usr/bin/env bash
# Builds a throw-away database from every migration and runs the invariants on it.
# Needs psql and a Postgres superuser URL:  DATABASE_URL=postgres://postgres:pw@localhost:5432/postgres bash supabase/tests/ci/run.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${DATABASE_URL:?set DATABASE_URL}"
log=$(mktemp)
psql() { command psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 "$@"; }

psql -f tests/ci/bootstrap.sql > /dev/null 2>&1
for f in migrations/*.sql; do
  # pg_cron / pg_net are stubbed by the bootstrap
  if ! sed -E 's/^create extension if not exists (pg_cron|pg_net);//I' "$f" | psql -1 > "$log" 2>&1; then
    echo "::error file=supabase/$f::migration failed"; tail -20 "$log"; exit 1
  fi
done
echo "applied $(ls migrations/*.sql | wc -l) migrations"
psql -f tests/ci/fixture.sql > /dev/null

# the invariants end in RAISE EXCEPTION on purpose (nothing is committed): read the message
out=$(command psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f tests/invariants.sql 2>&1 || true)
result=$(grep -o 'RESULT: .*' <<< "$out" | head -1)
echo "${result:-$out}"
[[ "$result" == "RESULT: OK"* ]]
