-- Execute SOMENTE na copia de laboratorio banco_v3_lab, jamais no banco canônico.
USE banco_v3_lab;
-- Gerador concorrente para IDs de pedidos: AUTO_INCREMENT, sem MAX(ID)+1 em POST.
CREATE TABLE IF NOT EXISTS portal_ids_pedido (
    ID INT NOT NULL AUTO_INCREMENT PRIMARY KEY
) ENGINE=InnoDB;
-- Execute uma vez apos restaurar a copia; falha se nao existir pedido anterior.
-- Insere o maior ID já existente para reservar o intervalo historico.
INSERT INTO portal_ids_pedido (ID)
SELECT COALESCE(MAX(ID_Pedido),0) FROM pedidos
WHERE NOT EXISTS (SELECT 1 FROM portal_ids_pedido);
-- Conferir: proximo ID sera maior que MAX(ID_Pedido), sem alterar pedidos originais.
SELECT MAX(ID_Pedido) AS maior_pedido FROM pedidos;
SELECT MAX(ID) AS sequencia_reservada FROM portal_ids_pedido;
