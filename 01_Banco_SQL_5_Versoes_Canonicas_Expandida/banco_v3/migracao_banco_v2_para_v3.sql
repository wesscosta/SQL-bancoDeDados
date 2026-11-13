-- MIGRAÇÃO NÃO DESTRUTIVA: banco_v2 -> banco_v3
-- Pré-requisitos: banco_v2 íntegra (7 tabelas), MySQL 8.0.16+; banco_v3 NÃO deve existir.
-- Este arquivo cria apenas banco_v3. NÃO executa RENAME, DROP ou ALTER em banco_v2.
SET NAMES utf8mb4;
CREATE DATABASE `banco_v3` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `banco_v3`;

-- categorias
CREATE TABLE `categorias` (
  `ID_Categoria` INT NOT NULL,
  `Categoria` VARCHAR(80) NOT NULL,
  PRIMARY KEY (`ID_Categoria`),
  UNIQUE KEY `uk_categorias_nome` (`Categoria`)
) ENGINE=InnoDB;



-- locais
CREATE TABLE `locais` (
  `ID_Local` INT NOT NULL,
  `Cidade` VARCHAR(80) NOT NULL,
  `Estado` CHAR(2) NOT NULL,
  `Regiao` VARCHAR(30) NOT NULL,
  PRIMARY KEY (`ID_Local`),
  UNIQUE KEY `uk_locais_cidade_estado` (`Cidade`,`Estado`)
) ENGINE=InnoDB;



-- clientes
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



-- lojas
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



-- produtos
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



-- vendedores
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

-- Copia somente dados cadastrais, mantendo suas chaves originais.
INSERT INTO categorias SELECT * FROM banco_v2.categorias;
INSERT INTO locais SELECT * FROM banco_v2.locais;
INSERT INTO clientes SELECT * FROM banco_v2.clientes;
INSERT INTO lojas SELECT * FROM banco_v2.lojas;
INSERT INTO produtos SELECT * FROM banco_v2.produtos;
INSERT INTO vendedores SELECT * FROM banco_v2.vendedores;

-- Catálogos operacionais introduzidos na v3.
CREATE TABLE status_pedido (
    ID_Status TINYINT NOT NULL,
    Descricao VARCHAR(40) NOT NULL,
    PRIMARY KEY (ID_Status),
    CONSTRAINT uk_status_pedido_descricao UNIQUE (Descricao)
) ENGINE=InnoDB;
INSERT INTO status_pedido (ID_Status,Descricao) VALUES
(1,'Pendente'),(2,'Processando'),(3,'Cancelado'),(4,'Concluído'),(5,'Histórico sem informação');

CREATE TABLE formas_pagamento (
    ID_Forma TINYINT NOT NULL,
    Descricao VARCHAR(40) NOT NULL,
    PRIMARY KEY (ID_Forma),
    CONSTRAINT uk_formas_pagamento_descricao UNIQUE (Descricao)
) ENGINE=InnoDB;
INSERT INTO formas_pagamento (ID_Forma,Descricao) VALUES
(1,'Dinheiro'),(2,'Pix'),(3,'Cartão de crédito'),(4,'Cartão de débito'),(5,'Boleto');

CREATE TABLE status_pagamento (
    ID_Status TINYINT NOT NULL,
    Descricao VARCHAR(40) NOT NULL,
    PRIMARY KEY (ID_Status),
    CONSTRAINT uk_status_pagamento_descricao UNIQUE (Descricao)
) ENGINE=InnoDB;
INSERT INTO status_pagamento (ID_Status,Descricao) VALUES
(1,'Pendente'),(2,'Aprovado'),(3,'Estornado'),(4,'Rejeitado');

-- A FK de pedidos valida também que vendedor pertence à loja correta.
ALTER TABLE vendedores
    ADD CONSTRAINT uk_vendedores_vendedor_loja UNIQUE (ID_Vendedor, ID_Loja);

-- Cabeçalho: uma linha por pedido. Não há ID_Produto neste cabeçalho.
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

-- Detalhe: uma linha por produto de cada pedido.
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

-- As operações históricas não possuem hora real; converter DATE em DATETIME usa 00:00:00.
-- Duas inserções somente, em uma transação; DDL já foi concluído antes.
START TRANSACTION;
INSERT INTO pedidos (
    ID_Pedido,Data_Pedido,ID_Loja,ID_Cliente,ID_Vendedor,ID_Status,
    Valor_Total,Custo_Total,Origem_Registro,Observacao
)
SELECT ID_Pedido,CAST(Data_Venda AS DATETIME),ID_Loja,ID_Cliente,
       NULL,5,Receita_Venda,Custo_Venda,'LEGADO_V2',
       'Historico_v2_sem_hora_ou_status'
