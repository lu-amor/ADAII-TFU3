from flask import Flask, jsonify
from db import db
from routes.productos import productos_bp
from routes.recetas import recetas_bp
from routes.listas import listas_bp
import os
import time
import logging

app = Flask(__name__)

# Config DB con variables de entorno
app.config['SQLALCHEMY_DATABASE_URI'] = f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}/{os.getenv('DB_NAME')}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

# Blueprints
app.register_blueprint(productos_bp, url_prefix="/productos")
app.register_blueprint(recetas_bp, url_prefix="/recetas")
app.register_blueprint(listas_bp, url_prefix="/listas")

def wait_for_db():
    """Wait for database to be ready and create tables"""
    max_retries = 30
    retry_count = 0
    
    while retry_count < max_retries:
        try:
            with app.app_context():
                db.create_all()
                logging.info("Database connected and tables created successfully")
                return True
        except Exception as e:
            retry_count += 1
            logging.warning(f"Database not ready, attempt {retry_count}/{max_retries}: {e}")
            time.sleep(2)
    
    logging.error("Failed to connect to database after maximum retries")
    return False

@app.route("/")
def index():
    return jsonify({"msg": "API Recetas funcionando 🚀"})

if __name__ == "__main__":
    # Wait for database before starting the server
    if wait_for_db():
        app.run(host="0.0.0.0", port=8000, debug=True)
    else:
        logging.error("Cannot start API: Database connection failed")
        exit(1)