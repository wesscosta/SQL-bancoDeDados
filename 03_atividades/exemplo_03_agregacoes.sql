select count(*) from pedidos;

select * from produtos;




select count(*)
from pedidos
left join produtos on pedidos.ID_Produto = produtos.ID_Produto;


select count(*)
from pedidos
right join produtos on pedidos.ID_Produto = produtos.ID_Produto;


select * from pedidos where ID_Loja <> 2;