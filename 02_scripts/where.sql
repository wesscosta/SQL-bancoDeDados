# 1.  Mostre apenas os produtos com preço iguais ou maiores que R$1.800
SELECT * FROM produtos WHERE Preco_Unit >= '1800';
    
# 2. Mostre apenas os produtos com preços iguais a R$3.100
SELECT * FROM produtos WHERE Preco_Unit = 3100;

# 3. Mostre apenas os produtos da marca ***DELL***
SELECT * FROM produtos WHERE marca_produto = "DELL";
    
# 4. Mostre apenas os pedidos feitos no dia 03/01/2019
SELECT * FROM pedidos WHERE Data_Venda = '2019-01-03';

#5. Mostre apenas os clientes SOLTEIROS do sexo MASCULINO
SELECT * FROM clientes WHERE sexo = "M" AND Estado_Civil = "S";

# 6. Mostre apenas os produtos das marcas DELL e SAMSUNG
SELECT * FROM produtos WHERE Marca_Produto = 'DELL' OR Marca_Produto = 'SAMSUNG';
  