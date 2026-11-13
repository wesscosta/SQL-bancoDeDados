"""Portal Comercial | laboratório banco_v3. Não publicar na internet."""
import os
from datetime import datetime
from decimal import Decimal, InvalidOperation

import mysql.connector
from dotenv import load_dotenv
from flask import Flask, flash, redirect, render_template, request, url_for
from flask_wtf.csrf import CSRFProtect

from conexao import conectar, consultar

load_dotenv()
app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("FLASK_SECRET_KEY", "")
app.config["MAX_CONTENT_LENGTH"] = 128 * 1024
CSRFProtect(app)


def ler_inteiro(valor, minimo=1):
    numero = int(valor)
    if numero < minimo:
        raise ValueError("Número fora do intervalo permitido")
    return numero


def executar_escrita(sql, parametros):
    """Exemplo guiado: escrita parametrizada e commit explícito."""
    con = conectar()
    cur = None
    try:
        con.start_transaction()
        cur = con.cursor()
        cur.execute(sql, parametros)
        con.commit()
    except Exception:
        con.rollback()
        raise
    finally:
        if cur is not None:
            cur.close()
        con.close()


@app.errorhandler(mysql.connector.Error)
def erro_mysql(erro):
    app.logger.error("Falha MySQL %s", erro.errno)
    return render_template("erro.html", mensagem="Falha de banco. Verifique a conexão e as regras de integridade."), 503


@app.get("/")
def inicio():
    return render_template("index.html")


@app.get("/sobre")
def sobre():
    return render_template("sobre.html")


@app.get("/produtos")
def produtos():
    busca = request.args.get("busca", "").strip()[:80]
    dados = consultar(
        """SELECT p.ID_Produto,p.Nome_Produto,c.Categoria,p.Preco_Unit
           FROM produtos p JOIN categorias c ON c.ID_Categoria=p.ID_Categoria
           WHERE p.Nome_Produto LIKE %s ORDER BY p.Nome_Produto LIMIT 100""",
        (f"%{busca}%",),
    )
    return render_template("lista.html", titulo="Produtos", dados=dados, busca=busca)


@app.get("/categorias")
def categorias():
    dados = consultar("SELECT ID_Categoria,Categoria FROM categorias ORDER BY Categoria")
    return render_template("lista.html", titulo="Categorias", dados=dados)


@app.get("/clientes")
def clientes():
    dados = consultar("SELECT ID_Cliente,Nome,Sobrenome,Email FROM clientes ORDER BY ID_Cliente LIMIT 100")
    return render_template("lista.html", titulo="Clientes", dados=dados)


@app.get("/locais")
def locais():
    dados = consultar("SELECT ID_Local,Cidade,Estado,Regiao FROM locais ORDER BY Cidade")
    return render_template("lista.html", titulo="Locais", dados=dados)


@app.get("/lojas")
def lojas():
    dados = consultar(
        """SELECT l.ID_Loja,l.Loja,loc.Cidade,loc.Estado
           FROM lojas l JOIN locais loc ON loc.ID_Local=l.ID_Local
           ORDER BY l.Loja"""
    )
    return render_template("lista.html", titulo="Lojas", dados=dados)


@app.get("/vendedores")
def vendedores():
    dados = consultar(
        """SELECT v.ID_Vendedor,v.Nome,v.Email,l.Loja
           FROM vendedores v JOIN lojas l ON l.ID_Loja=v.ID_Loja
           ORDER BY v.Nome"""
    )
    return render_template("lista.html", titulo="Vendedores", dados=dados)


@app.get("/pedidos")
def pedidos():
    dados = consultar(
        """SELECT p.ID_Pedido,p.Data_Pedido,p.Valor_Total,
                  p.Origem_Registro,s.Descricao AS Status,
                  c.Nome AS Cliente,l.Loja
           FROM pedidos p
           JOIN clientes c ON c.ID_Cliente=p.ID_Cliente
           JOIN lojas l ON l.ID_Loja=p.ID_Loja
           JOIN status_pedido s ON s.ID_Status=p.ID_Status
           ORDER BY p.ID_Pedido DESC LIMIT 100"""
    )
    return render_template("lista.html", titulo="Pedidos (100 mais recentes)", dados=dados, links_pedidos=True)


