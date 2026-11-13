-- Execute após carregar banco_v4. Valores esperados para a massa canônica.
SELECT COUNT(*) AS Tabelas FROM information_schema.tables
WHERE table_schema='banco_v4' AND table_type='BASE TABLE'; -- esperado 20
SELECT COUNT(*) AS Pedidos FROM banco_v4.pedidos; -- esperado 390
SELECT COUNT(*) AS Itens FROM banco_v4.itens_pedido; -- esperado 414
SELECT COUNT(*) AS Fornecedores FROM banco_v4.fornecedores; -- esperado 15
SELECT COUNT(*) AS Compras FROM banco_v4.compras; -- esperado 16
SELECT COUNT(*) AS Itens_Compra FROM banco_v4.itens_compra; -- esperado 32
SELECT COUNT(*) AS Saldos_Estoque FROM banco_v4.estoque; -- esperado 128
SELECT COUNT(*) AS Movimentos FROM banco_v4.movimentacoes_estoque; -- esperado 200
SELECT COUNT(*) AS Historicos_Status FROM banco_v4.historico_status_pedido; -- esperado 16
SELECT COUNT(*) AS Pagamentos_Legados
FROM banco_v4.pagamentos pg JOIN banco_v4.pedidos p ON p.ID_Pedido=pg.ID_Pedido
WHERE p.Origem_Registro='LEGADO_V2'; -- esperado 0
SELECT COUNT(*) AS Historicos_Legados_Fabricados
FROM banco_v4.historico_status_pedido h JOIN banco_v4.pedidos p ON p.ID_Pedido=h.ID_Pedido
WHERE p.Origem_Registro='LEGADO_V2'; -- esperado 0
SELECT COUNT(*) AS Movimentos_Legados_Fabricados
FROM banco_v4.movimentacoes_estoque m JOIN banco_v4.pedidos p ON p.ID_Pedido=m.ID_Pedido
WHERE p.Origem_Registro='LEGADO_V2'; -- esperado 0
SELECT COUNT(*) AS Compras_Divergentes
FROM (
 SELECT c.ID_Compra,c.Valor_Total,
        SUM(ic.Quantidade*ic.Custo_Unit) AS Total_Itens
 FROM banco_v4.compras c JOIN banco_v4.itens_compra ic ON ic.ID_Compra=c.ID_Compra
 GROUP BY c.ID_Compra,c.Valor_Total
 HAVING ABS(c.Valor_Total-SUM(ic.Quantidade*ic.Custo_Unit))>0.005
) d; -- esperado 0
SELECT COUNT(*) AS Estoques_Divergentes
FROM (
 SELECT e.ID_Loja,e.ID_Produto,e.Quantidade,
 COALESCE(SUM(CASE WHEN m.Tipo_Movimentacao IN ('ENTRADA','AJUSTE') THEN m.Quantidade
                   ELSE -m.Quantidade END),0) AS Saldo_Movimentos
 FROM banco_v4.estoque e
 LEFT JOIN banco_v4.movimentacoes_estoque m ON m.ID_Loja=e.ID_Loja AND m.ID_Produto=e.ID_Produto
 GROUP BY e.ID_Loja,e.ID_Produto,e.Quantidade
 HAVING e.Quantidade <> Saldo_Movimentos
) d; -- esperado 0
SELECT COUNT(*) AS Pedidos_Com_Totais_Divergentes
FROM (
 SELECT p.ID_Pedido,p.Valor_Total
 FROM banco_v4.pedidos p LEFT JOIN banco_v4.itens_pedido i ON i.ID_Pedido=p.ID_Pedido
 GROUP BY p.ID_Pedido,p.Valor_Total
 HAVING COUNT(i.ID_Item)=0 OR ABS(p.Valor_Total-
    COALESCE(SUM(i.Quantidade*i.Preco_Unit-i.Desconto_Valor+i.Ajuste_Valor),0))>0.005
) d; -- esperado 0
SELECT COUNT(*) AS FKs_Duplicadas
FROM (
 SELECT CONSTRAINT_NAME FROM information_schema.REFERENTIAL_CONSTRAINTS
 WHERE CONSTRAINT_SCHEMA='banco_v4' GROUP BY CONSTRAINT_NAME HAVING COUNT(*)>1
) d; -- esperado 0
