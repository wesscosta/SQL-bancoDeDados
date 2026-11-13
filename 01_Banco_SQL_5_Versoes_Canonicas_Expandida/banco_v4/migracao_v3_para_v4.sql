-- Evolução com SCHEMAS INDEPENDENTES: banco_v3 -> banco_v4.
-- Execute em servidor que tenha banco_v3; falha se banco_v4 já existir.
-- Não apaga ou altera banco_v3. NÃO use junto ao arquivo completo.
SET NAMES utf8mb4;
CREATE DATABASE `banco_v4` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `banco_v4`;

CREATE TABLE `categorias` (
  `ID_Categoria` INT NOT NULL,
  `Categoria` VARCHAR(80) NOT NULL,
  PRIMARY KEY (`ID_Categoria`),
  UNIQUE KEY `uk_categorias_nome` (`Categoria`)
) ENGINE=InnoDB;

CREATE TABLE `locais` (
  `ID_Local` INT NOT NULL,
  `Cidade` VARCHAR(80) NOT NULL,
  `Estado` CHAR(2) NOT NULL,
  `Regiao` VARCHAR(30) NOT NULL,
  PRIMARY KEY (`ID_Local`),
  UNIQUE KEY `uk_locais_cidade_estado` (`Cidade`,`Estado`)
) ENGINE=InnoDB;

CREATE TABLE `clientes` (
  `ID_Cliente` INT NOT NULL,
  `Nome` VARCHAR(80) NOT NULL,
  `Sobrenome` VARCHAR(100) NOT NULL,
  `Data_Nascimento` DATE,
  `Estado_Civil` CHAR(1),
  `Sexo` CHAR(1),
  `Email` VARCHAR(150),
  `Telefone` VARCHAR(20),
  `Renda_Anual` DECIMAL(12,2),
  `Qtd_Filhos` INT DEFAULT 0,
  `Escolaridade` VARCHAR(60),
  PRIMARY KEY (`ID_Cliente`),
  UNIQUE KEY `uk_clientes_email` (`Email`),
  CHECK (`Qtd_Filhos` IS NULL OR `Qtd_Filhos` >= 0),
  CHECK (`Renda_Anual` IS NULL OR `Renda_Anual` >= 0)
) ENGINE=InnoDB;

CREATE TABLE `lojas` (
  `ID_Loja` INT NOT NULL,
  `Loja` VARCHAR(80) NOT NULL,
  `Gerente` VARCHAR(120),
  `Endereco` VARCHAR(255),
  `Num_Funcionarios` INT,
  `Telefone` VARCHAR(20),
  `ID_Local` INT NOT NULL,
  PRIMARY KEY (`ID_Loja`),
  CONSTRAINT `fk_lojas_locais` FOREIGN KEY (`ID_Local`) REFERENCES `locais` (`ID_Local`),
  CHECK (`Num_Funcionarios` IS NULL OR `Num_Funcionarios` >= 0)
) ENGINE=InnoDB;

CREATE TABLE `produtos` (
  `ID_Produto` INT NOT NULL,
  `Nome_Produto` VARCHAR(180) NOT NULL,
  `ID_Categoria` INT NOT NULL,
  `Marca_Produto` VARCHAR(80),
  `Num_Serie` VARCHAR(40),
  `Preco_Unit` DECIMAL(10,2) NOT NULL,
  `Custo_Unit` DECIMAL(10,2),
  PRIMARY KEY (`ID_Produto`),
  UNIQUE KEY `uk_produtos_num_serie` (`Num_Serie`),
  CONSTRAINT `fk_produtos_categorias` FOREIGN KEY (`ID_Categoria`) REFERENCES `categorias` (`ID_Categoria`),
  CHECK (`Preco_Unit` >= 0),
  CHECK (`Custo_Unit` IS NULL OR `Custo_Unit` >= 0)
) ENGINE=InnoDB;

CREATE TABLE `vendedores` (
  `ID_Vendedor` INT NOT NULL AUTO_INCREMENT,
  `Nome` VARCHAR(100) NOT NULL,
  `Email` VARCHAR(150),
  `Data_Nascimento` DATE,
  `ID_Loja` INT NOT NULL,
  PRIMARY KEY (`ID_Vendedor`),
  UNIQUE KEY `uk_vendedores_email` (`Email`),
  CONSTRAINT `fk_vendedores_lojas` FOREIGN KEY (`ID_Loja`) REFERENCES `lojas` (`ID_Loja`)
) ENGINE=InnoDB;

CREATE TABLE status_pedido (
    ID_Status TINYINT NOT NULL,
    Descricao VARCHAR(40) NOT NULL,
    PRIMARY KEY (ID_Status),
    CONSTRAINT uk_status_pedido_descricao UNIQUE (Descricao)
) ENGINE=InnoDB;

CREATE TABLE formas_pagamento (
    ID_Forma TINYINT NOT NULL,
    Descricao VARCHAR(40) NOT NULL,
    PRIMARY KEY (ID_Forma),
    CONSTRAINT uk_formas_pagamento_descricao UNIQUE (Descricao)
) ENGINE=InnoDB;

