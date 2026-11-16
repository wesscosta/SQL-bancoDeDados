"""Permite executar pytest da raiz do repo ou da pasta do Portal."""
from pathlib import Path
import sys

portal = str(Path(__file__).resolve().parents[1])
if portal not in sys.path:
    sys.path.insert(0, portal)
