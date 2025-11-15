from flask import Flask, request, jsonify, Response
import os
import requests
from db import db
import logging
from models import Receta, Producto
import xml.etree.ElementTree as ET

# Reuse PRODUCTOS_URL from env (already present)

app = Flask(__name__)

DB_HOST = os.environ.get('DB_HOST', 'db_recetas')
DB_USER = os.environ.get('DB_USER', 'user')
DB_PASS = os.environ.get('DB_PASSWORD', 'pass')
DB_NAME = os.environ.get('DB_NAME', 'recetas_db')
DB_PORT = os.environ.get('DB_PORT', '5432')

# URL of productos service (compose service name)
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


@app.route('/recetas', methods=['GET'])
def list_recetas():
    recetas = Receta.query.all()
    out = []
    for r in recetas:
        out.append({'id': r.id, 'nombre': r.nombre, 'productos': [p.nombre for p in r.productos]})
    return jsonify(out)


@app.route('/recetas', methods=['POST'])
def create_receta():
    data = request.get_json() or {}
    nombre = data.get('nombre')
    productos = data.get('productos', [])
    if not nombre:
        return jsonify({'error': 'nombre is required'}), 400
    r = Receta(nombre=nombre)
    # Ensure products exist in productos service; create if missing
    for pn in productos:
        try:
            # Try creating product in central productos service
            resp = requests.post(f"{PRODUCTOS_URL}/productos", json={"nombre": pn}, timeout=5)
        except requests.RequestException:
            return jsonify({'error': 'failed to reach productos service'}), 503

        if resp.status_code == 201:
            # created, good
            pass
        elif resp.status_code == 409:
            # already exists, that's fine
            pass
        else:
            return jsonify({'error': 'productos service error', 'details': resp.text}), 502

        # Keep a local Producto row for relationship convenience
        p = Producto.query.filter_by(nombre=pn).first()
        if not p:
            p = Producto(nombre=pn)
            db.session.add(p)
        r.productos.append(p)
    db.session.add(r)
    db.session.commit()
    return jsonify({'id': r.id, 'nombre': r.nombre, 'productos': [p.nombre for p in r.productos]}), 201


def _soap_fault(faultcode, faultstring):
    envelope = ET.Element('{http://schemas.xmlsoap.org/soap/envelope/}Envelope')
    envelope.set('xmlns:soap', 'http://schemas.xmlsoap.org/soap/envelope/')
    body = ET.SubElement(envelope, '{http://schemas.xmlsoap.org/soap/envelope/}Body')
    fault = ET.SubElement(body, '{http://schemas.xmlsoap.org/soap/envelope/}Fault')
    code = ET.SubElement(fault, 'faultcode')
    code.text = faultcode
    string = ET.SubElement(fault, 'faultstring')
    string.text = faultstring
    return Response(ET.tostring(envelope, encoding='utf-8', xml_declaration=True), mimetype='text/xml')


@app.route('/soap/recetas', methods=['POST'])
def soap_create_receta():
    """Accepts a SOAP Envelope to create a receta.

    Expected XML structure (example):
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <CreateReceta>
          <nombre>Tortilla</nombre>
          <productos>
            <nombre>Huevos</nombre>
            <nombre>Leche</nombre>
          </productos>
        </CreateReceta>
      </soap:Body>
    </soap:Envelope>
    """
    data = request.data
    try:
        tree = ET.fromstring(data)
    except ET.ParseError:
        return _soap_fault('Client', 'Malformed XML')

    body = tree.find('.//{http://schemas.xmlsoap.org/soap/envelope/}Body') or tree.find('.//Body')
    if body is None:
        return _soap_fault('Client', 'Missing SOAP Body')

    # operation node
    op = None
    for child in list(body):
        op = child
        break
    if op is None:
        return _soap_fault('Client', 'No operation in SOAP Body')

    nombre_el = op.find('nombre') or op.find('Nombre') or op.find('.//nombre')
    if nombre_el is None or not (nombre_el.text and nombre_el.text.strip()):
        return _soap_fault('Client', 'Missing receta nombre')
    receta_nombre = nombre_el.text.strip()

    # collect product names
    productos_list = []
    productos_parent = op.find('productos') or op.find('Productos') or op.find('.//productos')
    if productos_parent is not None:
        for p_el in list(productos_parent):
            if p_el is None:
                continue
            # accept <nombre> or direct text
            tagname = p_el.tag.lower()
            if tagname.endswith('nombre') and p_el.text and p_el.text.strip():
                productos_list.append(p_el.text.strip())
            elif p_el.text and p_el.text.strip():
                productos_list.append(p_el.text.strip())

    # ensure products exist in productos service
    for pname in productos_list:
        try:
            p_resp = requests.post(f"{PRODUCTOS_URL}/productos", json={"nombre": pname}, timeout=5)
        except requests.RequestException:
            return _soap_fault('Server', f'productos service unavailable for {pname}')
        if p_resp.status_code not in (200, 201, 409):
            return _soap_fault('Server', f'productos service error for {pname}: {p_resp.status_code}')

    # create receta locally
    try:
        r = Receta(nombre=receta_nombre)
        for pname in productos_list:
            p = Producto.query.filter_by(nombre=pname).first()
            if not p:
                p = Producto(nombre=pname)
                db.session.add(p)
                db.session.flush()
            r.productos.append(p)
        db.session.add(r)
        db.session.commit()
    except Exception as e:
        logging.exception('Failed to create receta')
        return _soap_fault('Server', 'Database error while creating receta')

    # build SOAP response
    envelope = ET.Element('{http://schemas.xmlsoap.org/soap/envelope/}Envelope')
    envelope.set('xmlns:soap', 'http://schemas.xmlsoap.org/soap/envelope/')
    body_resp = ET.SubElement(envelope, '{http://schemas.xmlsoap.org/soap/envelope/}Body')
    resp_el = ET.SubElement(body_resp, 'CreateRecetaResponse')
    id_el = ET.SubElement(resp_el, 'id')
    id_el.text = str(r.id)
    name_el = ET.SubElement(resp_el, 'nombre')
    name_el.text = r.nombre
    prods_el = ET.SubElement(resp_el, 'productos')
    for pname in productos_list:
        pn = ET.SubElement(prods_el, 'nombre')
        pn.text = pname

    return Response(ET.tostring(envelope, encoding='utf-8', xml_declaration=True), mimetype='text/xml')


@app.route('/recetas/<int:rid>', methods=['GET'])
def get_receta(rid):
    r = Receta.query.get_or_404(rid)
    return jsonify({'id': r.id, 'nombre': r.nombre, 'productos': [p.nombre for p in r.productos]})


@app.route('/recetas/<int:rid>', methods=['PUT'])
def update_receta(rid):
    r = Receta.query.get_or_404(rid)
    data = request.get_json() or {}
    nombre = data.get('nombre')
    productos = data.get('productos')
    if nombre:
        r.nombre = nombre
    if productos is not None:
        r.productos = []
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
            r.productos.append(p)
    db.session.commit()
    return jsonify({'id': r.id, 'nombre': r.nombre, 'productos': [p.nombre for p in r.productos]})


@app.route('/recetas/<int:rid>', methods=['DELETE'])
def delete_receta(rid):
    r = Receta.query.get_or_404(rid)
    db.session.delete(r)
    db.session.commit()
    return jsonify({'result': 'deleted'})


if __name__ == '__main__':
    create_tables()
    app.run(host='0.0.0.0', port=8002)
