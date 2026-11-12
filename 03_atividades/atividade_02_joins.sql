-- 1. Liste o nome dos clientes e as datas de seus pedidos.

SELECT 
	c.Nome,
    p.Data_Venda
FROM pedidos p
INNER JOIN clientes c
ON p.ID_Cliente = c.ID_Cliente;

-- 14. Mostre a quantidade de clientes distintos atendidos por loja.
select 
	count(distinct clientes.nome) as 'Clientes Unicos',
	lojas.Loja
from pedidos
join clientes on pedidos.ID_Cliente = clientes.ID_Cliente
join lojas on pedidos.ID_Loja = lojas.ID_Loja
group by lojas.loja;


-- 2.Mostre o nome dos produtos e a categoria de cada um.
SELECT
	pr.Nome_Produto,
    ca.Categoria
FROM produtos pr
join categorias ca on pr.ID_Categoria = ca.ID_Categoria;

-- 3.Exiba cada pedido com o nome da loja onde foi realizado.
select
    pedidos.ID_Pedido,
    lojas.Loja
from pedidos
inner join lojas	
	on pedidos.ID_Loja = lojas.ID_Loja;


# 8. Exiba pedido, cliente, produto, loja e data da venda.
 
SELECT 
	pedidos.ID_Pedido,
    clientes.Nome,
    produtos.Nome_Produto,
    lojas.Loja,
    pedidos.Data_Venda
FROM pedidos
INNER JOIN  clientes ON pedidos.ID_Cliente = clientes.ID_Cliente
INNER JOIN produtos ON pedidos.ID_Produto = produtos.ID_Produto
INNER JOIN lojas ON pedidos.ID_Loja = lojas.ID_Loja;


#Liste todas as categorias e seus produtos, incluindo categorias sem produto.
select
	c.categoria, p.ID_Produto
from produtos p
left join categorias c
on c.ID_Categoria = p.ID_Categoria;

#Mostre todas as lojas e seus pedidos, incluindo lojas sem pedidos.
select
	l.Loja, p.ID_Pedido
from pedidos p
left join lojas l on l.ID_Loja = p.ID_Loja;

# 9.Liste todos os produtos com sua categoria.

SELECT
	p.ID_Produto,
    p.Nome_Produto,
    c.Categoria
FROM produtos p
LEFT JOIN categorias c
ON c.ID_Categoria = p.ID_Categoria;

# 11. Liste apenas os produtos que nunca foram vendidos.

SELECT
	p.ID_Produto,
    p.Nome_Produto,
    pe.Qtd_Vendida
FROM produtos p
LEFT JOIN pedidos pe
ON p.ID_Produto = pe.ID_Produto
WHERE pe.Qtd_Vendida IS NULL;

#RIGHT JOIN — 15 questões

# 1. Liste todos os clientes e seus pedidos, preservando todos os clientes.
SELECT clientes.Nome, pedidos.ID_Pedido
FROM clientes
RIGHT JOIN pedidos
		ON pedidos.ID_Cliente = clientes.ID_Cliente;
        
        
# 2. Exiba todos os produtos e pedidos, preservando todos os produtos.
SELECT produtos.Nome_Produto, pedidos.ID_Pedido
FROM produtos
RIGHT JOIN pedidos
		ON produtos.ID_Produto = pedidos.ID_Produto;
        

# 3. Mostre todas as lojas e pedidos, preservando todas as lojas.
select LOJAS.LOJA, PEDIDOS.ID_PEDIDO
	FROM PEDIDOS
    RIGHT JOIN LOJAS ON pedidos.ID_Loja = PEDIDOS.ID_LOJA;

# 4. Liste todas as categorias e produtos, preservando todas as categorias.
SELECT CATEGORIAS.CATEGORIA, PRODUTOS.NOME_PRODUTO
	FROM PRODUTOS
    RIGHT join CATEGORIAS ON produtos.ID_CATEGORIA = CATEGORIAS.ID_CATEGORIA;



#CROSS JOIN 
#EXEMPLO: 
SELECT
    l.ID_Loja,
    l.Loja,
    c.ID_Categoria,
    c.Categoria
FROM lojas AS l
CROSS JOIN categorias AS c
ORDER BY l.ID_Loja, c.ID_Categoria;


# 1 Gere todas as combinações entre lojas e categorias.
SELECT 
	l.Loja, 
    categorias.Categoria
FROM lojas AS l
CROSS JOIN categorias;

# 4 Gere todas as combinações entre categorias e lojas e ordene por categoria e loja.

SELECT 
	categorias.categoria,
    lojas.loja
from categorias   
CROSS JOIN  lojas
 ORDER BY Categoria , loja
