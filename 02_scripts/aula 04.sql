/*
Mutiplas 


Linhas */
-- Unica Linha

SELECT * FROM CLIENTES; 

SELECT nome as "Primeiro nome"
FROM CLIENTES;

SELECT nome, sobrenome, Qtd_Filhos AS "Quantidade de Filhos", Renda_Anual
FROM clientes
WHERE  Qtd_Filhos >= 3 OR Renda_Anual >60000 
order by Qtd_Filhos DESC;

SELECT * FROM PRODUTOS WHERE Num_Serie LIKE "MIC%" and Num_Serie LIKE "%11";
SELECT * FROM PRODUTOS WHERE Num_Serie LIKE "MIC%14%";

SELECT nome, sobrenome, Qtd_Filhos AS "Quantidade de Filhos"
FROM clientes
WHERE  nome between "a" and "d"
-- qtd_filhos IN (2,5)
order by nome;

