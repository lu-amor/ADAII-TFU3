from flask import Flask, request, Response, jsonify
import os
import time
import logging
import xml.etree.ElementTree as ET
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import threading

# Service URLs used by the gateway to call microservices
SERVICE_URLS = {
    'productos': os.environ.get('PRODUCTOS_URL', 'http://productos:8001'),
    'recetas': os.environ.get('RECETAS_URL', 'http://recetas:8002'),
    'listas': os.environ.get('LISTAS_URL', 'http://listas:8003'),
}

app = Flask(__name__)

# Resilience configuration (can be tuned via env)
RETRY_TOTAL = int(os.environ.get('GATEWAY_RETRY_TOTAL', '3'))
RETRY_BACKOFF = float(os.environ.get('GATEWAY_RETRY_BACKOFF', '0.3'))
CB_THRESHOLD = int(os.environ.get('GATEWAY_CB_THRESHOLD', '5'))
CB_COOLDOWN = int(os.environ.get('GATEWAY_CB_COOLDOWN', '30'))  # seconds


# Create a requests.Session with retries
def _create_session():
    session = requests.Session()
    retry = Retry(
        total=RETRY_TOTAL,
        backoff_factor=RETRY_BACKOFF,
        status_forcelist=[429, 500, 502, 503, 504],
        allowed_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount('http://', adapter)
    session.mount('https://', adapter)
    return session


# Simple in-memory circuit-breaker state
_cb_lock = threading.Lock()
_cb_state = {name: {'failures': 0, 'until': 0} for name in SERVICE_URLS.keys()}


def _is_open(name):
    st = _cb_state.get(name)
    if not st:
        return False
    return time.time() < st['until']


def _record_failure(name):
    with _cb_lock:
        st = _cb_state.setdefault(name, {'failures': 0, 'until': 0})
        st['failures'] += 1
        if st['failures'] >= CB_THRESHOLD:
            st['until'] = time.time() + CB_COOLDOWN


def _record_success(name):
    with _cb_lock:
        st = _cb_state.setdefault(name, {'failures': 0, 'until': 0})
        st['failures'] = 0
        st['until'] = 0


# shared session
_session = _create_session()

# Gateway does not use a local database. It acts as a facade to microservices.


def _soap_fault(faultcode, faultstring):
    """Return a SOAP Fault XML Response body (string)."""
    envelope = ET.Element('{http://schemas.xmlsoap.org/soap/envelope/}Envelope')
    envelope.set('xmlns:soap', 'http://schemas.xmlsoap.org/soap/envelope/')
    body = ET.SubElement(envelope, '{http://schemas.xmlsoap.org/soap/envelope/}Body')
    fault = ET.SubElement(body, '{http://schemas.xmlsoap.org/soap/envelope/}Fault')
    code = ET.SubElement(fault, 'faultcode')
    code.text = faultcode
    string = ET.SubElement(fault, 'faultstring')
    string.text = faultstring
    return Response(ET.tostring(envelope, encoding='utf-8', xml_declaration=True), mimetype='text/xml')


def call_service(method, service_name, path, timeout=None, **kwargs):
    """Call a backend service using the shared session.

    Returns the requests.Response on success.
    Raises requests.RequestException on network/timeout errors.
    Implements a tiny circuit-breaker to avoid hammering a down service.
    """
    base = SERVICE_URLS.get(service_name)
    if not base:
        raise requests.RequestException(f'Unknown service: {service_name}')

    if _is_open(service_name):
        raise requests.RequestException(f'service {service_name} marked as down')

    url = base.rstrip('/') + path
    try:
        resp = _session.request(method, url, timeout=timeout, **kwargs)
        # treat 5xx as failures for circuit purposes
        if 500 <= resp.status_code < 600:
            _record_failure(service_name)
        else:
            _record_success(service_name)
        return resp
    except requests.RequestException:
        _record_failure(service_name)
        raise


@app.route('/soap/recetas', methods=['POST'])
def soap_recetas():
    """SOAP endpoint that accepts a SOAP envelope to create a Receta.
    Expected request body (example):

    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <CreateReceta>
          <nombre>Tortilla</nombre>
          <productos>
            <nombre>Leche</nombre>
            <nombre>Huevos</nombre>
          </productos>
        </CreateReceta>
      </soap:Body>
    </soap:Envelope>
    """
    try:
        tree = ET.fromstring(request.data)
    except ET.ParseError:
        return _soap_fault('Client', 'Malformed XML')

    body = tree.find('.//{http://schemas.xmlsoap.org/soap/envelope/}Body') or tree.find('.//Body')
    if body is None:
        return _soap_fault('Client', 'Missing SOAP Body')

    op = None
    for child in list(body):
        op = child
        break
    if op is None:
        return _soap_fault('Client', 'No operation found in SOAP Body')

    nombre_el = op.find('nombre') or op.find('Nombre') or op.find('.//nombre')
    if nombre_el is None or not (nombre_el.text and nombre_el.text.strip()):
        return _soap_fault('Client', 'Missing receta nombre')
    receta_nombre = nombre_el.text.strip()

    # Parse producto names: look for <productos><nombre>...</nombre></productos>
    productos_list = []
    productos_parent = op.find('productos') or op.find('Productos') or op.find('.//productos')
    if productos_parent is not None:
        for p_el in list(productos_parent):
            # accept either <nombre>text</nombre> or direct text nodes
            if p_el.tag.lower().endswith('nombre') and p_el.text:
                productos_list.append(p_el.text.strip())
            elif p_el.text and p_el.text.strip():
                productos_list.append(p_el.text.strip())
    else:
        # fallback: any sibling <producto> elements
        for p_el in op.findall('producto'):
            if p_el.text and p_el.text.strip():
                productos_list.append(p_el.text.strip())

    # Ensure each product exists in the productos microservice (create if missing)
    for pname in productos_list:
        try:
            p_resp = call_service('POST', 'productos', '/productos', json={"nombre": pname}, timeout=5)
        except requests.RequestException:
            return _soap_fault('Server', f'productos service unavailable when creating {pname}')

        if p_resp.status_code not in (200, 201, 409):
            return _soap_fault('Server', f'productos service error for {pname}: {p_resp.status_code}')

    # Now call the recetas microservice to create the receta using product names
        try:
            r_resp = call_service('POST', 'recetas', '/recetas', json={"nombre": receta_nombre, "productos": productos_list}, timeout=10)
        except requests.RequestException:
            return _soap_fault('Server', 'recetas service unavailable')

    if r_resp.status_code not in (200, 201):
        # forward error details if possible
        detail = r_resp.text if r_resp.text else str(r_resp.status_code)
        return _soap_fault('Server', f'recetas service error: {detail}')

    # Build SOAP response from recetas service JSON
    try:
        j = r_resp.json()
        receta_id = j.get('id')
        receta_nombre_out = j.get('nombre', receta_nombre)
        receta_productos = j.get('productos', productos_list)
    except Exception:
        receta_id = None
        receta_nombre_out = receta_nombre
        receta_productos = productos_list

    envelope = ET.Element('{http://schemas.xmlsoap.org/soap/envelope/}Envelope')
    envelope.set('xmlns:soap', 'http://schemas.xmlsoap.org/soap/envelope/')
    body_resp = ET.SubElement(envelope, '{http://schemas.xmlsoap.org/soap/envelope/}Body')
    resp_el = ET.SubElement(body_resp, 'CreateRecetaResponse')
    if receta_id is not None:
        id_el = ET.SubElement(resp_el, 'id')
        id_el.text = str(receta_id)
    name_el = ET.SubElement(resp_el, 'nombre')
    name_el.text = receta_nombre_out
    prods_el = ET.SubElement(resp_el, 'productos')
    for pname in receta_productos:
        pn = ET.SubElement(prods_el, 'nombre')
        pn.text = pname

    return Response(ET.tostring(envelope, encoding='utf-8', xml_declaration=True), mimetype='text/xml')

@app.route("/")
def index():
    return jsonify({"msg": "API Recetas funcionando 🚀"})


@app.route('/health')
def health():
    """Simple health endpoint used by compose and probes."""
    return jsonify({'status': 'ok'}), 200


# Lightweight proxy endpoints so the gateway can expose the microservices' REST APIs
@app.route('/productos/', methods=['GET', 'POST'])
def proxy_productos():
    target = SERVICE_URLS['productos'] + '/productos'
    try:
        if request.method == 'GET':
            resp = call_service('GET', 'productos', '/productos', params=request.args, timeout=5)
        else:
            resp = call_service('POST', 'productos', '/productos', json=request.get_json(silent=True) or {}, timeout=5)
    except requests.RequestException:
        return jsonify({'error': 'productos service unavailable'}), 502
    return Response(resp.content, status=resp.status_code, content_type=resp.headers.get('Content-Type', 'application/json'))


@app.route('/recetas/', methods=['GET', 'POST'])
def proxy_recetas():
    target = SERVICE_URLS['recetas'] + '/recetas'
    try:
        if request.method == 'GET':
            resp = call_service('GET', 'recetas', '/recetas', params=request.args, timeout=5)
        else:
            resp = call_service('POST', 'recetas', '/recetas', json=request.get_json(silent=True) or {}, timeout=10)
    except requests.RequestException:
        return jsonify({'error': 'recetas service unavailable'}), 502
    return Response(resp.content, status=resp.status_code, content_type=resp.headers.get('Content-Type', 'application/json'))


@app.route('/listas/', methods=['GET', 'POST'])
def proxy_listas():
    target = SERVICE_URLS['listas'] + '/listas'
    try:
        if request.method == 'GET':
            resp = call_service('GET', 'listas', '/listas', params=request.args, timeout=5)
        else:
            resp = call_service('POST', 'listas', '/listas', json=request.get_json(silent=True) or {}, timeout=5)
    except requests.RequestException:
        return jsonify({'error': 'listas service unavailable'}), 502
    return Response(resp.content, status=resp.status_code, content_type=resp.headers.get('Content-Type', 'application/json'))

if __name__ == "__main__":
    # Gateway runs without a local DB; start directly
    app.run(host="0.0.0.0", port=8000, debug=True)