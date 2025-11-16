from flask import Flask, request, jsonify
import os
from db import db
from models import Producto

app = Flask(__name__)

DB_HOST = os.environ.get('DB_HOST', 'db_productos')
DB_USER = os.environ.get('DB_USER', 'user')
DB_PASS = os.environ.get('DB_PASSWORD', 'pass')
DB_NAME = os.environ.get('DB_NAME', 'productos_db')
DB_PORT = os.environ.get('DB_PORT', '5432')

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


@app.route('/productos', methods=['GET'])
def list_productos():
    nombre = request.args.get('nombre')
    if nombre:
        p = Producto.query.filter_by(nombre=nombre).first()
        if not p:
            return jsonify([])
        return jsonify([{'id': p.id, 'nombre': p.nombre}])

    productos = Producto.query.all()
    return jsonify([{'id': p.id, 'nombre': p.nombre} for p in productos])


@app.route('/productos', methods=['POST'])
def create_producto():
    data = request.get_json() or {}
    nombre = data.get('nombre')
    if not nombre:
        return jsonify({'error': 'nombre is required'}), 400
    if Producto.query.filter_by(nombre=nombre).first():
        return jsonify({'error': 'producto already exists'}), 409
    p = Producto(nombre=nombre)
    db.session.add(p)
    db.session.commit()
    return jsonify({'id': p.id, 'nombre': p.nombre}), 201


@app.route('/productos/<int:pid>', methods=['GET'])
def get_producto(pid):
    p = Producto.query.get_or_404(pid)
    return jsonify({'id': p.id, 'nombre': p.nombre})


@app.route('/productos/<int:pid>', methods=['PUT'])
def update_producto(pid):
    p = Producto.query.get_or_404(pid)
    data = request.get_json() or {}
    nombre = data.get('nombre')
    if nombre:
        p.nombre = nombre
        db.session.commit()
    return jsonify({'id': p.id, 'nombre': p.nombre})


@app.route('/productos/<int:pid>', methods=['DELETE'])
def delete_producto(pid):
    p = Producto.query.get_or_404(pid)
    db.session.delete(p)
    db.session.commit()
    return jsonify({'result': 'deleted'})


@app.route('/health')
def health():
    return jsonify({'status': 'ok'}), 200


if __name__ == '__main__':
    # Ensure tables exist before serving requests
    create_tables()
    app.run(host='0.0.0.0', port=8001)
