# Banco de Dados & SQL — 5 versões canônicas expandidas

Sequência: `banco_v1 → banco_v2 → banco_v3 → banco_v4 → banco_v5`.

- **v1:** base inicial e consultas fundamentais.
- **v2:** integridade estrutural.
- **v3:** normalização da venda + operação comercial. Surge `itens_pedido`.
- **v4:** suprimentos, compras, estoque e rastreabilidade. Surgem `itens_compra` e outras entidades operacionais.
- **v5:** mesmo domínio da v4 em grande volume para índices e EXPLAIN.

## Relações N:N materializadas

- `pedidos ↔ produtos` → `itens_pedido`
- `produtos ↔ fornecedores` → `produto_fornecedor`
- `compras ↔ produtos` → `itens_compra`
- `lojas ↔ produtos` → `estoque` (saldo por combinação)

As demais relações permanecem 1:N quando essa cardinalidade representa melhor o domínio.