@app.get("/pedidos/<int:pedido_id>")
def pedido_detalhe(pedido_id):
    cabecalho = consultar(
        """SELECT p.ID_Pedido,p.Data_Pedido,p.Valor_Total,p.Origem_Registro,
                  s.Descricao AS Status,c.Nome AS Cliente,l.Loja,
                  v.Nome AS Vendedor
           FROM pedidos p JOIN clientes c ON c.ID_Cliente=p.ID_Cliente
           JOIN lojas l ON l.ID_Loja=p.ID_Loja
           JOIN status_pedido s ON s.ID_Status=p.ID_Status
           LEFT JOIN vendedores v ON v.ID_Vendedor=p.ID_Vendedor
           WHERE p.ID_Pedido=%s""", (pedido_id,)
    )
    if not cabecalho:
        return render_template("erro.html", mensagem="Pedido não encontrado."), 404
    itens = consultar(
        """SELECT i.Quantidade,i.Preco_Unit,i.Desconto_Valor,i.Ajuste_Valor,
                  pr.Nome_Produto,(i.Quantidade*i.Preco_Unit-i.Desconto_Valor+i.Ajuste_Valor) AS Subtotal
           FROM itens_pedido i JOIN produtos pr ON pr.ID_Produto=i.ID_Produto
           WHERE i.ID_Pedido=%s ORDER BY i.ID_Item""", (pedido_id,)
    )
    pagamentos = consultar(
        """SELECT pg.Valor_Pagamento,pg.Data_Pagamento,fp.Descricao AS Forma,
                  sp.Descricao AS Status
           FROM pagamentos pg
           JOIN formas_pagamento fp ON fp.ID_Forma=pg.ID_Forma
           JOIN status_pagamento sp ON sp.ID_Status=pg.ID_Status
           WHERE pg.ID_Pedido=%s ORDER BY pg.ID_Pagamento""", (pedido_id,)
    )
    return render_template("pedido.html", pedido=cabecalho[0], itens=itens, pagamentos=pagamentos)


@app.route("/categorias/novo", methods=["GET", "POST"])
def categoria_nova():
    if request.method == "POST":
        try:
            ident = ler_inteiro(request.form.get("id_categoria"))
            nome = request.form.get("nome", "").strip()
            if not 1 <= len(nome) <= 80:
                raise ValueError("Nome deve conter entre 1 e 80 caracteres")
            executar_escrita(
                "INSERT INTO categorias (ID_Categoria,Categoria) VALUES (%s,%s)",
                (ident, nome),
            )
            flash("Categoria cadastrada.")
            return redirect(url_for("categorias"))
        except (ValueError, TypeError):
            flash("Revise o identificador e o nome.")
        except mysql.connector.IntegrityError:
            flash("Identificador ou nome já utilizado.")
    return render_template("categoria_nova.html")


@app.route("/pedidos/novo", methods=["GET", "POST"])
def pedido_novo():
    clientes = consultar("SELECT ID_Cliente,Nome,Sobrenome FROM clientes ORDER BY Nome LIMIT 200")
    lojas = consultar("SELECT ID_Loja,Loja FROM lojas ORDER BY Loja")
    vendedores = consultar("SELECT ID_Vendedor,Nome,ID_Loja FROM vendedores ORDER BY Nome")
    produtos = consultar("SELECT ID_Produto,Nome_Produto,Preco_Unit FROM produtos ORDER BY Nome_Produto")
    if request.method == "POST":
        con = conectar()
        cur = None
        try:
            cliente_id = ler_inteiro(request.form.get("cliente"))
            loja_id = ler_inteiro(request.form.get("loja"))
            vendedor_id = ler_inteiro(request.form.get("vendedor"))
            ids = [ler_inteiro(x) for x in request.form.getlist("produto")]
            quantidades = [ler_inteiro(x) for x in request.form.getlist("quantidade")]
            if len(ids) != len(quantidades) or len(ids) < 2 or len(set(ids)) != len(ids):
                raise ValueError("Escolha pelo menos dois produtos distintos.")
            if len(ids) > 5 or any(q > 100 for q in quantidades):
                raise ValueError("Máximo de cinco itens e 100 unidades por item.")
            con.start_transaction()
            cur = con.cursor(dictionary=True)
            cur.execute("SELECT ID_Cliente FROM clientes WHERE ID_Cliente=%s", (cliente_id,))
            if cur.fetchone() is None:
                raise ValueError("Cliente não encontrado.")
            cur.execute("SELECT ID_Vendedor FROM vendedores WHERE ID_Vendedor=%s AND ID_Loja=%s",
                        (vendedor_id, loja_id))
            if cur.fetchone() is None:
                raise ValueError("O vendedor não pertence à loja selecionada.")
            marcadores = ",".join(["%s"] * len(ids))
            cur.execute(
                f"SELECT ID_Produto,Preco_Unit,Custo_Unit FROM produtos WHERE ID_Produto IN ({marcadores}) FOR SHARE",
                tuple(ids),
            )
            precos = {r["ID_Produto"]: r for r in cur.fetchall()}
            if len(precos) != len(ids):
                raise ValueError("Há produtos inválidos na seleção.")
            total = sum((Decimal(precos[i]["Preco_Unit"]) * q for i, q in zip(ids, quantidades)),
                        Decimal("0.00"))
            custos = [precos[i]["Custo_Unit"] for i in ids]
            custo_total = (sum((Decimal(c) * q for c, q in zip(custos, quantidades)), Decimal("0.00"))
                           if all(c is not None for c in custos) else None)
            # Tabela de sequência preparada SOMENTE na cópia de laboratório.
            # INSERT auto_increment é concorrente e dispensa MAX(ID)+1.
            cur.execute("INSERT INTO portal_ids_pedido () VALUES ()")
            pedido_id = cur.lastrowid
            cur.execute(
                """INSERT INTO pedidos
                   (ID_Pedido,Data_Pedido,ID_Loja,ID_Cliente,ID_Vendedor,
                    ID_Status,Valor_Total,Custo_Total,Origem_Registro,Observacao)
                   VALUES (%s,%s,%s,%s,%s,1,%s,%s,'OPERACAO_V3','Pedido de laboratorio')""",
                (pedido_id, datetime.now(), loja_id, cliente_id, vendedor_id, total, custo_total),
            )
            for i, q in zip(ids, quantidades):
                item = precos[i]
                cur.execute(
                    """INSERT INTO itens_pedido
                       (ID_Pedido,ID_Produto,Quantidade,Preco_Unit,Custo_Unit,Desconto_Valor,Ajuste_Valor)
                       VALUES (%s,%s,%s,%s,%s,0,0)""",
                    (pedido_id, i, q, item["Preco_Unit"], item["Custo_Unit"]),
                )
            con.commit()
            flash("Pedido confirmado com itens em uma única transação.")
            return redirect(url_for("pedido_detalhe", pedido_id=pedido_id))
        except (TypeError, ValueError) as erro:
            con.rollback()
            flash(str(erro))
        except mysql.connector.IntegrityError:
            con.rollback()
            flash("Operação rejeitada por regra de integridade.")
        except mysql.connector.Error:
            con.rollback()
            raise
        finally:
            if cur is not None:
                cur.close()
            con.close()
    return render_template("pedido_novo.html", clientes=clientes, lojas=lojas,
                           vendedores=vendedores, produtos=produtos)


