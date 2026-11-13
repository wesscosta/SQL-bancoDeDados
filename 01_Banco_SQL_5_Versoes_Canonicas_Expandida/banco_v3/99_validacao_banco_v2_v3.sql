-- Validação cruzada entre bancos independentes v2 e v3.
-- Exige que ambos existam; não altera dados.
SELECT (SELECT COUNT(*) FROM banco_v2.pedidos) AS Origem,
       (SELECT COUNT(*) FROM banco_v3.pedidos WHERE Origem_Registro='LEGADO_V2') AS Cabecalhos,
       (SELECT COUNT(*) FROM banco_v3.itens_pedido AS i
        JOIN banco_v3.pedidos AS p ON p.ID_Pedido=i.ID_Pedido
        WHERE p.Origem_Registro='LEGADO_V2') AS Itens;
SELECT (SELECT COALESCE(SUM(Receita_Venda),0) FROM banco_v2.pedidos) AS Receita_v2,
       (SELECT COALESCE(SUM(Valor_Total),0) FROM banco_v3.pedidos
        WHERE Origem_Registro='LEGADO_V2') AS Receita_v3;
SELECT COUNT(*) AS Divergencias_Linha_A_Linha
FROM banco_v2.pedidos AS origem
LEFT JOIN banco_v3.pedidos AS cab ON cab.ID_Pedido=origem.ID_Pedido
LEFT JOIN banco_v3.itens_pedido AS item ON item.ID_Pedido=cab.ID_Pedido
WHERE cab.ID_Pedido IS NULL OR item.ID_Item IS NULL
   OR NOT (DATE(cab.Data_Pedido) <=> origem.Data_Venda)
   OR NOT (cab.ID_Cliente <=> origem.ID_Cliente)
   OR NOT (cab.ID_Loja <=> origem.ID_Loja)
   OR NOT (cab.Valor_Total <=> origem.Receita_Venda)
   OR NOT (cab.Custo_Total <=> origem.Custo_Venda)
   OR NOT (cab.ID_Vendedor IS NULL AND cab.ID_Status=5 AND cab.Origem_Registro='LEGADO_V2')
   OR NOT (item.ID_Produto <=> origem.ID_Produto)
   OR NOT (item.Quantidade <=> origem.Qtd_Vendida)
   OR NOT (item.Preco_Unit <=> origem.Preco_Unit)
   OR NOT (item.Custo_Unit <=> origem.Custo_Unit)
   OR NOT (item.Ajuste_Valor <=> (origem.Receita_Venda-origem.Qtd_Vendida*origem.Preco_Unit));
-- Esperado: origens=cabecalhos=itens; receitas iguais; zero divergências.
