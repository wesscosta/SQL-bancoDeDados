-- Execute após carregar banco_v5. Para a massa canônica, verifique os totais.
SELECT COUNT(*) AS Tabelas FROM information_schema.tables
WHERE table_schema='banco_v5' AND table_type='BASE TABLE'; -- 20
SELECT COUNT(*) AS Clientes FROM banco_v5.clientes; -- 10000
SELECT COUNT(*) AS Produtos FROM banco_v5.produtos; -- 500
SELECT COUNT(*) AS Pedidos FROM banco_v5.pedidos; -- 100000
SELECT COUNT(*) AS Itens FROM banco_v5.itens_pedido; -- 249439
SELECT COUNT(*) AS Pagamentos FROM banco_v5.pagamentos; -- 99626
SELECT COUNT(*) AS Estoques FROM banco_v5.estoque; -- 4000
SELECT COUNT(*) AS Movimentos FROM banco_v5.movimentacoes_estoque; -- 4072
SELECT Origem_Registro,COUNT(*) AS Pedidos,
       COALESCE(SUM(Valor_Total),0) AS Receita
FROM banco_v5.pedidos GROUP BY Origem_Registro;
-- LEGADO_V2=374; OPERACAO_V3=99626
SELECT COUNT(*) AS Pagamentos_Legados
FROM banco_v5.pagamentos pg JOIN banco_v5.pedidos p ON p.ID_Pedido=pg.ID_Pedido
WHERE p.Origem_Registro='LEGADO_V2'; -- esperado 0
SELECT COUNT(*) AS Movimentos_Ficticios_Performance
FROM banco_v5.movimentacoes_estoque m JOIN banco_v5.pedidos p ON p.ID_Pedido=m.ID_Pedido
WHERE p.Observacao='Carga de performance v5'; -- esperado 0, porque massa é para benchmark
SELECT COUNT(*) AS Pedidos_Sem_Vendedor_Valido
FROM banco_v5.pedidos p LEFT JOIN banco_v5.vendedores v
 ON v.ID_Vendedor=p.ID_Vendedor AND v.ID_Loja=p.ID_Loja
WHERE p.Origem_Registro='OPERACAO_V3' AND v.ID_Vendedor IS NULL; -- esperado 0
SELECT COUNT(*) AS Pedidos_Valores_Divergentes
FROM (
 SELECT p.ID_Pedido,p.Valor_Total
 FROM banco_v5.pedidos p LEFT JOIN banco_v5.itens_pedido ip ON ip.ID_Pedido=p.ID_Pedido
 GROUP BY p.ID_Pedido,p.Valor_Total
 HAVING COUNT(ip.ID_Item)=0 OR ABS(p.Valor_Total-
  COALESCE(SUM(ip.Quantidade*ip.Preco_Unit-ip.Desconto_Valor+ip.Ajuste_Valor),0))>0.005
) d; -- esperado 0
SELECT COUNT(*) AS Estoques_Divergentes
FROM (
 SELECT e.ID_Loja,e.ID_Produto,e.Quantidade,
 COALESCE(SUM(CASE WHEN m.Tipo_Movimentacao IN ('ENTRADA','AJUSTE') THEN m.Quantidade
                   ELSE -m.Quantidade END),0) AS Saldo_Movimentos
 FROM banco_v5.estoque e LEFT JOIN banco_v5.movimentacoes_estoque m
 ON m.ID_Loja=e.ID_Loja AND m.ID_Produto=e.ID_Produto
 GROUP BY e.ID_Loja,e.ID_Produto,e.Quantidade
 HAVING e.Quantidade <> Saldo_Movimentos
) d; -- esperado 0
SELECT COUNT(*) AS FKs_Duplicadas
FROM (
 SELECT CONSTRAINT_NAME FROM information_schema.REFERENTIAL_CONSTRAINTS
 WHERE CONSTRAINT_SCHEMA='banco_v5' GROUP BY CONSTRAINT_NAME HAVING COUNT(*)>1
) d; -- esperado 0
