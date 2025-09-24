from flask import Blueprint, request, jsonify
from db import db
from models import Lista, Producto

listas_bp = Blueprint("listas", __name__)

# Crear lista con productos
@listas_bp.route("/", methods=["POST"])
def crear_lista():
    data = request.get_json()
    try:
        with db.session.begin():  # Transacción ACID
            lista = Lista(nombre=data["nombre"])
            db.session.add(lista)
            for pid in data.get("productos", []):
                producto = Producto.query.get(pid)
                if producto:
                    lista.productos.append(producto)
            db.session.commit()
        return jsonify({"msg": "Lista creada", "id": lista.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 400

# Listar todas las listas
@listas_bp.route("/", methods=["GET"])
def listar_listas():
    listas = Lista.query.all()
    return jsonify([
        {
            "id": l.id,
            "nombre": l.nombre,
            "productos": [{"id": p.id, "nombre": p.nombre} for p in l.productos]
        } for l in listas
    ])

# Agregar productos a una lista
@listas_bp.route("/<int:lista_id>/productos", methods=["POST"])
def agregar_productos(lista_id):
    data = request.get_json()
    lista = Lista.query.get(lista_id)
    if not lista:
        return jsonify({"error": "Lista no encontrada"}), 404
    try:
        for pid in data.get("productos", []):
            producto = Producto.query.get(pid)
            if producto and producto not in lista.productos:
                lista.productos.append(producto)
        db.session.commit()
        return jsonify({"msg": "Productos agregados"}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 400
