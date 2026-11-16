#!/usr/bin/env bash
# Prova que migracao v2->v3 divergente faz ROLLBACK em MySQL 8.4 isolado.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CN="sql-gate-negativo-$$"
PASSWORD="lab-${RANDOM}-${RANDOM}"
LOG="$(mktemp)"
cleanup() {
  docker rm -f "$CN" >/dev/null 2>&1 || true
  rm -f "$LOG"
}
trap cleanup EXIT
docker run --rm -d --name "$CN" --network none \
  -e "MYSQL_ROOT_PASSWORD=$PASSWORD" mysql:8.4 >/dev/null
sql() { docker exec -i -e "MYSQL_PWD=$PASSWORD" "$CN" mysql -uroot --batch --skip-column-names "$@"; }
for i in {1..90}; do if sql -e 'SELECT 1' >/dev/null 2>&1; then break; fi; sleep 1; done
sql < "$ROOT/01_Banco_SQL_5_Versoes_Canonicas_Expandida/banco_v1/banco_completo.sql"
sql < "$ROOT/01_Banco_SQL_5_Versoes_Canonicas_Expandida/banco_v2/banco_completo.sql"
# Introduz divergencia somente nesta copia efemera do script, nunca na fonte.
if sed 's/NULL,5,Receita_Venda,Custo_Venda,/NULL,5,Receita_Venda,Custo_Venda+1,/' \
  "$ROOT/01_Banco_SQL_5_Versoes_Canonicas_Expandida/banco_v3/migracao_banco_v2_para_v3.sql" \
  | sql > "$LOG" 2>&1; then
  echo "FAIL: divergencia deveria impedir COMMIT" >&2; exit 1
fi
grep -q 'Migracao v2-v3: divergencia linha a linha' "$LOG" || {
  echo "FAIL: migracao falhou por causa diferente"; cat "$LOG"; exit 1;
}
pedidos="$(sql -e "SELECT COUNT(*) FROM banco_v3.pedidos")"
itens="$(sql -e "SELECT COUNT(*) FROM banco_v3.itens_pedido")"
[[ "$pedidos" == 0 && "$itens" == 0 ]] || {
  echo "FAIL: ROLLBACK nao preservou estado ($pedidos/$itens)"; exit 1;
}
echo "PASS: divergencia detectada, SIGNAL e ROLLBACK antes do COMMIT"
