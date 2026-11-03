import os
import pymysql
from flask import Flask, render_template_string

app = Flask(__name__)

PAGE = """<!doctype html><html lang="fr"><meta charset="utf-8"><title>Mini Datacenter</title>
<h1>Mini Datacenter v2 : inventaire</h1>
<p>Données lues dans MariaDB (db01, zone DATA) par web01 (DMZ).</p>
<table border="1" cellpadding="6"><tr><th>Nom</th><th>Zone</th><th>IP</th></tr>
{% for s in services %}<tr><td>{{ s.nom }}</td><td>{{ s.zone }}</td><td>{{ s.ip }}</td></tr>{% endfor %}
</table>"""

def connect():
    # Paramètres lus dans les variables d'environnement (fichier .env)
    return pymysql.connect(
        host=os.environ["DB_HOST"], user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"], database=os.environ["DB_NAME"],
        connect_timeout=3, cursorclass=pymysql.cursors.DictCursor)

@app.route("/")
def index():
    with connect() as conn, conn.cursor() as cur:
        cur.execute("SELECT nom, zone, ip FROM services ORDER BY id")
        services = cur.fetchall()
    return render_template_string(PAGE, services=services)

@app.route("/health")
def health():
    # Vérifie que la base répond, sans exposer de détail sensible
    try:
        with connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1")
        return {"status": "ok", "db": "ok"}
    except Exception as e:
        return {"status": "degraded", "db": e.__class__.__name__}, 503
