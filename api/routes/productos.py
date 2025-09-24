from flask import Blueprint, request, jsonify
from db import db
from models import Producto

productos_bp = Blueprint("productos", __name__)

@productos_bp.route("/", methods=["POST"])
def crear_producto():
    data = request.get_json()
    nuevo = Producto(nombre=data["nombre"])
    db.session.add(nuevo)
    db.session.commit()
    return jsonify({"msg": "Producto creado", "id": nuevo.id}), 201

@productos_bp.route("/", methods=["GET"])
def listar_productos():
    productos = Producto.query.all()
    return jsonify([{"id": p.id, "nombre": p.nombre} for p in productos])
