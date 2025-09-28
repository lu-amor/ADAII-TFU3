from flask import Blueprint, request, jsonify
from db import db
from models import Producto

productos_bp = Blueprint("productos", __name__)

@productos_bp.route("/", methods=["POST"])
def crear_producto():
    """Stateless product creation with ACID transaction"""
    data = request.get_json()
    
    # Stateless validation
    if not data or not data.get("nombre") or not data.get("nombre").strip():
        return jsonify({"error": "Nombre es requerido y no puede estar vacío"}), 400
    
    try:
        # ACID transaction for product creation
        with db.session.begin():
            nuevo = Producto(nombre=data["nombre"].strip())
            db.session.add(nuevo)
            db.session.commit()
            
        return jsonify({
            "msg": "Producto creado", 
            "id": nuevo.id,
            "nombre": nuevo.nombre,
            "timestamp": "stateless_operation"  # No server state
        }), 201
        
    except Exception as e:
        db.session.rollback()
        # Check for unique constraint violation (duplicate product)
        if "unique constraint" in str(e).lower() or "duplicate" in str(e).lower():
            return jsonify({"error": f"Producto '{data['nombre']}' ya existe"}), 400
        return jsonify({"error": f"Error creando producto: {str(e)}"}), 500

@productos_bp.route("/", methods=["GET"])
def listar_productos():
    """Stateless product listing - no session state maintained"""
    try:
        productos = Producto.query.all()
        return jsonify({
            "productos": [{"id": p.id, "nombre": p.nombre} for p in productos],
            "total": len(productos),
            "operation": "stateless_query"  # Emphasizing stateless nature
        })
    except Exception as e:
        return jsonify({"error": f"Error obteniendo productos: {str(e)}"}), 500

@productos_bp.route("/<int:producto_id>", methods=["GET"])
def obtener_producto(producto_id):
    """Get individual product - stateless operation"""
    try:
        producto = Producto.query.get(producto_id)
        if not producto:
            return jsonify({"error": "Producto no encontrado"}), 404
            
        return jsonify({
            "id": producto.id,
            "nombre": producto.nombre,
            "recetas": [{"id": r.id, "nombre": r.nombre} for r in producto.recetas],
            "operation": "stateless_fetch"
        })
    except Exception as e:
        return jsonify({"error": f"Error obteniendo producto: {str(e)}"}), 500