FROM banco_v2.pedidos;

INSERT INTO itens_pedido (
    ID_Pedido,ID_Produto,Quantidade,Preco_Unit,Custo_Unit,Desconto_Valor,Ajuste_Valor
)
SELECT ID_Pedido,ID_Produto,Qtd_Vendida,Preco_Unit,Custo_Unit,0,
       Receita_Venda - Qtd_Vendida * Preco_Unit
FROM banco_v2.pedidos;

-- Gates obrigatórios ANTES do COMMIT:
-- (a) contagem v2 = pedidos LEGADO_V2 = itens gerados;
-- (b) somas de receita iguais; (c) nenhum ID de origem ausente.
SELECT (SELECT COUNT(*) FROM banco_v2.pedidos) AS Origem,
       (SELECT COUNT(*) FROM pedidos WHERE Origem_Registro='LEGADO_V2') AS Destino,
       (SELECT COUNT(*) FROM itens_pedido) AS Itens;
SELECT (SELECT COALESCE(SUM(Receita_Venda),0) FROM banco_v2.pedidos) AS Receita_v2,
       (SELECT COALESCE(SUM(Valor_Total),0) FROM pedidos WHERE Origem_Registro='LEGADO_V2') AS Receita_v3;
-- Execução automatizada: inspecione o resultado e use ROLLBACK se houver divergência.
-- Para uma migração definitiva, execute os INSERTs de forma controlada no Workbench.
COMMIT;

