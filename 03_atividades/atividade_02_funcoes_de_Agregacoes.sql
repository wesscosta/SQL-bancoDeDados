# Bloco A — Funções de agregação

-- **Questão 01 — Quantidade de clientes:** quantos registros existem na tabela `clientes`?

select
	count(*) as "qtd de clientes"
from clientes;

-- **Questão 02 — Perfil de renda:** qual é a renda anual **média, menor e maior** entre os clientes?
select
	avg(renda_anual) as renda_media,
    min(renda_anual) as renda_menor,
    max(renda_anual) as renda_maior
    from clientes;
/* **Questão 03 — Estrutura familiar:** qual é a **média** e qual é a 
**maior quantidade de filhos** registrada entre os clientes?
*/
select
avg(Qtd_filhos),
max(Qtd_filhos)
from clientes;

/* **Questão 04 — Catálogo de produtos:** quantos produtos existem
cadastrados e qual é o **preço unitário médio** do catálogo? */

select
count(id_produto),
avg(preco_unit)
from produtos;

-- **Questão 05 — Volume de vendas:** quantos pedidos foram registrados e qual é a **quantidade total de itens vendidos**?
select 
	count(ID_Pedido) as 'Qntd Pedidos',
	count(Qtd_Vendida) as 'Qntd Vendida'
	from pedidos;
    
    
-- **Questão 06 — Resultado comercial geral:** qual é a **receita total**, o **custo total**,
# a **receita média por pedido**, a **menor receita** e a **maior receita** registrada em `pedidos`?

select
	sum(Custo_Venda),
	sum(Receita_Venda),
	avg(Receita_Venda),
    min(Receita_Venda),
    max(Receita_Venda)
from pedidos;
    

## Bloco B — GROUP BY: análise por grupos

-- **Questão 07 — Estado civil:** quantos clientes existem em cada `Estado_Civil`?
SELECT 
	Estado_civil,
    count(*) AS "Clientes Casados e Solteiros"
FROM clientes
GROUP BY Estado_Civil;

/* **Questão 08 — Escolaridade e renda:** qual é a
 `Renda_Anual` média para cada nível de `Escolaridade`?*/

SELECT
	Escolaridade,
    AVG(Renda_Anual)
FROM clientes
GROUP BY Escolaridade;

-- **Questão 09 — Família por estado civil:** para cada `Estado_Civil`, apresente a quantidade de clientes e a média de `Qtd_Filhos`.
select
	estado_civil , 
    count(ID_cliente) , 
    avg(qtd_filhos)
from clientes
group by estado_civil;

    

-- **Questão 10 — Distribuição do catálogo:** quantos produtos existem em cada `ID_Categoria`?

SELECT
	ID_categoria,
	COUNT(Nome_Produto)
FROM produtos
group by ID_Categoria;

-- **Questão 11 — Preço por categoria:** para cada `ID_Categoria`, apresente o preço 
# **médio, menor e maior** dos produtos.

SELECT	
	ID_Categoria,
    avg(Preco_Unit) AS "Preço Médio",
    MIN(Preco_Unit) AS "Menor Preço",
    MAX(Preco_Unit) AS "Maior Preço"
from produtos
GROUP BY ID_Categoria;
    


-- **Questão 12 — Movimento das lojas:** quantos pedidos foram registrados por `ID_Loja`?
select 
	ID_Loja,
    count(*) as "pedido"
from pedidos
group by ID_Loja;

-- **Questão 13 — Faturamento das lojas:** qual é a soma de `Receita_Venda` por `ID_Loja`? Ordene do maior para o menor faturamento.
select	ID_Loja,
	sum(Receita_Venda)
from pedidos
group by id_loja
order by sum(Receita_Venda) desc;

-- **Questão 14 — Receita e custo por loja:** para cada `ID_Loja`, apresente a receita total e o custo total das vendas.
select ID_Loja,
sum(Receita_venda),
sum(custo_venda)
from pedidos
group by ID_Loja;



-- **Questão 15 — Ticket médio por loja:** qual é a média de `Receita_Venda` por pedido em cada `ID_Loja`?
-- **Questão 16 — Clientes atendidos:** quantos clientes distintos cada `ID_Loja` atendeu? Utilize `COUNT(DISTINCT ID_Cliente)`.

## Bloco C — HAVING: filtrando grupos

-- **Questão 17 — Lojas com maior faturamento:** mostre somente os `ID_Loja` cuja soma de `Receita_Venda` seja **superior a R$ 30.000**.
-- **Questão 18 — Lojas com maior alcance:** mostre somente os `ID_Loja` que atenderam **mais de 40 clientes distintos**.
-- **Questão 19 — Lojas com ticket médio elevado:** mostre somente os `ID_Loja` cuja média de `Receita_Venda` por pedido seja **superior a R$ 620**.
-- **Questão 20 — Categorias com maior variedade:** mostre somente os `ID_Categoria` que possuem **pelo menos 3 produtos cadastrados**.