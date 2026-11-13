# Evidências de homologação — 13/11/2026

Ambiente: notebook Arch Linux conectado, contêineres MySQL **8.4.13** isolados e descartáveis, sem uso de bancos de produção.

Referência de base: `fccd8cf742f5e814d355b29ce3f9e04c9804c6b0`.

- `mysql84_homologacao.log`: importações diretas e migrações, consultas que falham quando divergem, reconciliamento e 52 assinaturas de conteúdo comparadas. Na assinatura são ignorados IDs auxiliares AUTO_INCREMENT de itens, movimentos e histórico de status, para comparar dados de negócio em vez da ordem de inserção.
- `rollback_negativo.log`: migração v2→v3 propositalmente alterada em ambiente descartável, devendo sinalizar erro e fazer rollback.
- `flask_mock_tests.log`: testes Flask com banco simulado, sem integração SQL real.
- `flask_mysql84_live.log`: integração real HTTP/SQL em schema `banco_v3_lab` descartável.
- `archives_check.log`: ZIPs comparados bit a bit com as fontes versionadas.

A execução no GitHub Actions ainda não está disponível nesta branch por falta de permissão de workflow nas credenciais conectadas. Estes arquivos são **logs locais**, não evidência de uma execução CI.
