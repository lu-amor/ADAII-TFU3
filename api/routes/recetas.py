from flask import Blueprint, request, jsonify
from db import db
from models import Receta, Producto

recetas_bp = Blueprint("recetas", __name__)

@recetas_bp.route("/", methods=["POST"])
def crear_receta():
    data = request.get_json()
    
    # Validate required fields (stateless validation)
    if not data or not data.get("nombre"):
        return jsonify({"error": "Nombre es requerido"}), 400
    
    try:
        with db.session.begin():  # ACID Transaction
            receta = Receta(nombre=data["nombre"])
            db.session.add(receta)
            db.session.flush()  # Get ID before commit
            
            # Add products to recipe
            productos_agregados = 0
            for pid in data.get("productos", []):
                producto = Producto.query.get(pid)
                if producto:
                    receta.productos.append(producto)
                    productos_agregados += 1
            
            db.session.commit()
            
        return jsonify({
            "msg": "Receta creada", 
            "id": receta.id,
            "productos_agregados": productos_agregados,
            "transaction_id": f"tx_{receta.id}"  # Demonstrating transaction tracking
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Transaction failed: {str(e)}"}), 400

@recetas_bp.route("/", methods=["GET"])
def listar_recetas():
    """Stateless endpoint - retrieves all recipes without maintaining session state"""
    recetas = Receta.query.all()
    return jsonify([
        {
            "id": r.id,
            "nombre": r.nombre,
            "productos": [{"id": p.id, "nombre": p.nombre} for p in r.productos],
            "num_productos": len(r.productos)
        } for r in recetas
    ])