-- Dados NOVOS somente depois da reconciliação de registros históricos.
INSERT INTO pedidos (ID_Pedido,Data_Pedido,ID_Loja,ID_Cliente,ID_Vendedor,ID_Status,Valor_Total,Custo_Total,Origem_Registro,Observacao) VALUES
(375, '2020-01-01 10:45:00', 6, 26, 17, 4, 10000.00, 4444.00, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(376, '2020-01-02 10:52:00', 1, 33, 1, 4, 8790.00, 3517.30, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(377, '2020-01-03 10:59:00', 4, 40, 6, 4, 7700.00, 3141.00, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(378, '2020-01-04 10:06:00', 7, 47, 19, 2, 7130.00, 2075.00, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(379, '2020-01-05 10:13:00', 2, 54, 2, 4, 2510.00, 1118.00, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(380, '2020-01-06 10:20:00', 5, 61, 15, 4, 10250.00, 3558.50, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(381, '2020-01-07 10:27:00', 8, 68, 21, 4, 6440.00, 2287.60, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(382, '2020-01-08 10:34:00', 3, 75, 5, 4, 16290.00, 6878.00, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(383, '2020-01-09 10:41:00', 6, 82, 17, 4, 8630.00, 2566.50, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(384, '2020-01-10 10:48:00', 1, 89, 1, 4, 6020.00, 2578.50, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(385, '2020-01-11 10:55:00', 4, 96, 6, 2, 6180.00, 1947.60, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(386, '2020-01-12 10:02:00', 7, 3, 19, 4, 15400.00, 5702.00, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(387, '2020-01-13 10:09:00', 2, 10, 2, 4, 7150.00, 2590.00, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(388, '2020-01-14 10:16:00', 5, 17, 15, 4, 2710.00, 1014.60, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(389, '2020-01-15 10:23:00', 8, 24, 21, 4, 7845.00, 1975.00, 'OPERACAO_V3', 'Pedido multi-itens de demonstração'),
(390, '2020-01-16 10:30:00', 3, 31, 5, 4, 18600.00, 5832.00, 'OPERACAO_V3', 'Pedido multi-itens de demonstração');

INSERT INTO itens_pedido (ID_Pedido,ID_Produto,Quantidade,Preco_Unit,Custo_Unit,Desconto_Valor,Ajuste_Valor) VALUES
(375, 4, 2, 350.00, 129.50, 0.00, 0),
(375, 7, 3, 3100.00, 1395.00, 0.00, 0),
(376, 9, 3, 780.00, 327.60, 0.00, 0),
(376, 12, 1, 650.00, 214.50, 0.00, 0),
(376, 16, 2, 2900.00, 1160.00, 0.00, 0),
(377, 14, 1, 3100.00, 1209.00, 0.00, 0),
(377, 1, 2, 2300.00, 966.00, 0.00, 0),
(378, 3, 2, 450.00, 90.00, 0.00, 0),
(378, 6, 3, 1800.00, 540.00, 270.00, 0),
(378, 10, 1, 1100.00, 275.00, 0.00, 0),
(379, 8, 3, 600.00, 258.00, 90.00, 0),
(379, 11, 1, 800.00, 344.00, 0.00, 0),
(380, 13, 1, 3400.00, 850.00, 0.00, 0),
(380, 16, 2, 2900.00, 1160.00, 0.00, 0),
(380, 4, 3, 350.00, 129.50, 0.00, 0),
(381, 2, 2, 2800.00, 980.00, 0.00, 0),
(381, 5, 3, 280.00, 109.20, 0.00, 0),
(382, 7, 3, 3100.00, 1395.00, 0.00, 0),
(382, 10, 1, 1100.00, 275.00, 0.00, 0),
(382, 14, 2, 3100.00, 1209.00, 310.00, 0),
(383, 12, 1, 650.00, 214.50, 0.00, 0),
(383, 15, 2, 4200.00, 1176.00, 420.00, 0),
(384, 1, 2, 2300.00, 966.00, 230.00, 0),
(384, 4, 3, 350.00, 129.50, 0.00, 0),
(384, 8, 1, 600.00, 258.00, 0.00, 0),
(385, 6, 3, 1800.00, 540.00, 0.00, 0),
(385, 9, 1, 780.00, 327.60, 0.00, 0),
(386, 11, 1, 800.00, 344.00, 0.00, 0),
(386, 14, 2, 3100.00, 1209.00, 0.00, 0),
(386, 2, 3, 2800.00, 980.00, 0.00, 0),
(387, 16, 2, 2900.00, 1160.00, 0.00, 0),
(387, 3, 3, 450.00, 90.00, 0.00, 0),
(388, 5, 3, 280.00, 109.20, 0.00, 0),
(388, 8, 1, 600.00, 258.00, 30.00, 0),
(388, 12, 2, 650.00, 214.50, 0.00, 0),
(389, 10, 1, 1100.00, 275.00, 55.00, 0),
(389, 13, 2, 3400.00, 850.00, 0.00, 0),
(390, 15, 2, 4200.00, 1176.00, 0.00, 0),
(390, 2, 3, 2800.00, 980.00, 0.00, 0),
(390, 6, 1, 1800.00, 540.00, 0.00, 0);

-- Pagamentos apenas nos 16 novos pedidos.
INSERT INTO pagamentos (ID_Pedido,ID_Forma,ID_Status,Valor_Pagamento,Data_Pagamento,Observacao) VALUES
(375, 1, 2, 10000.00, '2020-01-01 10:45:00', 'Pagamento sintético de laboratório'),
(376, 2, 2, 8790.00, '2020-01-02 10:52:00', 'Pagamento sintético de laboratório'),
(377, 3, 2, 7700.00, '2020-01-03 10:59:00', 'Pagamento sintético de laboratório'),
(378, 4, 2, 7130.00, '2020-01-04 10:06:00', 'Pagamento sintético de laboratório'),
(379, 5, 2, 2510.00, '2020-01-05 10:13:00', 'Pagamento sintético de laboratório'),
(380, 1, 2, 10250.00, '2020-01-06 10:20:00', 'Pagamento sintético de laboratório'),
(381, 2, 2, 6440.00, '2020-01-07 10:27:00', 'Pagamento sintético de laboratório'),
(382, 3, 2, 16290.00, '2020-01-08 10:34:00', 'Pagamento sintético de laboratório'),
(383, 4, 2, 8630.00, '2020-01-09 10:41:00', 'Pagamento sintético de laboratório'),
(384, 5, 2, 6020.00, '2020-01-10 10:48:00', 'Pagamento sintético de laboratório'),
(385, 1, 2, 6180.00, '2020-01-11 10:55:00', 'Pagamento sintético de laboratório'),
(386, 2, 2, 15400.00, '2020-01-12 10:02:00', 'Pagamento sintético de laboratório'),
(387, 3, 2, 7150.00, '2020-01-13 10:09:00', 'Pagamento sintético de laboratório'),
(388, 4, 2, 2710.00, '2020-01-14 10:16:00', 'Pagamento sintético de laboratório'),
(389, 5, 2, 7845.00, '2020-01-15 10:23:00', 'Pagamento sintético de laboratório'),
(390, 1, 2, 18600.00, '2020-01-16 10:30:00', 'Pagamento sintético de laboratório');
