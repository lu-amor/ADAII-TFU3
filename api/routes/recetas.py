from flask import Blueprint, request, jsonify
from db import db
from models import Receta, Producto

recetas_bp = Blueprint("recetas", __name__)

@recetas_bp.route("/", methods=["POST"])
def crear_receta():
    data = request.get_json()
    try:
        with db.session.begin():  # <-- Transacción ACID
            receta = Receta(nombre=data["nombre"])
            db.session.add(receta)
            for pid in data["productos"]:
                producto = Producto.query.get(pid)
                if producto:
                    receta.productos.append(producto)
            db.session.commit()
        return jsonify({"msg": "Receta creada", "id": receta.id}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 400
