# Portal Comercial com Flask | banco_v3

Projeto de laboratório sobre uma **cópia isolada da banco_v3**. Esta implementação constitui a base executável e exemplos guiados; a autonomia é avaliada pelos exercícios em `sql/desafios.sql` e pelos checkpoints do Notion. Não publique em ambiente externo.

## Início rápido

1. Copie os dados de `banco_v3` para um schema separado **`banco_v3_lab`**. Para importar do arquivo canônico, substitua somente o nome do schema no cabeçalho do arquivo de instalação direta em uma cópia local. Não altere a fonte.
2. Execute `sql/preparar_lab.sql` **somente** no schema de laboratório, para criar a sequência concorrente de IDs dos novos pedidos.
3. Crie conta MySQL de laboratório com permissões mínimas para SELECT e DML no schema `banco_v3_lab`, sem privilégios de DDL para Flask.
4. Crie o ambiente virtual e instale as dependências; copie `.env.example` para `.env` e preencha DB_* e FLASK_SECRET_KEY (gerar com `python -c "import secrets; print(secrets.token_hex(32))"`).
5. Execute `python -m flask --app app run` e abra `http://127.0.0.1:5000`.

**Windows PowerShell**
```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
.\.venv\Scripts\python.exe -m flask --app app run
```

**Linux**
```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
cp .env.example .env
.venv/bin/python -m flask --app app run
```

Não usar root no Flask. Não colocar senha no Git, não desabilitar FKs/CSRF e não usar o esquema canônico em operações de escrita.

## Funcionalidades-base

- Consultas: produtos, categorias, clientes, locais, lojas, vendedores e pedidos.
- Pedido: detalhamento com múltiplos itens, histórico, vendedor (ou desconhecido), status e pagamentos.
- Escrita guiada: cadastrar categoria, criar pedido com dois produtos, registrar pagamento.
- Relatórios: valores registrados por loja, pedidos por status, unidades vendidas por produto.
- Proteções: SQL parametrizado, `Decimal`, CSRF, FK composta loja/vendedor, transações e rollback; tabela auxiliar de sequência no **schema de laboratório**.

A sequência `portal_ids_pedido` reserva identificadores sem `MAX(ID_Pedido)+1` e sem mudar a estrutura canônica. Buracos em sequências podem ocorrer após rollback, o que é esperado.

## Checkpoints do material

| Etapa | Competência | Evidência |
| --- | --- | --- |
| CP1 | Flask, HTTP, Jinja | Home e /sobre com 200; URL desconhecida 404 |
| CP2 | Conexão e SELECT parametrizado | /produtos com busca; SQL no Workbench |
| CP3 | JOIN e leitura de entidades | consultas por entidade e pedido multi-item |
| CP4 | INSERT e formulário | categoria cadastrada; conflito de PK tratado |
| CP5 | UPDATE e integridade | desafio de edição controlada realizado pelo aluno |
| CP6 | Transação multi-item, rollback | pedido com dois itens atômico; pagamento separado |
| CP7 | Agregação sem dupla contagem | relatórios conferidos no Workbench |
| CP8 | Testes, apresentação e autonomia | evidência e explicação de SQL e integridade |

**Carga sugerida:** núcleo CP1–CP4 e CP7 em 12–16 h; CP5, CP6 e defesa em 12–16 h adicionais. Aprofundar concorrência depois da Atividade 13. As etapas têm produto observável, mas os desafios de edição e consultas avançadas devem ser implementados pelos estudantes, não copiados de um gabarito público.

## Rotas

GET: `/`, `/sobre`, `/produtos`, `/categorias`, `/clientes`, `/locais`, `/lojas`, `/vendedores`, `/pedidos`, `/pedidos/<id>`, `/relatorios`.

GET/POST: `/categorias/novo`, `/pedidos/novo`, `/pedidos/<id>/pagamentos/novo`.

Cadastro e edição de clientes, produtos, lojas e vendedores são **extensões**, ainda não oferecidas pela implementação-base. Não tratar páginas ausentes como concluídas.

## Testes

```bash
python -m pytest -q
```

Testes automatizados de rotas e regras com dependências simuladas. Para integração com MySQL, execute a aplicação usando `banco_v3_lab` local e teste os cenários do roteiro. Nunca use a senha real em capturas ou logs.

## Observações de domínio

- LEGADO_V2 indica operação histórica; status e vendedor desconhecidos são preservados.
- Ausência de pagamento registrado não comprova falta de pagamento real.
- Os valores totais dos relatórios representam **valores registrados**, incluindo status pendentes/cancelados; não são receita recebida.
- Não existe controle de estoque na v3: não inventar movimentações.
- A conta MySQL do aplicativo não deve poder escrever em `banco_v3` nem em outros schemas.
