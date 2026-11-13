-- Evolução com SCHEMAS INDEPENDENTES: banco_v4 -> banco_v5.
-- Execute em servidor que tenha banco_v4; falha se banco_v5 já existir.
-- Não apaga ou altera banco_v4. NÃO use junto ao arquivo completo.
SET NAMES utf8mb4;
CREATE DATABASE `banco_v5` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `banco_v5`;

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

CREATE TABLE status_compra (
    ID_Status_Compra TINYINT NOT NULL,
    Status_Compra VARCHAR(30) NOT NULL,
    PRIMARY KEY (ID_Status_Compra),
    UNIQUE KEY uk_status_compra_nome (Status_Compra)
) ENGINE=InnoDB;

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

INSERT INTO `banco_v5`.`categorias` SELECT * FROM `banco_v4`.`categorias`;
INSERT INTO `banco_v5`.`locais` SELECT * FROM `banco_v4`.`locais`;
INSERT INTO `banco_v5`.`clientes` SELECT * FROM `banco_v4`.`clientes`;
INSERT INTO `banco_v5`.`lojas` SELECT * FROM `banco_v4`.`lojas`;
INSERT INTO `banco_v5`.`produtos` SELECT * FROM `banco_v4`.`produtos`;
INSERT INTO `banco_v5`.`vendedores` SELECT * FROM `banco_v4`.`vendedores`;
INSERT INTO `banco_v5`.`status_pedido` SELECT * FROM `banco_v4`.`status_pedido`;
INSERT INTO `banco_v5`.`formas_pagamento` SELECT * FROM `banco_v4`.`formas_pagamento`;
INSERT INTO `banco_v5`.`status_pagamento` SELECT * FROM `banco_v4`.`status_pagamento`;
INSERT INTO `banco_v5`.`pedidos` SELECT * FROM `banco_v4`.`pedidos`;
INSERT INTO `banco_v5`.`itens_pedido` SELECT * FROM `banco_v4`.`itens_pedido`;
INSERT INTO `banco_v5`.`pagamentos` SELECT * FROM `banco_v4`.`pagamentos`;
INSERT INTO `banco_v5`.`fornecedores` SELECT * FROM `banco_v4`.`fornecedores`;
INSERT INTO `banco_v5`.`produto_fornecedor` SELECT * FROM `banco_v4`.`produto_fornecedor`;
INSERT INTO `banco_v5`.`status_compra` SELECT * FROM `banco_v4`.`status_compra`;
INSERT INTO `banco_v5`.`compras` SELECT * FROM `banco_v4`.`compras`;
INSERT INTO `banco_v5`.`itens_compra` SELECT * FROM `banco_v4`.`itens_compra`;
INSERT INTO `banco_v5`.`estoque` SELECT * FROM `banco_v4`.`estoque`;
INSERT INTO `banco_v5`.`historico_status_pedido` SELECT * FROM `banco_v4`.`historico_status_pedido`;
INSERT INTO `banco_v5`.`movimentacoes_estoque` SELECT * FROM `banco_v4`.`movimentacoes_estoque`;

-- Evolução v4 -> v5: aumento de volume para EXPLAIN e índices.
-- Executar somente em novo banco_v5 já criado a partir de banco_v4.
-- Os pedidos gerados para performance são dados sintéticos, não lançamentos de estoque.
USE banco_v5;

CREATE TEMPORARY TABLE tmp_digits (n TINYINT PRIMARY KEY);
INSERT INTO tmp_digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);
CREATE TEMPORARY TABLE tmp_seq AS
SELECT 1 + a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n AS n
FROM tmp_digits a CROSS JOIN tmp_digits b CROSS JOIN tmp_digits c
CROSS JOIN tmp_digits d CROSS JOIN tmp_digits e
WHERE 1 + a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n <= 100000;
ALTER TABLE tmp_seq ADD PRIMARY KEY (n);

-- Completa cadastros até 10.000 clientes; IDs originais não são alterados.
INSERT INTO clientes (
    ID_Cliente,Nome,Sobrenome,Data_Nascimento,Estado_Civil,Sexo,Email,Telefone,Renda_Anual,Qtd_Filhos,Escolaridade
)
SELECT s.n,
       CONCAT('ClientePerf',LPAD(s.n,5,'0')),
       CONCAT('Sobrenome',LPAD(MOD(s.n,251),3,'0')),
       DATE_ADD('1975-01-01',INTERVAL MOD(s.n*29,12000) DAY),
       IF(MOD(s.n,3)=0,'C','S'), IF(MOD(s.n,2)=0,'F','M'),
       CONCAT('perf',LPAD(s.n,5,'0'),'@lab.local'),
       CONCAT('(86) 9',LPAD(MOD(s.n*7919,100000000),8,'0')),
       25000+MOD(s.n*193,180000), MOD(s.n,6),
       CASE MOD(s.n,4) WHEN 0 THEN 'Ensino Médio' WHEN 1 THEN 'Superior'
             WHEN 2 THEN 'Pós-graduado' ELSE 'Tecnólogo' END
