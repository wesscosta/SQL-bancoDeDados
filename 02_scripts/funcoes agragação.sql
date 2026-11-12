select * from pedidos;

SELECT * FROM CLIENTES WHERE SOBRENOME LIKE  'B%';
select count(distinct Sexo) from clientes;

select count(ID_Categoria) from categorias;
select count(ID_Loja) from lojas;
select count(ID_Produto) from produtos;

select sum(Preco_Unit) from produtos;

select sum(Receita_Venda) from pedidos where Data_Venda like '2019-01-__';
SELECT sum(Receita_Venda) FROM pedidos Where Data_Venda like '2019-01%';

# count(coluna) -> Contar
# count(distinct coluna) -> contar os valores distintos
# SUM(coluna) -> soma
# AVG(coluna) -> Media
# MIN(coluna) -> Minimo
# (coluna) -> Maximo

# MOSTRE A MEDIA DO CUSTO DE VENDA
select avg(Custo_Venda) from pedidos;
select avg(Qtd_Vendida) from pedidos;
select min(receita_venda) from pedidos;
select max(receita_venda) from pedidos;








