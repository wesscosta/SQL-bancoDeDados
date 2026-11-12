USE banco_v3;
SHOW TABLES; SELECT COUNT(*) FROM pedidos; SELECT COUNT(*) FROM itens_pedido; SELECT ID_Pedido,COUNT(*) Itens FROM itens_pedido GROUP BY ID_Pedido HAVING COUNT(*)>1;
