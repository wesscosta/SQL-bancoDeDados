# Validação da geração — versões expandidas

Validação estática realizada após a reconstrução.

## Estrutura final

- `banco_v1`: 6 tabelas — base inicial.
- `banco_v2`: 7 tabelas — integridade + vendedores.
- `banco_v3`: 12 tabelas finais — inclui `itens_pedido`, status e pagamentos.
- `banco_v4`: 20 tabelas finais — inclui `produto_fornecedor`, `compras`, `itens_compra`, `estoque`, movimentos e histórico.
- `banco_v5`: mesmas 20 tabelas da v4, com carga ampliada.

## Checagens executadas

- FKs locais e colunas referenciadas verificadas nas versões v3–v5: **sem referências ausentes**.
- `itens_pedido` não contém `ID_Fornecedor`.
- `itens_compra` contém `ID_Fornecedor` e usa FKs compostas para validar compra/fornecedor e produto/fornecedor.
- Itens de compra sintéticos verificados contra `produto_fornecedor`: **0 incompatibilidades**.
- 16 pedidos multi-itens de demonstração na v3, com 40 itens no total.
- Totais dos pedidos multi-itens comparados com quantidade × preço − desconto: **0 divergências**.
- Migrações não contêm sequências literais `\\n` inválidas.

## Limite da validação

Não havia uma instância MySQL disponível na sessão para executar os scripts ponta a ponta. Por isso, cada versão inclui `99_validacao.sql` para conferência após a importação em MySQL 8.0+/8.4.
