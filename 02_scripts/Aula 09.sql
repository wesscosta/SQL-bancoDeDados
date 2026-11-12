select * from pedidos;

SELECT nome FROM clientes
WHERE id_cliente IN (
  SELECT id_cliente FROM pedidos WHERE Data_Venda >= '2019-10-01'
);



SELECT nome  from clientes c
where exists(
	select 1 from pedidos p
    where p.ID_Cliente = c.ID_Cliente AND p.Receita_Venda > 400
);


-- 1. Clientes com receita acima da média de todos os clientes

select * from pedidos;

select c.ID_Cliente, c.nome, sum(p.Receita_Venda)  as Total from clientes c left join
pedidos p  on p.ID_Cliente = c.ID_Cliente 
group by c.ID_Cliente , c.nome
having SUM(Receita_venda) > (
	select AVG(Receita_Total)  from (
		select  id_cliente, sum(Receita_Venda) as Receita_Total
		from pedidos
		group by ID_Cliente
	) as sub
);

-- Outra  forma
select pedidos.id_Cliente, clientes.nome, SUM(pedidos.Receita_venda) as Receita
from pedidos
left join clientes on clientes.id_cliente = pedidos.ID_Cliente
group by pedidos.id_cliente
having SUM(Receita_venda) > (
	select AVG(Receita_Total)  from (
		select  id_cliente, sum(Receita_Venda) as Receita_Total
		from pedidos
		group by ID_Cliente
	) as sub
);

-- 4. Produtos que nunca foram vendidos (subconsulta NOT IN )

select * from produtos;
select distinct ID_produto from pedidos;

select ID_Produto, Nome_Produto from produtos
where ID_Produto not IN(
	select distinct ID_produto from pedidos
);


