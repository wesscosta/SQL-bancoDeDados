#- 1.  Busque todos os clientes cujo o nome começa com A
select *  from clientes where Nome  like'a%' LIMIT 3;
#- 2. Liste todos os clientes que conta do gmail
SELECT * FROM clientes WHERE Email LIKE '%gmail%';
#- 3. Liste os clientes que sejam de São Paulo Capital
select * from clientes where Telefone like '(11)%';
#- 4. Liste as Lojas que possui endereço na avenida
select * from lojas where endereco like 'av%';
#- 5. liste os produtos que no numero de serie começe com MIC e termine com 11
select * from produtos Where Num_Serie Like 'MIC%11';
#- 6.  Liste os produtos que no nome tenham I5
select * from produtos where nome_produto Like '%i5%';
#- 7. Liste todos os pedidos que ocorreram no mês de maio de 2019
SELECT * FROM pedidos where Data_Venda like '2019-05%';
#- 8. Liste todos os pedidos que ocorreram no dia 16 no ano de 2019
SELECT * FROM pedidos where Data_Venda like '2019-__-16%';   