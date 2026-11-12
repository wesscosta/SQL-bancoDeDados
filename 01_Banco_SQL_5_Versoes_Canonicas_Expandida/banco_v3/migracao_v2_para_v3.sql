USE banco_v3;


-- ============================================================
-- Evolução canônica: banco_v2 -> banco_v3
-- Normalização da venda + operação comercial
-- ============================================================

-- A tabela pedidos da v2 representa, na prática, uma linha de venda.
-- Preservamos temporariamente os dados para migrar o grão.
RENAME TABLE pedidos TO pedidos_legacy;

CREATE TABLE status_pedido (
    ID_Status TINYINT NOT NULL,
    Status_Pedido VARCHAR(30) NOT NULL,
    PRIMARY KEY (ID_Status),
    UNIQUE KEY uk_status_pedido_nome (Status_Pedido)
) ENGINE=InnoDB;

INSERT INTO status_pedido VALUES
(1,'Pendente'),(2,'Processando'),(3,'Cancelado'),(4,'Concluído');

CREATE TABLE formas_pagamento (
    ID_Forma_Pagamento TINYINT NOT NULL,
    Forma_Pagamento VARCHAR(40) NOT NULL,
    PRIMARY KEY (ID_Forma_Pagamento),
    UNIQUE KEY uk_formas_pagamento_nome (Forma_Pagamento)
) ENGINE=InnoDB;

INSERT INTO formas_pagamento VALUES
(1,'Dinheiro'),(2,'Pix'),(3,'Cartão de crédito'),(4,'Cartão de débito'),(5,'Boleto');

CREATE TABLE status_pagamento (
    ID_Status_Pagamento TINYINT NOT NULL,
    Status_Pagamento VARCHAR(30) NOT NULL,
    PRIMARY KEY (ID_Status_Pagamento),
    UNIQUE KEY uk_status_pagamento_nome (Status_Pagamento)
) ENGINE=InnoDB;

INSERT INTO status_pagamento VALUES
(1,'Pendente'),(2,'Aprovado'),(3,'Estornado');

-- Permite validar que o vendedor pertence à mesma loja registrada no pedido.
ALTER TABLE vendedores
ADD CONSTRAINT uk_vendedores_vendedor_loja UNIQUE (ID_Vendedor, ID_Loja);

-- Cabeçalho do pedido: uma linha por pedido, sem produto no cabeçalho.
CREATE TABLE pedidos (
    ID_Pedido INT NOT NULL,
    Data_Pedido DATETIME NOT NULL,
    ID_Loja INT NOT NULL,
    ID_Cliente INT NOT NULL,
    ID_Vendedor INT NOT NULL,
    ID_Status TINYINT NOT NULL,
    Valor_Total DECIMAL(12,2) NOT NULL,
    Custo_Total DECIMAL(12,2) NULL,
    Observacao VARCHAR(255) NULL,
    PRIMARY KEY (ID_Pedido),
    KEY idx_pedidos_cliente (ID_Cliente),
    KEY idx_pedidos_loja (ID_Loja),
    KEY idx_pedidos_data (Data_Pedido),
    KEY idx_pedidos_status (ID_Status),
    CONSTRAINT ck_pedidos_valor_total CHECK (Valor_Total >= 0),
    CONSTRAINT ck_pedidos_custo_total CHECK (Custo_Total IS NULL OR Custo_Total >= 0),
    CONSTRAINT fk_pedidos_clientes FOREIGN KEY (ID_Cliente) REFERENCES clientes(ID_Cliente),
    CONSTRAINT fk_pedidos_lojas FOREIGN KEY (ID_Loja) REFERENCES lojas(ID_Loja),
    CONSTRAINT fk_pedidos_status FOREIGN KEY (ID_Status) REFERENCES status_pedido(ID_Status),
    CONSTRAINT fk_pedidos_vendedor_loja FOREIGN KEY (ID_Vendedor, ID_Loja)
        REFERENCES vendedores(ID_Vendedor, ID_Loja)
) ENGINE=InnoDB;

