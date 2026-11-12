USE banco_v4;


-- ============================================================
-- Evolução canônica: banco_v3 -> banco_v4
-- Suprimentos, compras, estoque e rastreabilidade
-- ============================================================

CREATE TABLE fornecedores (
    ID_Fornecedor INT NOT NULL AUTO_INCREMENT,
    Nome_Fornecedor VARCHAR(120) NOT NULL,
    CNPJ VARCHAR(18) NULL,
    Telefone VARCHAR(20) NULL,
    Email VARCHAR(120) NULL,
    PRIMARY KEY (ID_Fornecedor),
    UNIQUE KEY uk_fornecedores_cnpj (CNPJ),
    UNIQUE KEY uk_fornecedores_email (Email)
) ENGINE=InnoDB;

INSERT INTO fornecedores (Nome_Fornecedor,CNPJ,Telefone,Email) VALUES
('Tech Supply Brasil','10.000.001/0001-01','(11) 3000-0001','contato01@fornecedor.local'),
('Nordeste Componentes','10.000.002/0001-02','(85) 3000-0002','contato02@fornecedor.local'),
('Sul Digital','10.000.003/0001-03','(41) 3000-0003','contato03@fornecedor.local'),
('Minas Hardware','10.000.004/0001-04','(31) 3000-0004','contato04@fornecedor.local'),
('Bahia Tech','10.000.005/0001-05','(71) 3000-0005','contato05@fornecedor.local'),
('Goiás Distribuição','10.000.006/0001-06','(62) 3000-0006','contato06@fornecedor.local'),
('Rio Componentes','10.000.007/0001-07','(21) 3000-0007','contato07@fornecedor.local'),
('Paulista Devices','10.000.008/0001-08','(11) 3000-0008','contato08@fornecedor.local'),
('Conecta Informática','10.000.009/0001-09','(85) 3000-0009','contato09@fornecedor.local'),
('Prime Hardware','10.000.010/0001-10','(31) 3000-0010','contato10@fornecedor.local'),
('Global Periféricos','10.000.011/0001-11','(41) 3000-0011','contato11@fornecedor.local'),
('Data Commerce','10.000.012/0001-12','(71) 3000-0012','contato12@fornecedor.local'),
('Central Notebook','10.000.013/0001-13','(62) 3000-0013','contato13@fornecedor.local'),
('Audio Pro Supply','10.000.014/0001-14','(21) 3000-0014','contato14@fornecedor.local'),
('Office Gamer Parts','10.000.015/0001-15','(11) 3000-0015','contato15@fornecedor.local');

-- N:N produtos <-> fornecedores.
CREATE TABLE produto_fornecedor (
    ID_Produto INT NOT NULL,
    ID_Fornecedor INT NOT NULL,
    Preco_Compra DECIMAL(12,2) NOT NULL,
    Fornecedor_Principal BOOLEAN NOT NULL DEFAULT FALSE,
    Prazo_Dias SMALLINT NULL,
    PRIMARY KEY (ID_Produto, ID_Fornecedor),
    CONSTRAINT ck_produto_fornecedor_preco CHECK (Preco_Compra > 0),
    CONSTRAINT ck_produto_fornecedor_prazo CHECK (Prazo_Dias IS NULL OR Prazo_Dias >= 0),
    CONSTRAINT fk_produto_fornecedor_produto FOREIGN KEY (ID_Produto) REFERENCES produtos(ID_Produto),
    CONSTRAINT fk_produto_fornecedor_fornecedor FOREIGN KEY (ID_Fornecedor) REFERENCES fornecedores(ID_Fornecedor)
) ENGINE=InnoDB;

INSERT INTO produto_fornecedor (ID_Produto,ID_Fornecedor,Preco_Compra,Fornecedor_Principal,Prazo_Dias)
SELECT ID_Produto, 1+MOD(ID_Produto-1,15), ROUND(COALESCE(Custo_Unit,Preco_Unit*0.55)*0.95,2), TRUE, 5+MOD(ID_Produto,8)
FROM produtos;
INSERT IGNORE INTO produto_fornecedor (ID_Produto,ID_Fornecedor,Preco_Compra,Fornecedor_Principal,Prazo_Dias)
SELECT ID_Produto, 1+MOD(ID_Produto+4,15), ROUND(COALESCE(Custo_Unit,Preco_Unit*0.55)*1.03,2), FALSE, 7+MOD(ID_Produto,10)
FROM produtos;

