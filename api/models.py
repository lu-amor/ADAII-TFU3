from db import db

# Tabla intermedia Receta-Producto
receta_producto = db.Table(
    'receta_producto',
    db.Column('receta_id', db.Integer, db.ForeignKey('receta.id'), primary_key=True),
    db.Column('producto_id', db.Integer, db.ForeignKey('producto.id'), primary_key=True)
)

class Producto(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False, unique=True)

class Receta(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    productos = db.relationship('Producto', secondary=receta_producto, backref='recetas')

class Lista(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    productos = db.relationship('Producto', secondary='lista_producto', backref='listas')

# Tabla intermedia Lista-Producto
lista_producto = db.Table(
    'lista_producto',
    db.Column('lista_id', db.Integer, db.ForeignKey('lista.id'), primary_key=True),
    db.Column('producto_id', db.Integer, db.ForeignKey('producto.id'), primary_key=True)
)
