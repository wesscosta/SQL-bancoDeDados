#!/usr/bin/env bash
set -euo pipefail
# Execute SOMENTE em um MySQL de testes isolado. Nenhuma senha fica no repositório.
: "${MYSQL_HOST:=127.0.0.1}"
: "${MYSQL_PORT:=3306}"
: "${MYSQL_USER:=root}"
: "${MYSQL_PWD:?Defina MYSQL_PWD via secret/ambiente}"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MYSQL=(mysql --batch --skip-column-names -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER")
check(){
 local name="$1" query="$2" expected="$3" result
 result=$("${MYSQL[@]}" -e "$query" | tr -d '[:space:]')
 if [[ "$result" != "$expected" ]]; then
   printf 'FALHA %-34s obtido=%s esperado=%s\n' "$name" "$result" "$expected" >&2; exit 1
 fi
 printf 'OK %-37s %s\n' "$name" "$result"
}
import(){ echo "Instalando $(basename "$1")"; "${MYSQL[@]}" < "$1"; }
import "$BASE_DIR/banco_v3_final.sql"
import "$BASE_DIR/migracao_v3_para_v4.sql"
check 'Tabelas v4' "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='banco_v4' AND table_type='BASE TABLE';" 20
check 'Pedidos v4' 'SELECT COUNT(*) FROM banco_v4.pedidos' 390
check 'Compras v4' 'SELECT COUNT(*) FROM banco_v4.compras' 16
check 'Estoque v4' 'SELECT COUNT(*) FROM banco_v4.estoque' 128
check 'Historico real v4' "SELECT COUNT(*) FROM banco_v4.historico_status_pedido h JOIN banco_v4.pedidos p USING(ID_Pedido) WHERE p.Origem_Registro='LEGADO_V2'" 0
check 'Pagamento legado v4' "SELECT COUNT(*) FROM banco_v4.pagamentos pg JOIN banco_v4.pedidos p USING(ID_Pedido) WHERE p.Origem_Registro='LEGADO_V2'" 0
import "$BASE_DIR/migracao_v4_para_v5.sql"
check 'Tabelas v5' "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='banco_v5' AND table_type='BASE TABLE';" 20
check 'Clientes v5' 'SELECT COUNT(*) FROM banco_v5.clientes' 10000
check 'Produtos v5' 'SELECT COUNT(*) FROM banco_v5.produtos' 500
check 'Pedidos v5' 'SELECT COUNT(*) FROM banco_v5.pedidos' 100000
check 'Itens v5' 'SELECT COUNT(*) FROM banco_v5.itens_pedido' 249439
check 'Pagamentos v5' 'SELECT COUNT(*) FROM banco_v5.pagamentos' 99626
check 'Estoque v5' 'SELECT COUNT(*) FROM banco_v5.estoque' 4000
check 'Pagamento legado v5' "SELECT COUNT(*) FROM banco_v5.pagamentos pg JOIN banco_v5.pedidos p USING(ID_Pedido) WHERE p.Origem_Registro='LEGADO_V2'" 0
check 'FK repetidas v5' "SELECT COUNT(*) FROM (SELECT CONSTRAINT_NAME FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='banco_v5' GROUP BY CONSTRAINT_NAME HAVING COUNT(*)>1) x" 0
check 'Divergencia financeira v5' "SELECT COUNT(*) FROM (SELECT p.ID_Pedido FROM banco_v5.pedidos p LEFT JOIN banco_v5.itens_pedido i USING(ID_Pedido) GROUP BY p.ID_Pedido,p.Valor_Total HAVING COUNT(i.ID_Item)=0 OR ABS(p.Valor_Total-COALESCE(SUM(i.Quantidade*i.Preco_Unit-i.Desconto_Valor+i.Ajuste_Valor),0))>0.005) x" 0
check 'Saldo estoque v5' "SELECT COUNT(*) FROM (SELECT e.ID_Loja,e.ID_Produto FROM banco_v5.estoque e LEFT JOIN banco_v5.movimentacoes_estoque m ON m.ID_Loja=e.ID_Loja AND m.ID_Produto=e.ID_Produto GROUP BY e.ID_Loja,e.ID_Produto,e.Quantidade HAVING e.Quantidade<>COALESCE(SUM(CASE WHEN m.Tipo_Movimentacao IN ('ENTRADA','AJUSTE') THEN m.Quantidade ELSE -m.Quantidade END),0)) x" 0
printf '\nHomologação dos scripts de MIGRAÇÃO concluída. Testando instalação direta no mesmo servidor EFÊMERO.\n'
"${MYSQL[@]}" -e 'DROP DATABASE banco_v5; DROP DATABASE banco_v4;'
import "$BASE_DIR/banco_v4_final.sql"
check 'Instalacao direta v4' 'SELECT COUNT(*) FROM banco_v4.pedidos' 390
import "$BASE_DIR/banco_v5_final.sql"
check 'Instalacao direta v5' 'SELECT COUNT(*) FROM banco_v5.pedidos' 100000
check 'FK repetidas v5 direta' "SELECT COUNT(*) FROM (SELECT CONSTRAINT_NAME FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='banco_v5' GROUP BY CONSTRAINT_NAME HAVING COUNT(*)>1) x" 0
printf '\nPASSOU: instalacoes e migracoes, em servidor efemero de teste.\n'
