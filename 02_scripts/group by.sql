# 01. Quantos clientes há em cada estado_civil
SELECT ESTADO_CIVIL,count(*) AS QUANTIDADE
from clientes
group by Estado_Civil
order by Estado_Civil;
# 2. **Qual a média  da renda anual por estado civil**
SELECT * FROM clientes;
SELECT  Estado_Civil, AVG(Renda_Anual) AS "Renda Anual" FROM clientes GROUP BY Estado_Civil;
# 3. **Quantas vezes cada produto foi vendido**
select * from pedidos;
select id_produto, count(qtd_vendida) as 'quantidade vendida' from pedidos group by id_produto;
# 4. **Qual é o valor total vendido em cada loja**
select id_loja, count(qtd_vendida) as 'qnt vendas', sum(receita_venda) as 'receita arrecadada'from pedidos group by ID_Loja order by ID_Loja;
 
# 5. **Qual é o valor médio dos pedidos de cada loja**
select id_loja, avg(receita_venda) from pedidos group by id_loja order by id_loja;

# 6. **Qual o preco medio dos produtos em cada categoria**
SELECT categorias.Categoria, avg(Preco_Unit) 
FROM produtos
GROUP BY ID_Categoria
ORDER BY ID_Categoria;

# 7. **Qual a  preço minima e maxima de produtos por pedidos**
select id_produto,min(preco_unit),max(Preco_Unit)
from pedidos
group by ID_Produto
order by id_produto
# 8. **Qual o produto mais vendido por data**
# 9. **Qual produto mais vendido em cada loja no dia 01 de cada mês**
# 10. **Qual é o valor total de vendas para cada cliente?**
# 11. **Qual é a média de quantidade de produtos vendidos por loja?**
# 12. **Quantos clientes diferentes cada loja atendeu**
# 13. **Qual é o menor e o maior valor de um pedido em cada loja?**
# 14. **Quantos pedidos foram feitos em cada local?**
# 15. **Qual é o valor total de produtos vendidos em cada local?**
# 16. **Qual é o produto mais barato e o mais caro em cada categoria?**
# 17. **Quantos produtos diferentes foram vendidos para cada cliente?**
# 18. **Qual é a quantidade total de produtos vendidos por categoria?**