#!/usr/bin/env bash
# Runs the DB invariants against the project in supabase/.env (SUPABASE_DB_URL, gitignored).
# Everything rolls back; success prints "RESULT: OK".
cd "$(dirname "$0")/.." || exit 1
URL=$(grep '^SUPABASE_DB_URL=' .env | cut -d= -f2-)
FILE="$PWD/tests/invariants.sql"; command -v cygpath >/dev/null && FILE=$(cygpath -m "$FILE")
supabase db query --db-url "$URL" -f "$FILE" 2>&1 | grep -o 'RESULT: .*' | head -1
