USE banco_v5;
SHOW TABLES; SELECT COUNT(*) FROM clientes; SELECT COUNT(*) FROM produtos; SELECT COUNT(*) FROM pedidos; SELECT COUNT(*) FROM itens_pedido; EXPLAIN SELECT p.ID_Pedido,p.Data_Pedido FROM pedidos p WHERE p.Data_Pedido >= '2024-01-01';
