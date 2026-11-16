-- Execute em uma instancia MySQL LOCAL com banco_v3; nao use instancia compartilhada.
-- A criacao desta tabela modifica apenas a estrutura da banco_v3 deste aluno.
USE banco_v3;
CREATE TABLE IF NOT EXISTS portal_ids_pedido (
    ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY
) ENGINE=InnoDB;
-- Reserva o maior ID existente na primeira execucao. Reexecutar nao duplica dados.
-- Depois disso, novos pedidos devem sempre reservar ID em portal_ids_pedido.
INSERT INTO portal_ids_pedido (ID)
SELECT t.maior
FROM (SELECT COALESCE(MAX(ID_Pedido), 0) AS maior FROM pedidos) AS t
WHERE NOT EXISTS (SELECT 1 FROM portal_ids_pedido);
SELECT (SELECT MAX(ID_Pedido) FROM pedidos) AS ultimo_pedido,
       (SELECT MAX(ID) FROM portal_ids_pedido) AS ultima_reserva;
