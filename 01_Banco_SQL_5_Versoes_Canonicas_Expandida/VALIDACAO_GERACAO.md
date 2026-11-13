# Evidências de validação e homologação

## Referência inicial

Auditoria da `main` em 13/11/2026: commit `fccd8cf742f5e814d355b29ce3f9e04c9804c6b0`, mensagem *update v4 and v5*.

A revisão anterior declarava **somente validação estática**; não era prova de execução MySQL.

## Contratos esperados

- v1: 6 tabelas.
- v2: 7 tabelas, 374 pedidos.
- v3: 12 tabelas; 374 pedidos históricos, 16 pedidos de demonstração, 414 itens e 16 pagamentos, nenhum histórico com pagamento.
- v4: 20 tabelas, 390 pedidos, 16 compras e 128 saldos de estoque.
- v5: 20 tabelas, 10.000 clientes, 500 produtos, 100.000 pedidos, 249.439 itens, 99.626 pagamentos e 4.000 saldos de estoque.

## Defeitos observados no MySQL 8.4.13 antes da correção

1. Na instalação direta v5, erro `1137 (HY000)` na geração da tabela de sequência `tmp_digits` com múltiplos aliases.
2. Na migração v3→v4, erro `6125 (HY000)`: FK composta para vendedores sem índice único correspondente.
3. O verificador anterior usava caminhos inexistentes e executava `DROP DATABASE` mesmo sem garantias de isolamento.

## Correções executadas

- Geração de sequências v5 com CTE de dígitos, compatível com MySQL 8.4, tanto na carga direta quanto na migração.
- Criação explícita do índice composto `(ID_Vendedor,ID_Loja)` nos scripts de migração v4 e v5.
- Reconciliação automática, `SIGNAL` e `ROLLBACK` na cópia histórica v2→v3.
- Verificador refeito com dois contêineres descartáveis, sem usar MySQL externo nem excluir bancos existentes.
- Correção dos cabeçalhos diretos v4 e v5.
- Atualização dos arquivos ZIP por reprodução determinística.

## Reproduzir

```bash
bash 01_Banco_SQL_5_Versoes_Canonicas_Expandida/verificar.sh
bash tools/test_migration_guard.sh
python3 tools/build_archives.py --check
```

O workflow `.github/workflows/mysql84-homologacao.yml` contém os mesmos gates. Verifique o status do GitHub Actions após abrir o PR; os testes locais **não** são evidência de que a execução remota já concluiu.

## Testes negativos

`tools/test_migration_guard.sh` gera uma variante defeituosa temporária da migração e confirma erro `SQLSTATE 45000`, com zero registros confirmados em pedidos/itens após rollback. O script canônico não é adulterado.

## Limites

Os testes cobrem os invariantes descritos, mas não substituem um teste de carga, uma auditoria financeira externa nem uma revisão de segurança de uma aplicação publicada. O Portal Flask é exclusivo para ambiente local de laboratório.