CREATE TABLE status_pagamento (
    ID_Status TINYINT NOT NULL,
    Descricao VARCHAR(40) NOT NULL,
    PRIMARY KEY (ID_Status),
    CONSTRAINT uk_status_pagamento_descricao UNIQUE (Descricao)
) ENGINE=InnoDB;

CREATE TABLE pedidos (
    ID_Pedido INT NOT NULL,
    Data_Pedido DATETIME NOT NULL,
    ID_Loja INT NOT NULL,
    ID_Cliente INT NOT NULL,
    ID_Vendedor INT NULL,
    ID_Status TINYINT NOT NULL,
    Valor_Total DECIMAL(12,2) NOT NULL,
    Custo_Total DECIMAL(12,2) NULL,
    Origem_Registro VARCHAR(16) NOT NULL,
    Observacao VARCHAR(255) NULL,
    PRIMARY KEY (ID_Pedido),
    KEY idx_pedidos_cliente (ID_Cliente),
    KEY idx_pedidos_loja (ID_Loja),
    KEY idx_pedidos_data (Data_Pedido),
    KEY idx_pedidos_status (ID_Status),
    KEY idx_pedidos_vendedor_loja (ID_Vendedor,ID_Loja),
    CONSTRAINT ck_pedidos_valor CHECK (Valor_Total >= 0),
    CONSTRAINT ck_pedidos_custo CHECK (Custo_Total IS NULL OR Custo_Total >= 0),
    CONSTRAINT ck_pedidos_origem CHECK (
        (Origem_Registro='LEGADO_V2' AND ID_Vendedor IS NULL AND ID_Status=5) OR
        (Origem_Registro='OPERACAO_V3' AND ID_Vendedor IS NOT NULL AND ID_Status BETWEEN 1 AND 4)
    ),
    CONSTRAINT fk_pedidos_v3_clientes FOREIGN KEY (ID_Cliente) REFERENCES clientes(ID_Cliente),
    CONSTRAINT fk_pedidos_v3_lojas FOREIGN KEY (ID_Loja) REFERENCES lojas(ID_Loja),
    CONSTRAINT fk_pedidos_v3_status FOREIGN KEY (ID_Status) REFERENCES status_pedido(ID_Status),
    CONSTRAINT fk_pedidos_v3_vendedor_loja FOREIGN KEY (ID_Vendedor, ID_Loja)
        REFERENCES vendedores(ID_Vendedor, ID_Loja)
) ENGINE=InnoDB;