@app.route("/pedidos/<int:pedido_id>/pagamentos/novo", methods=["GET", "POST"])
def pagamento_novo(pedido_id):
    encontrado = consultar("SELECT ID_Pedido,Origem_Registro FROM pedidos WHERE ID_Pedido=%s",
                           (pedido_id,))
    if not encontrado:
        return render_template("erro.html", mensagem="Pedido não encontrado."), 404
    if encontrado[0]["Origem_Registro"] != "OPERACAO_V3":
        return render_template("erro.html", mensagem="Não se pode inventar pagamento para pedidos históricos."), 403
    formas = consultar("SELECT ID_Forma,Descricao FROM formas_pagamento ORDER BY ID_Forma")
    status = consultar("SELECT ID_Status,Descricao FROM status_pagamento ORDER BY ID_Status")
    if request.method == "POST":
        try:
            forma_id = ler_inteiro(request.form.get("forma"))
            status_id = ler_inteiro(request.form.get("status"))
            valor = Decimal(request.form.get("valor", "").replace(",", "."))
            if not valor.is_finite() or valor <= 0 or valor != valor.quantize(Decimal("0.01")):
                raise ValueError("Valor inválido.")
            pago_em = datetime.now() if status_id == 2 else None
            executar_escrita(
                """INSERT INTO pagamentos
                   (ID_Pedido,ID_Forma,ID_Status,Valor_Pagamento,Data_Pagamento,Observacao)
                   VALUES (%s,%s,%s,%s,%s,%s)""",
                (pedido_id, forma_id, status_id, valor, pago_em, "Operação de laboratório"),
            )
            flash("Registro de pagamento gravado.")
            return redirect(url_for("pedido_detalhe", pedido_id=pedido_id))
        except (ValueError, TypeError, InvalidOperation):
            flash("Verifique forma, status e valor monetário.")
        except mysql.connector.IntegrityError:
            flash("Pagamento rejeitado por regra de integridade.")
    return render_template("pagamento_novo.html", pedido_id=pedido_id, formas=formas, status=status)


@app.get("/relatorios")
def relatorios():
    # Sem JOIN com itens para somar totais de pedidos: evita multiplicação de receita.
    por_loja = consultar(
        """SELECT l.Loja,COUNT(p.ID_Pedido) AS Qtd_Pedidos,
                  COALESCE(SUM(p.Valor_Total),0) AS Valor_Registrado
           FROM lojas l LEFT JOIN pedidos p ON p.ID_Loja=l.ID_Loja
           GROUP BY l.ID_Loja,l.Loja ORDER BY Valor_Registrado DESC"""
    )
    por_status = consultar(
        """SELECT s.Descricao AS Status,COUNT(p.ID_Pedido) AS Quantidade
           FROM status_pedido s LEFT JOIN pedidos p ON p.ID_Status=s.ID_Status
           GROUP BY s.ID_Status,s.Descricao ORDER BY s.ID_Status"""
    )
    mais_vendidos = consultar(
        """SELECT pr.Nome_Produto,SUM(i.Quantidade) AS Unidades
           FROM itens_pedido i JOIN produtos pr ON pr.ID_Produto=i.ID_Produto
           GROUP BY pr.ID_Produto,pr.Nome_Produto ORDER BY Unidades DESC LIMIT 10"""
    )
    return render_template("relatorios.html", por_loja=por_loja,
                           por_status=por_status, mais_vendidos=mais_vendidos)


if __name__ == "__main__":
    # Execução local somente; nunca escute em 0.0.0.0.
    app.run(host="127.0.0.1", debug=False)
