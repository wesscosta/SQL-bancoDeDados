# Portal Comercial com Flask | banco_v3

**Banco único:** a aplicação conecta diretamente ao schema `banco_v3` de uma **instância MySQL local de cada aluno**. Não use a instância de outro estudante nem um banco compartilhado. A aplicação realiza inserções reais.

Leia a [atividade detalhada no Notion](https://app.notion.com/p/416f3eb198c381d3a2c7c16bc294e96c), com os 8 checkpoints, código de apoio, exercícios, testes e critérios de avaliação.

## Instalar e executar

1. No MySQL Workbench, confira que `banco_v3` está disponível e íntegra.
2. Antes de criar pedidos, execute `sql/preparar_lab.sql` no Workbench com conta administrativa, **uma vez**. O script cria `portal_ids_pedido` e é idempotente enquanto todos os novos pedidos usarem essa sequência.
3. Crie `usuario_portal` para acesso local TCP (`127.0.0.1`), autorizando `SELECT, INSERT, UPDATE` **somente** em `banco_v3`.
4. Copie `.env.example` para `.env`, preencha `DB_*` e gere `FLASK_SECRET_KEY` com `python -c "import secrets; print(secrets.token_hex(32))"`. Nunca publique o `.env`.
5. Crie um ambiente virtual, instale `requirements.txt` e rode Flask em `127.0.0.1:5000`.

**PowerShell**

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
# Edite .env antes da proxima linha
.\.venv\Scripts\python.exe -m flask --app app run --host 127.0.0.1
```

**Linux**

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
cp .env.example .env
# Edite .env antes da proxima linha
.venv/bin/python -m flask --app app run --host 127.0.0.1
```

A senha do MySQL deve ser definida individualmente pelo aluno. Não inclua segredos nas capturas de tela.

## O que já está implementado

- Consultas e filtros de produtos, categorias, clientes, locais, lojas, vendedores e pedidos.
- Pedido com itens, status, vendedor e pagamentos.
- Cadastro de categoria, pedido com dois produtos (transação + rollback) e pagamento controlado por origem.
- Relatórios por loja, status e unidades por produto.

**O que os alunos implementam:** `UPDATE` de categorias e produtos; consultas SQL adicionais; validação de pagamento acumulado com controle de concorrência; testes negativos e documentação.

## Regras

- Toda instrução SQL com dados de usuário usa parâmetros.
- Dinheiro usa `Decimal`.
- `portal_ids_pedido` evita `MAX(ID_Pedido)+1` em cada gravação.
- Não grave pagamentos em pedidos históricos (`Origem_Registro='LEGADO_V2'`, um valor armazenado na própria `banco_v3`).
- Ausência de pagamento cadastrado não prova inadimplência.
- Esta aplicação local não tem login; nunca exponha a porta Flask publicamente.

## Testes

```bash
python -m pytest -q
```

Testes de unidade de rotas não substituem o teste real usando o MySQL local. O teste de integração real com contêiner descartável é um instrumento de homologação para o professor; não execute em uma base compartilhada.
