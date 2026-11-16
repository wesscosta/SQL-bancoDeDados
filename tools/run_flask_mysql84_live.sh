#!/usr/bin/env bash
# MySQL efemero com porta aleatoria vinculada SOMENTE a 127.0.0.1.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="${PORTAL_PYTHON:-python3}"
CN="portal-mysql84-live-$$"
PASSWORD="portal-lab-${RANDOM}-${RANDOM}"
cleanup() { docker rm -f "$CN" >/dev/null 2>&1 || true; }
trap cleanup EXIT
docker run -d --rm --name "$CN" -p 127.0.0.1::3306 \
  -e "MYSQL_ROOT_PASSWORD=$PASSWORD" mysql:8.4 >/dev/null
sql() { docker exec -i -e "MYSQL_PWD=$PASSWORD" "$CN" mysql -uroot --batch "$@"; }
for i in {1..90}; do
  if sql -e 'SELECT 1' >/dev/null 2>&1; then break; fi
  sleep 1
done
sql -e 'SELECT VERSION();'
# Instancia MySQL efemera: cria somente banco_v3 dentro do container descartavel.
sql < "$ROOT/01_Banco_SQL_5_Versoes_Canonicas_Expandida/banco_v3/banco_v3_final.sql"
sql < "$ROOT/portal_comercial_starter/sql/preparar_lab.sql"
sql -e "CREATE USER 'portal_test'@'%' IDENTIFIED BY '$PASSWORD';"
sql -e "GRANT SELECT,INSERT,UPDATE ON banco_v3.* TO 'portal_test'@'%';"
BINDING="$(docker port "$CN" 3306/tcp)"
PORT="${BINDING##*:}"
echo "MySQL teste exposto somente em 127.0.0.1:$PORT"
cd "$ROOT/portal_comercial_starter"
PORTAL_INTEGRATION=1 FLASK_SECRET_KEY=teste-local \
  DB_HOST=127.0.0.1 DB_PORT="$PORT" DB_NAME=banco_v3 \
  DB_USER=portal_test DB_PASSWORD="$PASSWORD" \
  "$PY" -m pytest -q tests/test_mysql_live.py
