from flask import Flask, request, jsonify
import os
import requests
from db import db
from models import Lista, Producto

app = Flask(__name__)

DB_HOST = os.environ.get('DB_HOST', 'db_listas')
DB_USER = os.environ.get('DB_USER', 'user')
DB_PASS = os.environ.get('DB_PASSWORD', 'pass')
DB_NAME = os.environ.get('DB_NAME', 'listas_db')
DB_PORT = os.environ.get('DB_PORT', '5432')

PRODUCTOS_URL = os.environ.get('PRODUCTOS_URL', 'http://productos:8001')

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)


def create_tables(wait=True, attempts=30, delay=2):
    """Create DB tables with optional wait/retry for the DB to be ready."""
    import time
    for i in range(attempts):
        try:
            with app.app_context():
                db.create_all()
            return
        except Exception:
            if not wait:
                raise
            time.sleep(delay)


@app.route('/listas', methods=['GET'])
def list_listas():
    listas = Lista.query.all()
    out = []
    for l in listas:
        out.append({'id': l.id, 'nombre': l.nombre, 'productos': [p.nombre for p in l.productos]})
    return jsonify(out)


@app.route('/listas', methods=['POST'])
def create_lista():
    data = request.get_json() or {}
    nombre = data.get('nombre')
    productos = data.get('productos', [])
    if not nombre:
        return jsonify({'error': 'nombre is required'}), 400
    l = Lista(nombre=nombre)
    for pn in productos:
        try:
            resp = requests.post(f"{PRODUCTOS_URL}/productos", json={"nombre": pn}, timeout=5)
        except requests.RequestException:
            return jsonify({'error': 'failed to reach productos service'}), 503

        if resp.status_code == 201:
            pass
        elif resp.status_code == 409:
            pass
        else:
            return jsonify({'error': 'productos service error', 'details': resp.text}), 502

        p = Producto.query.filter_by(nombre=pn).first()
        if not p:
            p = Producto(nombre=pn)
            db.session.add(p)
        l.productos.append(p)
    db.session.add(l)
    db.session.commit()
    return jsonify({'id': l.id, 'nombre': l.nombre, 'productos': [p.nombre for p in l.productos]}), 201


@app.route('/listas/<int:lid>', methods=['GET'])
def get_lista(lid):
    l = Lista.query.get_or_404(lid)
    return jsonify({'id': l.id, 'nombre': l.nombre, 'productos': [p.nombre for p in l.productos]})


@app.route('/listas/<int:lid>', methods=['PUT'])
def update_lista(lid):
    l = Lista.query.get_or_404(lid)
    data = request.get_json() or {}
    nombre = data.get('nombre')
    productos = data.get('productos')
    if nombre:
        l.nombre = nombre
    if productos is not None:
        l.productos = []
        for pn in productos:
            try:
                resp = requests.post(f"{PRODUCTOS_URL}/productos", json={"nombre": pn}, timeout=5)
            except requests.RequestException:
                return jsonify({'error': 'failed to reach productos service'}), 503

            if resp.status_code not in (201, 409):
                return jsonify({'error': 'productos service error', 'details': resp.text}), 502

            p = Producto.query.filter_by(nombre=pn).first()
            if not p:
                p = Producto(nombre=pn)
                db.session.add(p)
            l.productos.append(p)
    db.session.commit()
    return jsonify({'id': l.id, 'nombre': l.nombre, 'productos': [p.nombre for p in l.productos]})


@app.route('/listas/<int:lid>', methods=['DELETE'])
def delete_lista(lid):
    l = Lista.query.get_or_404(lid)
    db.session.delete(l)
    db.session.commit()
    return jsonify({'result': 'deleted'})


if __name__ == '__main__':
    create_tables()
    app.run(host='0.0.0.0', port=8003)