CREATE TABLE status_compra (
    ID_Status_Compra TINYINT NOT NULL,
    Status_Compra VARCHAR(30) NOT NULL,
    PRIMARY KEY (ID_Status_Compra),
    UNIQUE KEY uk_status_compra_nome (Status_Compra)
) ENGINE=InnoDB;
INSERT INTO status_compra VALUES (1,'Aberta'),(2,'Recebida'),(3,'Cancelada');

CREATE TABLE compras (
    ID_Compra INT NOT NULL AUTO_INCREMENT,
    Data_Compra DATETIME NOT NULL,
    ID_Fornecedor INT NOT NULL,
    ID_Loja INT NOT NULL,
    ID_Status_Compra TINYINT NOT NULL,
    Valor_Total DECIMAL(12,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (ID_Compra),
    KEY idx_compras_fornecedor (ID_Fornecedor),
    KEY idx_compras_loja (ID_Loja),
    KEY idx_compras_data (Data_Compra),
    CONSTRAINT ck_compras_valor_total CHECK (Valor_Total >= 0),
    CONSTRAINT fk_compras_fornecedor FOREIGN KEY (ID_Fornecedor) REFERENCES fornecedores(ID_Fornecedor),
    CONSTRAINT fk_compras_loja FOREIGN KEY (ID_Loja) REFERENCES lojas(ID_Loja),
    UNIQUE KEY uk_compras_compra_fornecedor (ID_Compra, ID_Fornecedor),
    CONSTRAINT fk_compras_status FOREIGN KEY (ID_Status_Compra) REFERENCES status_compra(ID_Status_Compra)
) ENGINE=InnoDB;

-- N:N compras <-> produtos.
CREATE TABLE itens_compra (
    ID_Item_Compra INT NOT NULL AUTO_INCREMENT,
    ID_Compra INT NOT NULL,
    ID_Produto INT NOT NULL,
    ID_Fornecedor INT NOT NULL,
    Quantidade INT NOT NULL,
    Custo_Unit DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (ID_Item_Compra),
    UNIQUE KEY uk_itens_compra_produto (ID_Compra, ID_Produto),
    KEY idx_itens_compra_produto (ID_Produto),
    KEY idx_itens_compra_fornecedor (ID_Fornecedor),
    CONSTRAINT ck_itens_compra_qtd CHECK (Quantidade > 0),
    CONSTRAINT ck_itens_compra_custo CHECK (Custo_Unit > 0),
    CONSTRAINT fk_itens_compra_compra_fornecedor FOREIGN KEY (ID_Compra,ID_Fornecedor)
        REFERENCES compras(ID_Compra,ID_Fornecedor),
    CONSTRAINT fk_itens_compra_produto_fornecedor FOREIGN KEY (ID_Produto,ID_Fornecedor)
        REFERENCES produto_fornecedor(ID_Produto,ID_Fornecedor)
) ENGINE=InnoDB;

-- N:N lojas <-> produtos materializado pelo saldo atual.
CREATE TABLE estoque (
    ID_Loja INT NOT NULL,
    ID_Produto INT NOT NULL,
    Quantidade INT NOT NULL DEFAULT 0,
    Estoque_Minimo INT NOT NULL DEFAULT 0,
    PRIMARY KEY (ID_Loja, ID_Produto),
    CONSTRAINT ck_estoque_qtd CHECK (Quantidade >= 0),
    CONSTRAINT ck_estoque_minimo CHECK (Estoque_Minimo >= 0),
    CONSTRAINT fk_estoque_loja FOREIGN KEY (ID_Loja) REFERENCES lojas(ID_Loja),
    CONSTRAINT fk_estoque_produto FOREIGN KEY (ID_Produto) REFERENCES produtos(ID_Produto)
) ENGINE=InnoDB;

INSERT INTO estoque (ID_Loja,ID_Produto,Quantidade,Estoque_Minimo)
SELECT l.ID_Loja,p.ID_Produto,20+MOD(l.ID_Loja*p.ID_Produto,81),10+MOD(p.ID_Produto,11)
FROM lojas l CROSS JOIN produtos p;

CREATE TABLE historico_status_pedido (
    ID_Historico INT NOT NULL AUTO_INCREMENT,
    ID_Pedido INT NOT NULL,
    ID_Status TINYINT NOT NULL,
    Data_Status DATETIME NOT NULL,
    Observacao VARCHAR(255) NULL,
    PRIMARY KEY (ID_Historico),
    KEY idx_hist_status_pedido (ID_Pedido,Data_Status),
    CONSTRAINT fk_hist_status_pedido FOREIGN KEY (ID_Pedido) REFERENCES pedidos(ID_Pedido),
    CONSTRAINT fk_hist_status_status FOREIGN KEY (ID_Status) REFERENCES status_pedido(ID_Status)
) ENGINE=InnoDB;

INSERT INTO historico_status_pedido (ID_Pedido,ID_Status,Data_Status,Observacao)
SELECT ID_Pedido,ID_Status,Data_Pedido,'Estado migrado para histórico na criação da v4'
FROM pedidos;

CREATE TABLE movimentacoes_estoque (
    ID_Movimentacao BIGINT NOT NULL AUTO_INCREMENT,
    ID_Loja INT NOT NULL,
    ID_Produto INT NOT NULL,
    Tipo_Movimentacao VARCHAR(20) NOT NULL,
    Quantidade INT NOT NULL,
    Data_Movimentacao DATETIME NOT NULL,
    ID_Pedido INT NULL,
    ID_Compra INT NULL,
    Observacao VARCHAR(255) NULL,
    PRIMARY KEY (ID_Movimentacao),
    KEY idx_mov_estoque_produto_loja (ID_Produto,ID_Loja),
    KEY idx_mov_estoque_data (Data_Movimentacao),
    CONSTRAINT ck_mov_estoque_tipo CHECK (Tipo_Movimentacao IN ('ENTRADA','SAIDA','AJUSTE')),
    CONSTRAINT ck_mov_estoque_qtd CHECK (Quantidade > 0),
    CONSTRAINT ck_mov_estoque_origem CHECK (
        (Tipo_Movimentacao='AJUSTE' AND ID_Pedido IS NULL AND ID_Compra IS NULL) OR
        (Tipo_Movimentacao='ENTRADA' AND ID_Pedido IS NULL AND ID_Compra IS NOT NULL) OR
        (Tipo_Movimentacao='SAIDA' AND ID_Pedido IS NOT NULL AND ID_Compra IS NULL)
    ),
    CONSTRAINT fk_mov_estoque_saldo FOREIGN KEY (ID_Loja,ID_Produto) REFERENCES estoque(ID_Loja,ID_Produto),
    CONSTRAINT fk_mov_estoque_pedido FOREIGN KEY (ID_Pedido) REFERENCES pedidos(ID_Pedido),
    CONSTRAINT fk_mov_estoque_compra FOREIGN KEY (ID_Compra) REFERENCES compras(ID_Compra)
) ENGINE=InnoDB;

-- O saldo inicial é registrado como ajuste rastreável.
INSERT INTO movimentacoes_estoque (ID_Loja,ID_Produto,Tipo_Movimentacao,Quantidade,Data_Movimentacao,Observacao)
SELECT ID_Loja,ID_Produto,'AJUSTE',Quantidade,'2020-01-01 08:00:00','Saldo inicial da v4'
FROM estoque WHERE Quantidade > 0;

INSERT INTO compras (ID_Compra,Data_Compra,ID_Fornecedor,ID_Loja,ID_Status_Compra,Valor_Total) VALUES
(1,'2020-01-01 09:03:00',1,4,2,13521.76),
(2,'2020-01-02 09:06:00',2,7,2,8653.30),
(3,'2020-01-03 09:09:00',3,2,2,10257.00),
(4,'2020-01-04 09:12:00',4,5,2,15648.45),
(5,'2020-01-05 09:15:00',5,8,2,17586.20),
(6,'2020-01-06 09:18:00',6,3,2,11147.76),
(7,'2020-01-07 09:21:00',7,6,2,23753.60),
(8,'2020-01-08 09:24:00',8,1,2,4186.92),
(9,'2020-01-09 09:27:00',9,4,2,6171.48),
(10,'2020-01-10 09:30:00',10,7,2,5613.94),
(11,'2020-01-11 09:33:00',11,2,2,4120.40),
(12,'2020-01-12 09:36:00',12,5,2,10584.18),
(13,'2020-01-13 09:39:00',13,8,2,7987.56),
(14,'2020-01-14 09:42:00',14,3,2,13082.16),
(15,'2020-01-15 09:45:00',15,6,2,14230.50),
(16,'2020-01-16 09:48:00',1,1,2,25861.20);
INSERT INTO itens_compra (ID_Compra,ID_Produto,ID_Fornecedor,Quantidade,Custo_Unit) VALUES
(1,1,1,6,927.36),
(1,16,1,7,1136.80),
(2,2,2,7,960.40),
(2,12,2,9,214.50),
(3,3,3,8,90.00),
(3,13,3,11,867.00),
(4,4,4,9,132.09),
(4,14,4,13,1112.28),
(5,5,5,10,100.46),
(5,15,5,15,1105.44),
(6,6,6,11,507.60),
(6,1,6,6,927.36),
(7,7,7,12,1339.20),
(7,2,7,8,960.40),
(8,8,8,13,252.84),
(8,3,8,10,90.00),
(9,9,9,14,327.60),
(9,4,9,12,132.09),
(10,10,10,15,280.50),
(10,5,10,14,100.46),
(11,11,11,5,316.48),
(11,6,11,5,507.60),
(12,12,12,6,201.63),
(12,7,12,7,1339.20),
(13,13,13,7,816.00),
(13,8,13,9,252.84),
(14,14,14,8,1184.82),
(14,9,14,11,327.60),
(15,15,15,9,1176.00),
(15,10,15,13,280.50),
(16,1,1,10,985.32),
(16,16,1,15,1067.20);

-- Entradas de compra geram movimento e atualizam o saldo atual.
INSERT INTO movimentacoes_estoque (
    ID_Loja,ID_Produto,Tipo_Movimentacao,Quantidade,Data_Movimentacao,ID_Compra,Observacao
)
SELECT c.ID_Loja,ic.ID_Produto,'ENTRADA',ic.Quantidade,c.Data_Compra,c.ID_Compra,'Recebimento de compra'
FROM compras c JOIN itens_compra ic ON ic.ID_Compra=c.ID_Compra
WHERE c.ID_Status_Compra=2;

UPDATE estoque e
JOIN (
    SELECT c.ID_Loja,ic.ID_Produto,SUM(ic.Quantidade) AS Qtd_Entrada
    FROM compras c JOIN itens_compra ic ON ic.ID_Compra=c.ID_Compra
    WHERE c.ID_Status_Compra=2
    GROUP BY c.ID_Loja,ic.ID_Produto
) x ON x.ID_Loja=e.ID_Loja AND x.ID_Produto=e.ID_Produto
SET e.Quantidade=e.Quantidade+x.Qtd_Entrada;

-- Algumas saídas históricas de venda para demonstrar rastreabilidade.
INSERT INTO movimentacoes_estoque (
    ID_Loja,ID_Produto,Tipo_Movimentacao,Quantidade,Data_Movimentacao,ID_Pedido,Observacao
)
SELECT p.ID_Loja,ip.ID_Produto,'SAIDA',ip.Quantidade,p.Data_Pedido,p.ID_Pedido,'Saída por venda'
FROM pedidos p JOIN itens_pedido ip ON ip.ID_Pedido=p.ID_Pedido
WHERE p.ID_Pedido >= 375;

UPDATE estoque e
JOIN (
    SELECT p.ID_Loja,ip.ID_Produto,SUM(ip.Quantidade) AS Qtd_Saida
    FROM pedidos p JOIN itens_pedido ip ON ip.ID_Pedido=p.ID_Pedido
    WHERE p.ID_Pedido >= 375
    GROUP BY p.ID_Loja,ip.ID_Produto
) x ON x.ID_Loja=e.ID_Loja AND x.ID_Produto=e.ID_Produto
SET e.Quantidade=GREATEST(0,e.Quantidade-x.Qtd_Saida);

-- Validações essenciais do novo domínio.
SELECT ID_Pedido,COUNT(*) AS Itens FROM itens_pedido GROUP BY ID_Pedido HAVING COUNT(*)>1;
SELECT ID_Compra,COUNT(*) AS Itens FROM itens_compra GROUP BY ID_Compra HAVING COUNT(*)>1;
SELECT COUNT(*) AS Relacoes_Produto_Fornecedor FROM produto_fornecedor;
SELECT COUNT(*) AS Saldos_Estoque FROM estoque;
