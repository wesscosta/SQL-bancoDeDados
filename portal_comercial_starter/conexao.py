"""Conexão e consultas explícitas para o laboratório banco_v3 (sem ORM)."""
import os
import mysql.connector
from dotenv import load_dotenv

load_dotenv()

def conectar():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        database=os.getenv("DB_NAME", "banco_v3_lab"),
        user=os.getenv("DB_USER", ""),
        password=os.getenv("DB_PASSWORD", ""),
        autocommit=False,
    )

def consultar(sql: str, parametros: tuple = ()) -> list[dict]:
    con = conectar()
    cur = None
    try:
        cur = con.cursor(dictionary=True)
        cur.execute(sql, parametros)
        return cur.fetchall()
    finally:
        if cur is not None:
            cur.close()
        con.close()
