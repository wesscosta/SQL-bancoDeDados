#!/usr/bin/env bash
# Laboratorio isolado: dois conteineres MySQL 8.4 descartaveis; sem portas nem volumes.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v docker >/dev/null || { echo "Docker necessario" >&2; exit 2; }
PASSWORD="sql-lab-${RANDOM}-${RANDOM}"
CN=""
TMP_DIR="$(mktemp -d)"
cleanup_container() { [[ -z "$CN" ]] || docker rm -f "$CN" >/dev/null 2>&1 || true; }
cleanup() {
  cleanup_container
  [[ -z "$TMP_DIR" ]] || rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT
sql() { docker exec -e "MYSQL_PWD=$PASSWORD" "$CN" mysql -uroot --batch --skip-column-names "$@"; }
load() {
  echo "IMPORT $1"
  docker exec -i -e "MYSQL_PWD=$PASSWORD" "$CN" mysql -uroot --batch --skip-column-names < "$ROOT/$1"
}
check() {
  local label="$1" query="$2" expected="$3" actual
  actual="$(sql -e "$query")"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL $label: expected=$expected actual=$actual" >&2
    exit 1
  fi
  echo "OK $label = $actual"
}
start() {
  CN="sql-audit-$1-$$"
  docker run --rm -d --name "$CN" --network none \
    -e "MYSQL_ROOT_PASSWORD=$PASSWORD" mysql:8.4 >/dev/null
  local i
  for i in {1..90}; do
    if sql -e 'SELECT 1' >/dev/null 2>&1; then
      echo "MySQL $(sql -e 'SELECT VERSION()') | $1"
      return
    fi
    sleep 1
  done
  echo "MySQL indisponivel" >&2
  exit 2
}
verify_origin() {
  check "v1 tables" "SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_SCHEMA='banco_v1' AND TABLE_TYPE='BASE TABLE'" 6
  check "v2 tables" "SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_SCHEMA='banco_v2' AND TABLE_TYPE='BASE TABLE'" 7
  check "v2 historical rows" "SELECT COUNT(*) FROM banco_v2.pedidos" 374
}
verify_version() {
  local v="$1" tables=20
  [[ "$v" == 3 ]] && tables=12
  check "v$v tables" "SELECT COUNT(*) FROM information_schema.tables WHERE TABLE_SCHEMA='banco_v$v' AND TABLE_TYPE='BASE TABLE'" "$tables"
  check "v$v FK unique names" "SELECT COUNT(*) FROM (SELECT CONSTRAINT_NAME FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='banco_v$v' GROUP BY CONSTRAINT_NAME HAVING COUNT(*)>1) t" 0
  check "v$v legacy count" "SELECT COUNT(*) FROM banco_v$v.pedidos WHERE Origem_Registro='LEGADO_V2'" 374
  check "v$v legacy unknown staff" "SELECT COUNT(*) FROM banco_v$v.pedidos WHERE Origem_Registro='LEGADO_V2' AND (ID_Vendedor IS NOT NULL OR ID_Status<>5)" 0
  check "v$v legacy payments" "SELECT COUNT(*) FROM banco_v$v.pagamentos pg JOIN banco_v$v.pedidos p USING(ID_Pedido) WHERE p.Origem_Registro='LEGADO_V2'" 0
  check "v$v historical revenue" "SELECT COUNT(*) FROM (SELECT (SELECT SUM(Receita_Venda) FROM banco_v2.pedidos) a,(SELECT SUM(Valor_Total) FROM banco_v$v.pedidos WHERE Origem_Registro='LEGADO_V2') b) t WHERE NOT(a<=>b)" 0
  check "v$v total/item divergence" "SELECT COUNT(*) FROM (SELECT p.ID_Pedido FROM banco_v$v.pedidos p LEFT JOIN banco_v$v.itens_pedido i USING(ID_Pedido) GROUP BY p.ID_Pedido,p.Valor_Total HAVING COUNT(i.ID_Item)=0 OR ABS(p.Valor_Total-COALESCE(SUM(i.Quantidade*i.Preco_Unit-i.Desconto_Valor+i.Ajuste_Valor),0))>0.005) t" 0
  check "v$v orphan items" "SELECT COUNT(*) FROM banco_v$v.itens_pedido i LEFT JOIN banco_v$v.pedidos p USING(ID_Pedido) WHERE p.ID_Pedido IS NULL" 0
  if [[ "$v" == 3 ]]; then
    check "v3 orders" "SELECT COUNT(*) FROM banco_v3.pedidos" 390
    check "v3 order items" "SELECT COUNT(*) FROM banco_v3.itens_pedido" 414
    check "v3 payments" "SELECT COUNT(*) FROM banco_v3.pagamentos" 16
  else
    check "v$v purchases without item" "SELECT COUNT(*) FROM banco_v$v.compras c LEFT JOIN banco_v$v.itens_compra i USING(ID_Compra) WHERE i.ID_Compra IS NULL" 0
    check "v$v purchase total divergence" "SELECT COUNT(*) FROM (SELECT c.ID_Compra FROM banco_v$v.compras c LEFT JOIN banco_v$v.itens_compra i USING(ID_Compra) GROUP BY c.ID_Compra,c.Valor_Total HAVING COUNT(i.ID_Item_Compra)=0 OR ABS(c.Valor_Total-COALESCE(SUM(i.Quantidade*i.Custo_Unit),0))>0.005) t" 0
    check "v$v stock mismatches" "SELECT COUNT(*) FROM (SELECT e.ID_Loja,e.ID_Produto FROM banco_v$v.estoque e LEFT JOIN banco_v$v.movimentacoes_estoque m ON m.ID_Loja=e.ID_Loja AND m.ID_Produto=e.ID_Produto GROUP BY e.ID_Loja,e.ID_Produto,e.Quantidade HAVING e.Quantidade<>COALESCE(SUM(CASE WHEN m.Tipo_Movimentacao IN ('ENTRADA','AJUSTE') THEN m.Quantidade ELSE -m.Quantidade END),0)) t" 0
  fi
  if [[ "$v" == 4 ]]; then
    check "v4 orders" "SELECT COUNT(*) FROM banco_v4.pedidos" 390
    check "v4 purchases" "SELECT COUNT(*) FROM banco_v4.compras" 16
    check "v4 stock rows" "SELECT COUNT(*) FROM banco_v4.estoque" 128
  elif [[ "$v" == 5 ]]; then
    check "v5 clients" "SELECT COUNT(*) FROM banco_v5.clientes" 10000
    check "v5 products" "SELECT COUNT(*) FROM banco_v5.produtos" 500
    check "v5 orders" "SELECT COUNT(*) FROM banco_v5.pedidos" 100000
    check "v5 items" "SELECT COUNT(*) FROM banco_v5.itens_pedido" 249439
    check "v5 payments" "SELECT COUNT(*) FROM banco_v5.pagamentos" 99626
    check "v5 stocks" "SELECT COUNT(*) FROM banco_v5.estoque" 4000
  fi
}
snapshot() {
  local dest="$1" schema t hash
  : > "$dest"
  for v in 3 4 5; do
    schema="banco_v$v"
    while IFS= read -r t; do
      [[ -z "$t" ]] && continue
      # IDs AUTO_INCREMENT de linhas derivadas podem variar entre cargas
      # sem alterar seu conteúdo: comparar dados de negócio sem esses IDs.
      if [[ "$t" == itens_pedido ]]; then
        hash="$(sql -e "SELECT ID_Pedido,ID_Produto,Quantidade,Preco_Unit,Custo_Unit,Desconto_Valor,Ajuste_Valor FROM $schema.itens_pedido ORDER BY ID_Pedido,ID_Produto" | sha256sum | cut -d' ' -f1)"
      elif [[ "$t" == historico_status_pedido ]]; then
        hash="$(sql -e "SELECT ID_Pedido,ID_Status,Data_Status,Observacao FROM $schema.historico_status_pedido ORDER BY ID_Pedido,ID_Status,Data_Status,Observacao" | sha256sum | cut -d' ' -f1)"
      elif [[ "$t" == movimentacoes_estoque ]]; then
        hash="$(sql -e "SELECT ID_Loja,ID_Produto,Tipo_Movimentacao,Quantidade,Data_Movimentacao,ID_Pedido,ID_Compra,Observacao FROM $schema.movimentacoes_estoque ORDER BY ID_Loja,ID_Produto,Tipo_Movimentacao,Quantidade,Data_Movimentacao,ID_Pedido,ID_Compra,Observacao" | sha256sum | cut -d' ' -f1)"
      else
        hash="$(docker exec -e "MYSQL_PWD=$PASSWORD" "$CN" mysqldump -uroot \
          --no-tablespaces --no-create-info --skip-comments --skip-extended-insert \
          --compact --order-by-primary "$schema" "$t" | sha256sum | cut -d' ' -f1)"
      fi
      printf '%s/%s %s\n' "$schema" "$t" "$hash" >> "$dest"
    done < <(sql -e "SELECT TABLE_NAME FROM information_schema.tables WHERE TABLE_SCHEMA='$schema' AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME")
  done
  echo "SNAPSHOT $dest: $(wc -l < "$dest") tabelas"
}
run_mode() {
  local mode="$1"
  start "$mode"
  load "banco_v1/banco_completo.sql"
  load "banco_v2/banco_completo.sql"
  verify_origin
  if [[ "$mode" == direct ]]; then
    load "banco_v3/banco_v3_final.sql"
  else
    load "banco_v3/migracao_banco_v2_para_v3.sql"
  fi
  verify_version 3
  if [[ "$mode" == direct ]]; then
    load "banco_v4/banco_v4_final.sql"
  else
    load "banco_v4/migracao_v3_para_v4.sql"
  fi
  verify_version 4
  if [[ "$mode" == direct ]]; then
    load "banco_v5/banco_v5_final.sql"
  else
    load "banco_v5/migracao_v4_para_v5.sql"
  fi
  verify_version 5
  snapshot "$TMP_DIR/$mode.txt"
  verify_origin
  echo "PASS $mode"
  cleanup_container
  CN=""
}
run_mode direct
run_mode migration
diff -u "$TMP_DIR/direct.txt" "$TMP_DIR/migration.txt"
echo "PASS: integridade e dados idênticos entre instalação direta e migrações em MySQL 8.4"
