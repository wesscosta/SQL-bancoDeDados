USE banco_v5;


-- ============================================================
-- Evolução canônica: banco_v4 -> banco_v5
-- Mesmo domínio, escala para performance
-- ============================================================

-- Geração set-based de uma sequência 1..100000.
DROP TEMPORARY TABLE IF EXISTS tmp_digits;
CREATE TEMPORARY TABLE tmp_digits (n TINYINT PRIMARY KEY);
INSERT INTO tmp_digits VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

DROP TEMPORARY TABLE IF EXISTS tmp_seq;
CREATE TEMPORARY TABLE tmp_seq AS
SELECT 1 + a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n AS n
FROM tmp_digits a
CROSS JOIN tmp_digits b
CROSS JOIN tmp_digits c
CROSS JOIN tmp_digits d
CROSS JOIN tmp_digits e
WHERE 1 + a.n + 10*b.n + 100*c.n + 1000*d.n + 10000*e.n <= 100000;
ALTER TABLE tmp_seq ADD PRIMARY KEY (n);

-- Clientes até 10 mil.
INSERT IGNORE INTO clientes (
    ID_Cliente,Nome,Sobrenome,Data_Nascimento,Estado_Civil,Sexo,Email,Telefone,Renda_Anual,Qtd_Filhos,Escolaridade
)
SELECT
    n,
    CONCAT('ClientePerf',LPAD(n,5,'0')),
    CONCAT('Sobrenome',LPAD(MOD(n,251),3,'0')),
    DATE_ADD('1975-01-01',INTERVAL MOD(n*29,12000) DAY),
    IF(MOD(n,3)=0,'C','S'),
    IF(MOD(n,2)=0,'F','M'),
    CONCAT('perf',LPAD(n,5,'0'),'@lab.local'),
    CONCAT('(86) 9',LPAD(MOD(n*7919,100000000),8,'0')),
    25000+MOD(n*193,180000),
    MOD(n,6),
    CASE MOD(n,4) WHEN 0 THEN 'Ensino Médio' WHEN 1 THEN 'Superior' WHEN 2 THEN 'Pós-graduado' ELSE 'Tecnólogo' END
FROM tmp_seq WHERE n<=10000;

-- Produtos até 500.
INSERT IGNORE INTO produtos (
    ID_Produto,Nome_Produto,ID_Categoria,Marca_Produto,Num_Serie,Preco_Unit,Custo_Unit
)
SELECT
    n,
    CONCAT('Produto Performance ',LPAD(n,4,'0')),
    1+MOD(n-1,7),
    CASE MOD(n,8) WHEN 0 THEN 'DELL' WHEN 1 THEN 'SAMSUNG' WHEN 2 THEN 'LOGITECH' WHEN 3 THEN 'JBL'
         WHEN 4 THEN 'SONY' WHEN 5 THEN 'AKG' WHEN 6 THEN 'BLUE' ELSE 'LABTECH' END,
    CONCAT('PERF-',LPAD(n,7,'0')),
    100+MOD(n*181,6900),
    ROUND((100+MOD(n*181,6900))*(0.35+MOD(n,20)/100),2)
FROM tmp_seq WHERE n<=500;

-- Relações de fornecedor para novos produtos.
INSERT IGNORE INTO produto_fornecedor (ID_Produto,ID_Fornecedor,Preco_Compra,Fornecedor_Principal,Prazo_Dias)
SELECT p.ID_Produto,1+MOD(p.ID_Produto-1,15),ROUND(p.Custo_Unit*0.95,2),TRUE,5+MOD(p.ID_Produto,8)
FROM produtos p;
INSERT IGNORE INTO produto_fornecedor (ID_Produto,ID_Fornecedor,Preco_Compra,Fornecedor_Principal,Prazo_Dias)
SELECT p.ID_Produto,1+MOD(p.ID_Produto+4,15),ROUND(p.Custo_Unit*1.03,2),FALSE,7+MOD(p.ID_Produto,10)
FROM produtos p;

-- Saldos para toda loja x produto.
INSERT IGNORE INTO estoque (ID_Loja,ID_Produto,Quantidade,Estoque_Minimo)
SELECT l.ID_Loja,p.ID_Produto,20+MOD(l.ID_Loja*p.ID_Produto,81),10+MOD(p.ID_Produto,11)
FROM lojas l CROSS JOIN produtos p;

