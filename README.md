# Banco de Dados & SQL

Repositório de apoio às atividades de MySQL. A árvore canônica está em [01_Banco_SQL_5_Versoes_Canonicas_Expandida/](01_Banco_SQL_5_Versoes_Canonicas_Expandida/).

## Caminhos de estudo

- **v1 → v2**: introdução, integridade e modelagem relacional.
- **v2 → v3**: pedidos normalizados em `pedidos` + `itens_pedido`, status, vendedor e pagamentos.
- **v3 → v4**: compras, suprimentos, estoque e rastreabilidade.
- **v4 → v5**: volume ampliado para análise de índices e execução de consultas.
- **Portal Flask**: [portal_comercial_starter/README.md](portal_comercial_starter/README.md), aplicação de laboratório sobre uma cópia da **v3**.

## Executar a homologação de forma segura

```bash
bash 01_Banco_SQL_5_Versoes_Canonicas_Expandida/verificar.sh
bash tools/test_migration_guard.sh
python3 tools/build_archives.py --check
```

Os scripts sobem contêineres descartáveis MySQL 8.4, sem volumes compartilhados e sem conexão ao banco local do usuário. **Não execute os SQL canônicos em bancos que contenham trabalhos a preservar:** os arquivos criam schemas com nomes fixos e não substituem backups.

## Entregáveis

- [Relatório de auditoria](AUDITORIA_20261113.md).
- [Arquivo das cinco versões](Banco_SQL_5_Versoes_Expandidas.zip), reconstruído a partir dos arquivos da árvore canônica.
- [Arquivo do projeto Flask](portal_comercial_starter.zip), gerado a partir do diretório versionado.

O material pedagógico e os checkpoints completos são publicados no Notion. Gabaritos não fazem parte deste repositório público.
