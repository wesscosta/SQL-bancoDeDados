# Cinco versões canônicas do banco comercial

| Versão | Contrato | Tabelas |
| --- | --- | ---: |
| v1 | Base introdutória | 6 |
| v2 | Integridade estrutural, vendedores | 7 |
| v3 | Pedidos e itens, status e pagamentos | 12 |
| v4 | Fornecedores, compras, estoque, movimentações e histórico | 20 |
| v5 | Contrato da v4 com dados sintéticos para performance | 20 |

Cada instalação cria um schema independente. **Não use os scripts em instâncias com schemas de trabalho sem backup.** A homologação automatizada usa contêiner MySQL 8.4 totalmente isolado, não usa credenciais reais e não exclui bancos do usuário.

## Instalação direta

- v1: `banco_v1/banco_completo.sql`
- v2: `banco_v2/banco_completo.sql`
- v3: `banco_v3/banco_v3_final.sql`
- v4: `banco_v4/banco_v4_final.sql`
- v5: `banco_v5/banco_v5_final.sql`

## Migrações

Após importar v1 e v2:

1. `banco_v3/migracao_banco_v2_para_v3.sql`
2. `banco_v4/migracao_v3_para_v4.sql`
3. `banco_v5/migracao_v4_para_v5.sql`

O script v2→v3 cria a tabela de pedidos e suas relações, copia histórico sem forjar pagamentos ou vendedores, usa `Ajuste_Valor` e faz **SIGNAL + ROLLBACK** se os invariantes históricos divergem antes do COMMIT. A estrutura DDL é criada antes da transação; em caso de falha, o schema parcial de teste permanece e deve ser analisado, sem exclusão automática.

## Homologação MySQL 8.4

```bash
bash 01_Banco_SQL_5_Versoes_Canonicas_Expandida/verificar.sh
```

Requisitos: Docker e `sha256sum`. Cada modo (instalação direta e migração) executa em um contêiner distinto. As validações falham em contagens erradas, chaves estrangeiras duplicadas, referências órfãs, pagamentos legados, divergências entre pedidos e itens, compras sem itens, totais de compras, movimentações e estoque. Também comparam os hashes dos dados de **todas as 52 tabelas de v3 a v5** entre os dois caminhos.

O teste negativo de rollback está em `tools/test_migration_guard.sh`; veja `VALIDACAO_GERACAO.md` para resultados e evidências.
