"""Testes isolados dos contratos HTTP/SQL; não exigem banco real."""
import os
from decimal import Decimal

import pytest

os.environ.setdefault("FLASK_SECRET_KEY", "chave-apenas-testes-123456789")
import app as modulo


@pytest.fixture
def client():
    modulo.app.config.update(TESTING=True, WTF_CSRF_ENABLED=False)
    with modulo.app.test_client() as cliente:
        yield cliente


def test_paginas_iniciais_e_404(client):
    assert client.get("/").status_code == 200
    assert client.get("/sobre").status_code == 200
    assert client.get("/rota-inexistente").status_code == 404


def test_produto_sql_parametrizado(client, monkeypatch):
    chamadas = []
    monkeypatch.setattr(modulo, "consultar",
                        lambda sql, params=(): chamadas.append((sql, params)) or
                        [{"ID_Produto": 1, "Nome_Produto": "Monitor",
                          "Categoria": "Monitor", "Preco_Unit": Decimal("100.00")}])
    resposta = client.get("/produtos?busca=%27%20OR%201%3D1")
    assert resposta.status_code == 200
    assert b"Monitor" in resposta.data
    assert "LIKE %s" in chamadas[0][0]
    assert chamadas[0][1] == ("%' OR 1=1%",)
    assert "' OR 1=1" not in chamadas[0][0]


@pytest.mark.parametrize("rota", ["/categorias", "/clientes", "/locais",
                                   "/lojas", "/vendedores", "/pedidos", "/relatorios"])
def test_listagens_sem_dados(client, monkeypatch, rota):
    monkeypatch.setattr(modulo, "consultar", lambda sql, params=(): [])
    assert client.get(rota).status_code == 200


def test_pedido_inexistente(client, monkeypatch):
    monkeypatch.setattr(modulo, "consultar", lambda sql, params=(): [])
    assert client.get("/pedidos/9999999").status_code == 404


def test_legado_nao_pode_receber_pagamento(client, monkeypatch):
    monkeypatch.setattr(modulo, "consultar",
                        lambda sql, params=(): [{"ID_Pedido": 9, "Origem_Registro": "LEGADO_V2"}])
    assert client.get("/pedidos/9/pagamentos/novo").status_code == 403
    assert client.post("/pedidos/9/pagamentos/novo", data={
        "forma": "1", "status": "2", "valor": "20.00"
    }).status_code == 403


def test_pedido_repetido_gera_rollback(client, monkeypatch):
    class Con:
        rollback_chamado = False
        fechado = False
        def rollback(self): self.rollback_chamado = True
        def close(self): self.fechado = True
    con = Con()
    monkeypatch.setattr(modulo, "consultar", lambda sql, params=(): [])
    monkeypatch.setattr(modulo, "conectar", lambda: con)
    r = client.post("/pedidos/novo", data={
        "cliente": "1", "loja": "1", "vendedor": "1",
        "produto": ["1", "1"], "quantidade": ["1", "2"],
    })
    assert r.status_code == 200
    assert con.rollback_chamado and con.fechado
    assert b"pelo menos dois produtos distintos" in r.data


def test_pedido_multi_item_atomico(client, monkeypatch):
    class Cursor:
        lastrowid = 391
        fechou = False
        comandos = []
        sql_atual = ""
        def execute(self, sql, params=()):
            self.sql_atual = sql
            self.comandos.append((sql, params))
        def fetchone(self):
            if "FROM clientes" in self.sql_atual:
                return {"ID_Cliente": 1}
            if "FROM vendedores" in self.sql_atual:
                return {"ID_Vendedor": 1}
            return None
        def fetchall(self):
            return [{"ID_Produto": 1, "Preco_Unit": Decimal("12.50"),
                     "Custo_Unit": Decimal("5.00")},
                    {"ID_Produto": 2, "Preco_Unit": Decimal("20.00"),
                     "Custo_Unit": Decimal("8.00")}]
        def close(self): self.fechou = True
    class Conn:
        iniciada = False
        confirmada = False
        fechou = False
        rollback_chamado = False
        def __init__(self): self.cur = Cursor()
        def start_transaction(self): self.iniciada = True
        def cursor(self, dictionary=False): return self.cur
        def commit(self): self.confirmada = True
        def rollback(self): self.rollback_chamado = True
        def close(self): self.fechou = True
    con = Conn()
    monkeypatch.setattr(modulo, "conectar", lambda: con)
    monkeypatch.setattr(modulo, "consultar", lambda sql, params=(): [])
    resp = client.post("/pedidos/novo", data={
        "cliente": "1", "loja": "1", "vendedor": "1",
        "produto": ["1", "2"], "quantidade": ["2", "3"],
    })
    assert resp.status_code == 302 and resp.location.endswith("/pedidos/391")
    assert con.iniciada and con.confirmada and con.fechou and con.cur.fechou
    assert not con.rollback_chamado
    sqls = [s for s, p in con.cur.comandos]
    assert sum("INSERT INTO itens_pedido" in s for s in sqls) == 2
    assert any("INSERT INTO portal_ids_pedido" in s for s in sqls)
    assert all("MAX(ID_Pedido)" not in s for s in sqls)
    insert = [(s, p) for s, p in con.cur.comandos if "INSERT INTO pedidos" in s]
    assert len(insert) == 1
    assert insert[0][1][5] == Decimal("85.00")


def test_csrf_sem_token_rejeitado(client):
    modulo.app.config["WTF_CSRF_ENABLED"] = True
    try:
        assert client.post("/categorias/novo", data={
            "id_categoria": "99", "nome": "Teste"
        }).status_code == 400
    finally:
        modulo.app.config["WTF_CSRF_ENABLED"] = False