-- Entidade associativa: resolve o relacionamento N:N pedidos <-> produtos.
CREATE TABLE itens_pedido (
    ID_Item INT NOT NULL AUTO_INCREMENT,
    ID_Pedido INT NOT NULL,
    ID_Produto INT NOT NULL,
    Quantidade INT NOT NULL,
    Preco_Unit DECIMAL(10,2) NOT NULL,
    Custo_Unit DECIMAL(10,2) NULL,
    Desconto_Valor DECIMAL(12,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (ID_Item),
    UNIQUE KEY uk_itens_pedido_produto (ID_Pedido, ID_Produto),
    KEY idx_itens_pedido_produto (ID_Produto),
    CONSTRAINT ck_itens_pedido_qtd CHECK (Quantidade > 0),
    CONSTRAINT ck_itens_pedido_preco CHECK (Preco_Unit >= 0),
    CONSTRAINT ck_itens_pedido_custo CHECK (Custo_Unit IS NULL OR Custo_Unit >= 0),
    CONSTRAINT ck_itens_pedido_desconto CHECK (
        Desconto_Valor >= 0 AND Desconto_Valor <= Quantidade * Preco_Unit
    ),
    CONSTRAINT fk_itens_pedido_pedido FOREIGN KEY (ID_Pedido) REFERENCES pedidos(ID_Pedido),
    CONSTRAINT fk_itens_pedido_produto FOREIGN KEY (ID_Produto) REFERENCES produtos(ID_Produto)
) ENGINE=InnoDB;

-- Cada linha antiga vira inicialmente um pedido com um item: preservação sem inventar agrupamentos históricos.
INSERT INTO pedidos (
    ID_Pedido, Data_Pedido, ID_Loja, ID_Cliente, ID_Vendedor, ID_Status,
    Valor_Total, Custo_Total, Observacao
)
SELECT
    pl.ID_Pedido,
    TIMESTAMP(pl.Data_Venda, '12:00:00'),
    pl.ID_Loja,
    pl.ID_Cliente,
    v.ID_Vendedor,
    CASE WHEN MOD(pl.ID_Pedido,20)=0 THEN 3 ELSE 4 END,
    pl.Receita_Venda,
    pl.Custo_Venda,
    'Migrado da estrutura v2: um item por registro histórico'
FROM pedidos_legacy AS pl
JOIN (
    SELECT ID_Loja, MIN(ID_Vendedor) AS ID_Vendedor
    FROM vendedores
    GROUP BY ID_Loja
) AS v ON v.ID_Loja = pl.ID_Loja;

INSERT INTO itens_pedido (
    ID_Pedido, ID_Produto, Quantidade, Preco_Unit, Custo_Unit, Desconto_Valor
)
SELECT
    ID_Pedido, ID_Produto, Qtd_Vendida, Preco_Unit, Custo_Unit, 0
FROM pedidos_legacy;

CREATE TABLE pagamentos (
    ID_Pagamento INT NOT NULL AUTO_INCREMENT,
    ID_Pedido INT NOT NULL,
    ID_Forma_Pagamento TINYINT NOT NULL,
    ID_Status_Pagamento TINYINT NOT NULL,
    Valor DECIMAL(12,2) NOT NULL,
    Data_Pagamento DATETIME NULL,
    PRIMARY KEY (ID_Pagamento),
    KEY idx_pagamentos_pedido (ID_Pedido),
    CONSTRAINT ck_pagamentos_valor CHECK (Valor > 0),
    CONSTRAINT fk_pagamentos_pedido FOREIGN KEY (ID_Pedido) REFERENCES pedidos(ID_Pedido),
    CONSTRAINT fk_pagamentos_forma FOREIGN KEY (ID_Forma_Pagamento)
        REFERENCES formas_pagamento(ID_Forma_Pagamento),
    CONSTRAINT fk_pagamentos_status FOREIGN KEY (ID_Status_Pagamento)
        REFERENCES status_pagamento(ID_Status_Pagamento)
) ENGINE=InnoDB;

INSERT INTO pagamentos (
    ID_Pedido, ID_Forma_Pagamento, ID_Status_Pagamento, Valor, Data_Pagamento
)
SELECT
    ID_Pedido,
    1 + MOD(ID_Pedido - 1, 5),
    CASE WHEN ID_Status = 3 THEN 3 ELSE 2 END,
    Valor_Total,
    CASE WHEN ID_Status = 3 THEN NULL ELSE DATE_ADD(Data_Pedido, INTERVAL 5 MINUTE) END
FROM pedidos;

DROP TABLE pedidos_legacy;

-- Pedidos sintéticos multi-itens para evidenciar o relacionamento N:N.
INSERT INTO pedidos (ID_Pedido,Data_Pedido,ID_Loja,ID_Cliente,ID_Vendedor,ID_Status,Valor_Total,Custo_Total,Observacao) VALUES
(375,'2020-01-01 10:45:00',6,26,17,4,10000.00,4444.00,'Pedido multi-itens de demonstração'),
(376,'2020-01-02 10:52:00',1,33,1,4,8790.00,3517.30,'Pedido multi-itens de demonstração'),
(377,'2020-01-03 10:59:00',4,40,6,4,7700.00,3141.00,'Pedido multi-itens de demonstração'),
(378,'2020-01-04 10:06:00',7,47,19,2,7130.00,2075.00,'Pedido multi-itens de demonstração'),
(379,'2020-01-05 10:13:00',2,54,2,4,2510.00,1118.00,'Pedido multi-itens de demonstração'),
(380,'2020-01-06 10:20:00',5,61,15,4,10250.00,3558.50,'Pedido multi-itens de demonstração'),
(381,'2020-01-07 10:27:00',8,68,21,4,6440.00,2287.60,'Pedido multi-itens de demonstração'),
(382,'2020-01-08 10:34:00',3,75,5,4,16290.00,6878.00,'Pedido multi-itens de demonstração'),
(383,'2020-01-09 10:41:00',6,82,17,4,8630.00,2566.50,'Pedido multi-itens de demonstração'),
(384,'2020-01-10 10:48:00',1,89,1,4,6020.00,2578.50,'Pedido multi-itens de demonstração'),
(385,'2020-01-11 10:55:00',4,96,6,2,6180.00,1947.60,'Pedido multi-itens de demonstração'),
(386,'2020-01-12 10:02:00',7,3,19,4,15400.00,5702.00,'Pedido multi-itens de demonstração'),
(387,'2020-01-13 10:09:00',2,10,2,4,7150.00,2590.00,'Pedido multi-itens de demonstração'),
(388,'2020-01-14 10:16:00',5,17,15,4,2710.00,1014.60,'Pedido multi-itens de demonstração'),
(389,'2020-01-15 10:23:00',8,24,21,4,7845.00,1975.00,'Pedido multi-itens de demonstração'),
(390,'2020-01-16 10:30:00',3,31,5,4,18600.00,5832.00,'Pedido multi-itens de demonstração');
INSERT INTO itens_pedido (ID_Pedido,ID_Produto,Quantidade,Preco_Unit,Custo_Unit,Desconto_Valor) VALUES
(375,4,2,350.00,129.50,0.00),
(375,7,3,3100.00,1395.00,0.00),
(376,9,3,780.00,327.60,0.00),
(376,12,1,650.00,214.50,0.00),
(376,16,2,2900.00,1160.00,0.00),
(377,14,1,3100.00,1209.00,0.00),
(377,1,2,2300.00,966.00,0.00),
(378,3,2,450.00,90.00,0.00),
(378,6,3,1800.00,540.00,270.00),
(378,10,1,1100.00,275.00,0.00),
(379,8,3,600.00,258.00,90.00),
(379,11,1,800.00,344.00,0.00),
(380,13,1,3400.00,850.00,0.00),
(380,16,2,2900.00,1160.00,0.00),
(380,4,3,350.00,129.50,0.00),
(381,2,2,2800.00,980.00,0.00),
(381,5,3,280.00,109.20,0.00),
(382,7,3,3100.00,1395.00,0.00),
(382,10,1,1100.00,275.00,0.00),
(382,14,2,3100.00,1209.00,310.00),
(383,12,1,650.00,214.50,0.00),
(383,15,2,4200.00,1176.00,420.00),
(384,1,2,2300.00,966.00,230.00),
(384,4,3,350.00,129.50,0.00),
(384,8,1,600.00,258.00,0.00),
(385,6,3,1800.00,540.00,0.00),
(385,9,1,780.00,327.60,0.00),
(386,11,1,800.00,344.00,0.00),
(386,14,2,3100.00,1209.00,0.00),
(386,2,3,2800.00,980.00,0.00),
(387,16,2,2900.00,1160.00,0.00),
(387,3,3,450.00,90.00,0.00),
(388,5,3,280.00,109.20,0.00),
(388,8,1,600.00,258.00,30.00),
(388,12,2,650.00,214.50,0.00),
(389,10,1,1100.00,275.00,55.00),
(389,13,2,3400.00,850.00,0.00),
(390,15,2,4200.00,1176.00,0.00),
(390,2,3,2800.00,980.00,0.00),
(390,6,1,1800.00,540.00,0.00);
INSERT INTO pagamentos (ID_Pedido,ID_Forma_Pagamento,ID_Status_Pagamento,Valor,Data_Pagamento) VALUES
(375,1,2,10000.00,'2020-01-01 10:45:00'),
(376,2,2,8790.00,'2020-01-02 10:52:00'),
(377,3,2,7700.00,'2020-01-03 10:59:00'),
(378,4,2,7130.00,'2020-01-04 10:06:00'),
(379,5,2,2510.00,'2020-01-05 10:13:00'),
(380,1,2,10250.00,'2020-01-06 10:20:00'),
(381,2,2,6440.00,'2020-01-07 10:27:00'),
(382,3,2,16290.00,'2020-01-08 10:34:00'),
(383,4,2,8630.00,'2020-01-09 10:41:00'),
(384,5,2,6020.00,'2020-01-10 10:48:00'),
(385,1,2,6180.00,'2020-01-11 10:55:00'),
(386,2,2,15400.00,'2020-01-12 10:02:00'),
(387,3,2,7150.00,'2020-01-13 10:09:00'),
(388,4,2,2710.00,'2020-01-14 10:16:00'),
(389,5,2,7845.00,'2020-01-15 10:23:00'),
(390,1,2,18600.00,'2020-01-16 10:30:00');

-- Validação do grão: pedidos multi-itens devem existir.
SELECT ID_Pedido, COUNT(*) AS Qtd_Itens
FROM itens_pedido
GROUP BY ID_Pedido
HAVING COUNT(*) > 1
ORDER BY ID_Pedido;