FROM tmp_seq s
WHERE s.n<=10000 AND NOT EXISTS (
    SELECT 1 FROM clientes c WHERE c.ID_Cliente=s.n
);

-- Completa catálogo até 500 produtos, mantendo os IDs originais.
INSERT INTO produtos (
    ID_Produto,Nome_Produto,ID_Categoria,Marca_Produto,Num_Serie,Preco_Unit,Custo_Unit
)
SELECT s.n,
       CONCAT('Produto Performance ',LPAD(s.n,4,'0')),
       1+MOD(s.n-1,7),
       CASE MOD(s.n,8) WHEN 0 THEN 'DELL' WHEN 1 THEN 'SAMSUNG'
            WHEN 2 THEN 'LOGITECH' WHEN 3 THEN 'JBL' WHEN 4 THEN 'SONY'
            WHEN 5 THEN 'AKG' WHEN 6 THEN 'BLUE' ELSE 'LABTECH' END,
       CONCAT('PERF-',LPAD(s.n,7,'0')),
       100+MOD(s.n*181,6900),
       ROUND((100+MOD(s.n*181,6900))*(0.35+MOD(s.n,20)/100),2)
FROM tmp_seq s
WHERE s.n<=500 AND NOT EXISTS (
    SELECT 1 FROM produtos pr WHERE pr.ID_Produto=s.n
);

-- Cadastra dois fornecedores determinísticos por produto novo.
INSERT INTO produto_fornecedor (ID_Produto,ID_Fornecedor,Preco_Compra,Fornecedor_Principal,Prazo_Dias)
SELECT p.ID_Produto,1+MOD(p.ID_Produto-1,15),ROUND(p.Custo_Unit*0.95,2),TRUE,5+MOD(p.ID_Produto,8)
FROM produtos p
WHERE NOT EXISTS (
    SELECT 1 FROM produto_fornecedor pf
    WHERE pf.ID_Produto=p.ID_Produto AND pf.ID_Fornecedor=1+MOD(p.ID_Produto-1,15)
);
INSERT INTO produto_fornecedor (ID_Produto,ID_Fornecedor,Preco_Compra,Fornecedor_Principal,Prazo_Dias)
SELECT p.ID_Produto,1+MOD(p.ID_Produto+4,15),ROUND(p.Custo_Unit*1.03,2),FALSE,7+MOD(p.ID_Produto,10)
FROM produtos p
WHERE NOT EXISTS (
    SELECT 1 FROM produto_fornecedor pf
    WHERE pf.ID_Produto=p.ID_Produto AND pf.ID_Fornecedor=1+MOD(p.ID_Produto+4,15)
);

-- Novos saldos terão movimentação de AJUSTE rastreável.
INSERT INTO estoque (ID_Loja,ID_Produto,Quantidade,Estoque_Minimo)
SELECT l.ID_Loja,p.ID_Produto,
       20+MOD(l.ID_Loja*p.ID_Produto,81),10+MOD(p.ID_Produto,11)
FROM lojas l CROSS JOIN produtos p
WHERE NOT EXISTS (
    SELECT 1 FROM estoque e WHERE e.ID_Loja=l.ID_Loja AND e.ID_Produto=p.ID_Produto
);
INSERT INTO movimentacoes_estoque (ID_Loja,ID_Produto,Tipo_Movimentacao,Quantidade,Data_Movimentacao,Observacao)
SELECT e.ID_Loja,e.ID_Produto,'AJUSTE',e.Quantidade,'2022-01-01 07:00:00','Saldo inicial dos novos produtos de performance'
FROM estoque e
WHERE e.ID_Produto>16 AND NOT EXISTS (
    SELECT 1 FROM movimentacoes_estoque m
    WHERE m.ID_Loja=e.ID_Loja AND m.ID_Produto=e.ID_Produto
);