CREATE TABLE itens_pedido (
    ID_Item INT NOT NULL AUTO_INCREMENT,
    ID_Pedido INT NOT NULL,
    ID_Produto INT NOT NULL,
    Quantidade INT NOT NULL,
    Preco_Unit DECIMAL(10,2) NOT NULL,
    Custo_Unit DECIMAL(10,2) NULL,
    Desconto_Valor DECIMAL(12,2) NOT NULL DEFAULT 0,
    Ajuste_Valor DECIMAL(12,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (ID_Item),
    CONSTRAINT uk_itens_pedido_produto UNIQUE (ID_Pedido, ID_Produto),
    KEY idx_itens_pedido_produto (ID_Produto),
    CONSTRAINT ck_itens_qtd CHECK (Quantidade > 0),
    CONSTRAINT ck_itens_preco CHECK (Preco_Unit >= 0),
    CONSTRAINT ck_itens_custo CHECK (Custo_Unit IS NULL OR Custo_Unit >= 0),
    CONSTRAINT ck_itens_desconto CHECK (Desconto_Valor >= 0),
    CONSTRAINT ck_itens_subtotal CHECK (
        Quantidade * Preco_Unit - Desconto_Valor + Ajuste_Valor >= 0
    ),
    CONSTRAINT fk_itens_pedido_cabecalho FOREIGN KEY (ID_Pedido) REFERENCES pedidos(ID_Pedido),
    CONSTRAINT fk_itens_pedido_produto FOREIGN KEY (ID_Produto) REFERENCES produtos(ID_Produto)
) ENGINE=InnoDB;

CREATE TABLE pagamentos (
    ID_Pagamento INT NOT NULL AUTO_INCREMENT,
    ID_Pedido INT NOT NULL,
    ID_Forma TINYINT NOT NULL,
    ID_Status TINYINT NOT NULL,
    Valor_Pagamento DECIMAL(12,2) NOT NULL,
    Data_Pagamento DATETIME NULL,
    Observacao VARCHAR(255) NULL,
    PRIMARY KEY (ID_Pagamento),
    KEY idx_pagamentos_pedido (ID_Pedido),
    CONSTRAINT ck_pagamentos_valor CHECK (Valor_Pagamento > 0),
    CONSTRAINT ck_pagamentos_aprovado_data CHECK (ID_Status <> 2 OR Data_Pagamento IS NOT NULL),
    CONSTRAINT fk_pagamentos_pedidos FOREIGN KEY (ID_Pedido) REFERENCES pedidos(ID_Pedido),
    CONSTRAINT fk_pagamentos_formas FOREIGN KEY (ID_Forma) REFERENCES formas_pagamento(ID_Forma),
    CONSTRAINT fk_pagamentos_status FOREIGN KEY (ID_Status) REFERENCES status_pagamento(ID_Status)
) ENGINE=InnoDB;

INSERT INTO `banco_v4`.`categorias` SELECT * FROM `banco_v3`.`categorias`;
INSERT INTO `banco_v4`.`locais` SELECT * FROM `banco_v3`.`locais`;
INSERT INTO `banco_v4`.`clientes` SELECT * FROM `banco_v3`.`clientes`;
INSERT INTO `banco_v4`.`lojas` SELECT * FROM `banco_v3`.`lojas`;
INSERT INTO `banco_v4`.`produtos` SELECT * FROM `banco_v3`.`produtos`;
INSERT INTO `banco_v4`.`vendedores` SELECT * FROM `banco_v3`.`vendedores`;
INSERT INTO `banco_v4`.`status_pedido` SELECT * FROM `banco_v3`.`status_pedido`;
INSERT INTO `banco_v4`.`formas_pagamento` SELECT * FROM `banco_v3`.`formas_pagamento`;
INSERT INTO `banco_v4`.`status_pagamento` SELECT * FROM `banco_v3`.`status_pagamento`;
INSERT INTO `banco_v4`.`pedidos` SELECT * FROM `banco_v3`.`pedidos`;
INSERT INTO `banco_v4`.`itens_pedido` SELECT * FROM `banco_v3`.`itens_pedido`;
INSERT INTO `banco_v4`.`pagamentos` SELECT * FROM `banco_v3`.`pagamentos`;

-- Evolução v3 -> v4: suprimentos, compras, estoque e rastreabilidade.
-- Executar apenas sobre banco_v4 novo e integralmente copiado da v3.
USE banco_v4;

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
INSERT INTO produto_fornecedor (ID_Produto,ID_Fornecedor,Preco_Compra,Fornecedor_Principal,Prazo_Dias)
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

-- Não fabricar uma cronologia operacional para registros LEGADO_V2.
INSERT INTO historico_status_pedido (ID_Pedido,ID_Status,Data_Status,Observacao)
SELECT ID_Pedido,ID_Status,Data_Pedido,'Estado inicial documentado do pedido sintético'
FROM pedidos
WHERE Origem_Registro='OPERACAO_V3';

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

-- O saldo inicial é registrado como ajuste rastreável (independente do legado v2).
INSERT INTO movimentacoes_estoque (ID_Loja,ID_Produto,Tipo_Movimentacao,Quantidade,Data_Movimentacao,Observacao)
SELECT ID_Loja,ID_Produto,'AJUSTE',Quantidade,'2020-01-01 08:00:00','Saldo inicial da v4'
FROM estoque WHERE Quantidade>0;

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

-- Compras recebidas geram movimento e atualizam estoque.
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
    WHERE c.ID_Status_Compra=2 GROUP BY c.ID_Loja,ic.ID_Produto
) x ON x.ID_Loja=e.ID_Loja AND x.ID_Produto=e.ID_Produto
SET e.Quantidade=e.Quantidade+x.Qtd_Entrada;

-- Somente as vendas sintéticas v3 são usadas na simulação de saídas de estoque.
-- Registros LEGADO_V2 antecedem o controle de estoque e não são reconstituídos como movimentação real.
INSERT INTO movimentacoes_estoque (
    ID_Loja,ID_Produto,Tipo_Movimentacao,Quantidade,Data_Movimentacao,ID_Pedido,Observacao
)
SELECT p.ID_Loja,ip.ID_Produto,'SAIDA',ip.Quantidade,p.Data_Pedido,p.ID_Pedido,'Saída por venda sintética'
FROM pedidos p JOIN itens_pedido ip ON ip.ID_Pedido=p.ID_Pedido
WHERE p.Origem_Registro='OPERACAO_V3';

-- Só registrar saídas efetivas quando houver saldo; não usar GREATEST para mascarar rupturas.
UPDATE estoque e
JOIN (
    SELECT p.ID_Loja,ip.ID_Produto,SUM(ip.Quantidade) AS Qtd_Saida
    FROM pedidos p JOIN itens_pedido ip ON ip.ID_Pedido=p.ID_Pedido
    WHERE p.Origem_Registro='OPERACAO_V3'
    GROUP BY p.ID_Loja,ip.ID_Produto
) x ON x.ID_Loja=e.ID_Loja AND x.ID_Produto=e.ID_Produto
SET e.Quantidade=e.Quantidade-x.Qtd_Saida;

-- A conciliação das compras foi preservada conforme fonte; diferenças do Valor_Total
-- em relação aos itens_compra devem ser auditadas, não reescritas silenciosamente.
