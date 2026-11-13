# Auditoria técnica e pedagógica | 13/11/2026

**Repositório:** `wesscosta/SQL-bancoDeDados`

**Baseline:** `fccd8cf742f5e814d355b29ce3f9e04c9804c6b0`

**Branch:** `fix/auditoria-sql-flask-v3-20261113`
**Ambiente de teste:** MySQL 8.4.13 em Docker isolado, sem volumes nem portas externas.

## Diagnóstico reproduzido

| Severidade | Área | Falha anterior | Correção |
| --- | --- | --- | --- |
| Alta | Instalação direta v5 | MySQL ERROR 1137 na linha 1488 (`tmp_digits` reaberta) | CTE para sequência de 100 mil IDs |
| Alta | Migração v4 | MySQL ERROR 6125, FK composta sem índice UNIQUE em vendedores | Índice composto nos scripts de v4 e v5 |
| Alta | Migração v3 | `COMMIT` incondicional após SELECTs observacionais | Procedure de gate e rollback transacional |
| Alta | Verificação | Caminhos inexistentes, exclusões de bancos no mesmo servidor | Contêiner descartável por caminho; sem DROP DATABASE |
| Média | Arquivos | ZIP consolidado não coincidia com a árvore atual | Gerador de ZIP determinístico e validação no CI |
| Baixa | Documentação | Cabeçalhos de v4/v5 herdados de v3 | Ajuste dos cabeçalhos e guias |
| Média | Portal Flask | Notion usava v2 e o starter não estava versionado | Starter executável com modelo v3, testes e roteiros |

## Resultados medidos

- As cinco instalações diretas são executáveis; v3, v4 e v5 passam invariantes.
- As migrações v2→v3, v3→v4 e v4→v5 passam e mantêm v1/v2 intactas.
- Histórico v2: 374 pedidos sem vendedor atribuído nem pagamento sintético.
- v5: 100.000 pedidos, 249.439 itens, 99.626 pagamentos e 4.000 saldos de estoque.
- Divergências de total entre pedidos e itens, total entre compras e itens, estoque e movimentação: zero nas verificações MySQL.
- Teste negativo de migração: falha intencional detectada por `SIGNAL`, seguida de `ROLLBACK`.
- Flask: 14 testes de rotas/contratos aprovados (1 teste de integração ignorado sem banco) e 1 teste de integração MySQL 8.4 aprovado em contêiner real, com pedido multi-item e pagamento. A publicação do workflow CI ficou bloqueada por permissões do GitHub.

## Projeto Flask

- Contrato: `banco_v3` em cópia independente `banco_v3_lab`.
- Rotas implementadas: listagens de 7 entidades, detalhe de pedido, relatórios, cadastro de categoria, criação atômica de pedido de 2 produtos, registro de pagamento somente para operação v3.
- Controle de IDs: tabela auxiliar exclusiva da cópia de laboratório com AUTO_INCREMENT, sem `MAX(ID)+1` concorrente.
- Segurança: parametrização, `Decimal`, CSRF, permissões locais, rollback e ausência de credenciais no Git.
- Escopo não implementado: CRUD completo das doze entidades, autenticação ou hospedagem pública. Esses recursos não são pré-requisitos para a finalidade didática.

## Orientação pedagógica

Posicionar o Portal Comercial como **projeto complementar com início após a Atividade 11**. Após a Atividade 09, os alunos podem conhecer Flask e o modelo v3; o núcleo principal usa conhecimentos de JOIN/consultas avançadas; após a Atividade 13, aprofundam-se as transações e a concorrência.

Preservar Atividades 08 a 14 e os oito checkpoints do Portal, com evidências verificáveis, exemplos graduais e desafios em `portal_comercial_starter/sql/desafios.sql`. Gabaritos permanecem fora do repositório público.

## Verificação final

```bash
bash 01_Banco_SQL_5_Versoes_Canonicas_Expandida/verificar.sh
bash tools/test_migration_guard.sh
python3 tools/build_archives.py --check
cd portal_comercial_starter
python -m pytest -q
```

Para integração real do Flask no MySQL 8.4 descartável, a partir da raiz:

```bash
PORTAL_PYTHON=python bash tools/run_flask_mysql84_live.sh
```

## Limitações

O repositório auditado não inclui um script canônico de migração **v1→v2**. Ambos os modos de homologação instalam v1 e v2 diretamente; a cadeia de migração executável e validada é **v2→v3→v4→v5**. Não declarar v1→v2 como migração homologada. Um script novo deve ser derivado e validado separadamente do material da Atividade 08, sem modificar as bases canônicas.

Os logs locais dos testes foram incluídos em `evidencias/2026-11-13/`; o workflow do GitHub Actions permanece **não publicado** por falta de permissão da integração para gravar em `.github/workflows/`. O starter é um ambiente de aprendizagem, não um ERP homologado para produção; não substitui controles de acesso, autorização e auditoria transacional de um sistema público.