-- Pedidos sintéticos: nenhum registro LEGADO_V2 recebe vendedor ou pagamento fictício.
INSERT INTO pedidos (
    ID_Pedido,Data_Pedido,ID_Loja,ID_Cliente,ID_Vendedor,ID_Status,
    Valor_Total,Custo_Total,Origem_Registro,Observacao
)
SELECT s.n,
       DATE_ADD('2022-01-01 08:00:00', INTERVAL MOD(s.n*17,1460*24*60) MINUTE),
       1+MOD(s.n*3,8),
       1+MOD(s.n*31,10000),
       v.ID_Vendedor,
       CASE WHEN MOD(s.n,25)=0 THEN 3 WHEN MOD(s.n,7)=0 THEN 2 ELSE 4 END,
       0,0,'OPERACAO_V3','Carga de performance v5'
FROM tmp_seq s
JOIN (
    SELECT ID_Loja,MIN(ID_Vendedor) AS ID_Vendedor
    FROM vendedores GROUP BY ID_Loja
) v ON v.ID_Loja=1+MOD(s.n*3,8)
WHERE s.n>390 AND NOT EXISTS (
    SELECT 1 FROM pedidos p WHERE p.ID_Pedido=s.n
);

-- De 1 a 4 produtos diferentes por pedido.
INSERT INTO itens_pedido (
    ID_Pedido,ID_Produto,Quantidade,Preco_Unit,Custo_Unit,Desconto_Valor,Ajuste_Valor
)
SELECT p.ID_Pedido,pr.ID_Produto,
       1+MOD(p.ID_Pedido+pos.pos,5),
       pr.Preco_Unit,pr.Custo_Unit,
       CASE WHEN MOD(p.ID_Pedido+pos.pos,20)=0
            THEN ROUND(pr.Preco_Unit*0.05,2) ELSE 0 END,
       0
FROM pedidos p
JOIN (SELECT 1 AS pos UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) pos
     ON pos.pos <= 1+MOD(p.ID_Pedido,4)
JOIN produtos pr ON pr.ID_Produto=1+MOD(p.ID_Pedido*17+pos.pos*29,500)
WHERE p.Origem_Registro='OPERACAO_V3' AND p.Observacao='Carga de performance v5'
  AND NOT EXISTS (
    SELECT 1 FROM itens_pedido ip
    WHERE ip.ID_Pedido=p.ID_Pedido AND ip.ID_Produto=pr.ID_Produto
);

UPDATE pedidos p
JOIN (
    SELECT ID_Pedido,
           SUM(Quantidade*Preco_Unit-Desconto_Valor+Ajuste_Valor) AS Total,
           SUM(Quantidade*Custo_Unit) AS Custo
    FROM itens_pedido GROUP BY ID_Pedido
) x ON x.ID_Pedido=p.ID_Pedido
SET p.Valor_Total=x.Total,p.Custo_Total=x.Custo
WHERE p.Origem_Registro='OPERACAO_V3' AND p.Observacao='Carga de performance v5';

-- Pagamentos apenas de pedidos SINTÉTICOS criados pela carga v5.
INSERT INTO pagamentos (ID_Pedido,ID_Forma,ID_Status,Valor_Pagamento,Data_Pagamento,Observacao)
SELECT p.ID_Pedido,1+MOD(p.ID_Pedido-1,5),
       CASE WHEN p.ID_Status=3 THEN 3 ELSE 2 END,
       p.Valor_Total,
       CASE WHEN p.ID_Status=3 THEN NULL ELSE DATE_ADD(p.Data_Pedido,INTERVAL 5 MINUTE) END,
       'Pagamento sintético de performance v5'
FROM pedidos p
WHERE p.Origem_Registro='OPERACAO_V3'
  AND p.Observacao='Carga de performance v5'
  AND NOT EXISTS (SELECT 1 FROM pagamentos pg WHERE pg.ID_Pedido=p.ID_Pedido);

INSERT INTO historico_status_pedido (ID_Pedido,ID_Status,Data_Status,Observacao)
SELECT p.ID_Pedido,p.ID_Status,p.Data_Pedido,'Estado inicial da carga sintética v5'
FROM pedidos p
WHERE p.Origem_Registro='OPERACAO_V3'
  AND p.Observacao='Carga de performance v5'
  AND NOT EXISTS (
    SELECT 1 FROM historico_status_pedido h WHERE h.ID_Pedido=p.ID_Pedido
);

DROP TEMPORARY TABLE tmp_seq;
DROP TEMPORARY TABLE tmp_digits;
ANALYZE TABLE clientes,produtos,pedidos,itens_pedido,pagamentos,estoque;
