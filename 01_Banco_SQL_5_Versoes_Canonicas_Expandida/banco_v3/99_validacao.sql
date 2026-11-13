-- Validação da banco_v3, sem necessidade da v2 instalada.
USE banco_v3;
SELECT 'tabelas' AS metrica,COUNT(*) AS valor
FROM information_schema.tables WHERE TABLE_SCHEMA='banco_v3' AND TABLE_TYPE='BASE TABLE';
SELECT Origem_Registro,COUNT(*) AS Pedidos,COALESCE(SUM(Valor_Total),0) AS Receita
FROM pedidos GROUP BY Origem_Registro;
SELECT COUNT(*) AS Itens,COUNT(DISTINCT ID_Pedido) AS Pedidos_Com_Itens FROM itens_pedido;
SELECT COUNT(*) AS Pagamentos FROM pagamentos;
SELECT COUNT(*) AS Historicos_Com_Pagamentos
FROM pagamentos AS pg JOIN pedidos AS p ON p.ID_Pedido=pg.ID_Pedido
WHERE p.Origem_Registro='LEGADO_V2';
SELECT COUNT(*) AS Pedidos_Com_Vendedor_Loja_Incoerentes
FROM pedidos AS p LEFT JOIN vendedores AS v
    ON v.ID_Vendedor=p.ID_Vendedor AND v.ID_Loja=p.ID_Loja
WHERE p.Origem_Registro='OPERACAO_V3' AND v.ID_Vendedor IS NULL;
SELECT COUNT(*) AS Pedidos_Com_Totais_Incoerentes
FROM (
 SELECT p.ID_Pedido
 FROM pedidos AS p LEFT JOIN itens_pedido AS i ON i.ID_Pedido=p.ID_Pedido
 GROUP BY p.ID_Pedido,p.Valor_Total
 HAVING COUNT(i.ID_Item)=0 OR ABS(p.Valor_Total-
      COALESCE(SUM(i.Quantidade*i.Preco_Unit-i.Desconto_Valor+i.Ajuste_Valor),0))>0.005
) AS divergencias;
SELECT COUNT(*) AS Itens_Orfaos
FROM itens_pedido AS i LEFT JOIN pedidos AS p ON p.ID_Pedido=i.ID_Pedido
WHERE p.ID_Pedido IS NULL;
SELECT COUNT(*) AS FKs_Nomes_Duplicados
FROM (
 SELECT CONSTRAINT_NAME,COUNT(*) AS Total
 FROM information_schema.REFERENTIAL_CONSTRAINTS
 WHERE CONSTRAINT_SCHEMA='banco_v3'
 GROUP BY CONSTRAINT_NAME HAVING COUNT(*)>1
) AS nomes;
SELECT ID_Pedido,COUNT(*) AS Qtd_Itens
FROM itens_pedido GROUP BY ID_Pedido HAVING COUNT(*)>1 ORDER BY ID_Pedido;
-- Para o conjunto canônico: 12 tabelas, 374 históricos, 16 novos,
-- 414 itens (374 + 40), 16 pagamentos, todos os contadores de incoerência = 0.
