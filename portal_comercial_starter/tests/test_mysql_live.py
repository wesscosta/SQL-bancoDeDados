"""Integração real MySQL 8.4; roda somente com PORTAL_INTEGRATION=1."""
import os
from decimal import Decimal
import mysql.connector
import pytest

pytestmark = pytest.mark.skipif(os.getenv("PORTAL_INTEGRATION") != "1",
                                reason="Requer banco_v3_lab isolado")

from app import app
from conexao import conectar, consultar


def test_fluxos_mysql84_pedido_e_pagamento():
    app.config.update(TESTING=True, WTF_CSRF_ENABLED=False)
    cli = app.test_client()
    for rota in ["/", "/sobre", "/produtos", "/categorias", "/clientes",
                 "/locais", "/lojas", "/vendedores", "/pedidos", "/relatorios",
                 "/pedidos/1", "/pedidos/375", "/pedidos/novo"]:
        resposta = cli.get(rota)
        assert resposta.status_code == 200, (rota, resposta.status_code)

    cliente = consultar("SELECT ID_Cliente FROM clientes LIMIT 1")[0]["ID_Cliente"]
    vendedor = consultar("SELECT ID_Vendedor,ID_Loja FROM vendedores LIMIT 1")[0]
    produtos = consultar("SELECT ID_Produto,Preco_Unit FROM produtos ORDER BY ID_Produto LIMIT 2")
    ids = [p["ID_Produto"] for p in produtos]
    total_esperado = sum((Decimal(p["Preco_Unit"]) for p in produtos), Decimal("0.00"))

    antes = consultar("SELECT COUNT(*) AS n FROM pedidos")[0]["n"]
    resp = cli.post("/pedidos/novo", data={
        "cliente": str(cliente), "loja": str(vendedor["ID_Loja"]),
        "vendedor": str(vendedor["ID_Vendedor"]),
        "produto": [str(x) for x in ids], "quantidade": ["1", "1"],
    })
    assert resp.status_code == 302
    novo_id = int(resp.location.split("/")[-1])
    pedido = consultar("SELECT * FROM pedidos WHERE ID_Pedido=%s", (novo_id,))[0]
    itens = consultar("SELECT * FROM itens_pedido WHERE ID_Pedido=%s", (novo_id,))
    assert len(itens) == 2
    assert pedido["Origem_Registro"] == "OPERACAO_V3"
    assert pedido["Valor_Total"] == total_esperado
    assert consultar("SELECT COUNT(*) AS n FROM pedidos")[0]["n"] == antes + 1
    assert cli.get(f"/pedidos/{novo_id}").status_code == 200

    falha = cli.post("/pedidos/novo", data={
        "cliente": str(cliente), "loja": str(vendedor["ID_Loja"]),
        "vendedor": "999999", "produto": [str(x) for x in ids],
        "quantidade": ["1", "1"],
    })
    assert falha.status_code == 200
    assert consultar("SELECT COUNT(*) AS n FROM pedidos")[0]["n"] == antes + 1

    assert cli.post("/pedidos/1/pagamentos/novo", data={
        "forma": "1", "status": "2", "valor": "10.00"
    }).status_code == 403

    pagar = cli.post(f"/pedidos/{novo_id}/pagamentos/novo", data={
        "forma": "1", "status": "2", "valor": str(total_esperado)
    })
    assert pagar.status_code == 302
    registro = consultar(
        "SELECT Valor_Pagamento,ID_Status,Data_Pagamento FROM pagamentos WHERE ID_Pedido=%s",
        (novo_id,),
    )[0]
    assert registro["Valor_Pagamento"] == total_esperado
    assert registro["ID_Status"] == 2 and registro["Data_Pagamento"] is not None
    assert consultar(
        """SELECT COUNT(*) AS n FROM pagamentos pg JOIN pedidos p USING(ID_Pedido)
           WHERE p.Origem_Registro='LEGADO_V2'"""
    )[0]["n"] == 0

    # CHECK Quantidade > 0 é realmente imposto pelo MySQL, não só pelo formulário.
    terceiro = consultar(
        "SELECT ID_Produto FROM produtos WHERE ID_Produto NOT IN (%s,%s) LIMIT 1",
        tuple(ids),
    )[0]["ID_Produto"]
    con = conectar()
    cur = con.cursor()
    try:
        with pytest.raises(mysql.connector.Error):
            cur.execute(
                """INSERT INTO itens_pedido
                   (ID_Pedido,ID_Produto,Quantidade,Preco_Unit,Desconto_Valor,Ajuste_Valor)
                   VALUES (%s,%s,0,10.00,0,0)""",
                (novo_id, terceiro),
            )
        con.rollback()
    finally:
        cur.close()
        con.close()
    assert len(consultar("SELECT ID_Item FROM itens_pedido WHERE ID_Pedido=%s", (novo_id,))) == 2
