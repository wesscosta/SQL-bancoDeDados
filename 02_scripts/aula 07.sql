CREATE TABLE vendedores(
		id int primary key,
        nome varchar(100) not null,
        email varchar(100) Unique,
        data_nascimento Date
);


ALTER TABLE vendedores modify COLUMN ID_Vendedor INT auto_increment;

ALTER TABLE lojas
MODIFY COLUMN ID_Loja INT NOT NULL;

ALTER TABLE lojas
ADD PRIMARY KEY (ID_loja);

ALTER TABLE vendedores 
ADD CONSTRAINT fk_vendedores_loja 
FOREIGN KEY (ID_Loja) REFERENCES lojas(Id_Loja);


ALTER TABLE categorias
MODIFY COLUMN ID_Categoria INT NOT NULL;

ALTER TABLE categorias
ADD PRIMARY KEY (ID_Categoria);

select * from clientes;

ALTER TABLE produtos
MODIFY COLUMN ID_Produto INT NOT NULL;

ALTER TABLE produtos
ADD PRIMARY KEY (ID_Produto);

ALTER TABLE pedidos
MODIFY COLUMN ID_Pedido INT NOT NULL;

ALTER TABLE pedidos
ADD PRIMARY KEY (ID_Pedido);

select * from pedidos;

ALTER TABLE produtos 
ADD CONSTRAINT fk_produtos_categorias 
FOREIGN KEY (ID_Categoria) REFERENCES c(ID_Categoria);

ALTER TABLE pedidos 
ADD CONSTRAINT fk_pedidos_clientes
FOREIGN KEY (ID_Cliente) REFERENCES clientes(ID_Cliente);



ALTER TABLE vendedores rename column id to ID_Vendedor;
select * from vendedores;

INSERT INTO vendedores(nome, email, data_nascimento, ID_Loja)
values ('Marta da Silva', 'Marta@email.com', '1996-10-11', 4);

delete FROM vendedores WHERE ID_VENDEDOR = 3;