-- Novos cabeçalhos de pedido até 100 mil. Totais serão recalculados após os itens.
INSERT IGNORE INTO pedidos (
    ID_Pedido,Data_Pedido,ID_Loja,ID_Cliente,ID_Vendedor,ID_Status,Valor_Total,Custo_Total,Observacao
)
SELECT
    s.n,
    DATE_ADD('2022-01-01 08:00:00', INTERVAL MOD(s.n*17,1460*24*60) MINUTE),
    1+MOD(s.n*3,8),
    1+MOD(s.n*31,10000),
    v.ID_Vendedor,
    CASE WHEN MOD(s.n,25)=0 THEN 3 WHEN MOD(s.n,7)=0 THEN 2 ELSE 4 END,
    0,0,'Carga de performance v5'
FROM tmp_seq s
JOIN (
    SELECT ID_Loja,MIN(ID_Vendedor) AS ID_Vendedor
    FROM vendedores GROUP BY ID_Loja
) v ON v.ID_Loja=1+MOD(s.n*3,8)
WHERE s.n>390;

-- 1 a 4 itens por pedido; o par pedido/produto é determinístico e sem repetição dentro do pedido.
INSERT IGNORE INTO itens_pedido (
    ID_Pedido,ID_Produto,Quantidade,Preco_Unit,Custo_Unit,Desconto_Valor
)
SELECT
    p.ID_Pedido,
    pr.ID_Produto,
    1+MOD(p.ID_Pedido+pos.pos,5),
    pr.Preco_Unit,
    pr.Custo_Unit,
    CASE WHEN MOD(p.ID_Pedido+pos.pos,20)=0 THEN ROUND(pr.Preco_Unit*0.05,2) ELSE 0 END
FROM pedidos p
JOIN (
    SELECT 1 pos UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
) pos ON pos.pos <= 1+MOD(p.ID_Pedido,4)
JOIN produtos pr
  ON pr.ID_Produto = 1+MOD(p.ID_Pedido*17+pos.pos*29,500)
WHERE p.Observacao='Carga de performance v5';

-- Recalcula snapshots financeiros do cabeçalho.
UPDATE pedidos p
JOIN (
    SELECT ID_Pedido,
           SUM(Quantidade*Preco_Unit-Desconto_Valor) AS Valor_Total,
           SUM(Quantidade*COALESCE(Custo_Unit,0)) AS Custo_Total
    FROM itens_pedido GROUP BY ID_Pedido
) x ON x.ID_Pedido=p.ID_Pedido
SET p.Valor_Total=x.Valor_Total,p.Custo_Total=x.Custo_Total
WHERE p.Observacao='Carga de performance v5';

-- Pagamento para pedidos ainda sem pagamento.
INSERT INTO pagamentos (ID_Pedido,ID_Forma_Pagamento,ID_Status_Pagamento,Valor,Data_Pagamento)
SELECT p.ID_Pedido,1+MOD(p.ID_Pedido-1,5),CASE WHEN p.ID_Status=3 THEN 3 ELSE 2 END,p.Valor_Total,
       CASE WHEN p.ID_Status=3 THEN NULL ELSE DATE_ADD(p.Data_Pedido,INTERVAL 5 MINUTE) END
FROM pedidos p
WHERE NOT EXISTS (SELECT 1 FROM pagamentos pg WHERE pg.ID_Pedido=p.ID_Pedido);

INSERT INTO historico_status_pedido (ID_Pedido,ID_Status,Data_Status,Observacao)
SELECT p.ID_Pedido,p.ID_Status,p.Data_Pedido,'Estado inicial da carga v5'
FROM pedidos p
WHERE NOT EXISTS (SELECT 1 FROM historico_status_pedido h WHERE h.ID_Pedido=p.ID_Pedido);

ANALYZE TABLE clientes,produtos,pedidos,itens_pedido,pagamentos,estoque;

SELECT COUNT(*) AS Clientes FROM clientes;
SELECT COUNT(*) AS Produtos FROM produtos;
SELECT COUNT(*) AS Pedidos FROM pedidos;
SELECT COUNT(*) AS Itens_Pedido FROM itens_pedido;
SELECT COUNT(*) AS Pagamentos FROM pagamentos;
SELECT COUNT(*) AS Estoques FROM estoque;
