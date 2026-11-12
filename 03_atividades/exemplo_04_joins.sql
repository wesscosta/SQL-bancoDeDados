SELECT *
FROM produtos pr
left JOIN pedidos p  on p.ID_Produto = pr.ID_Produto
where p.ID_Pedido is not null;

select * from pedidos;

