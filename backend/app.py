# API del muro de mensajes: listar y publicar, guardando en Firestore.
import os, uuid
from flask import Flask, request, jsonify
from google.cloud import firestore

app = Flask(__name__)
db = firestore.Client(database=os.environ.get("BASE_DATOS", "(default)"))
INSTANCIA = uuid.uuid4().hex[:6]
CATEGORIAS = {"General", "Avisos", "Dudas"}


@app.after_request
def permitir_navegador(respuesta):
    origen_permitido = os.environ.get("ORIGEN_PERMITIDO", "")
    if request.headers.get("Origin") == origen_permitido:
        respuesta.headers["Access-Control-Allow-Origin"] = origen_permitido
        respuesta.headers["Access-Control-Allow-Headers"] = "Content-Type"
        respuesta.headers["Access-Control-Allow-Methods"] = "GET, POST"
    return respuesta


@app.get("/")
def salud():
    return "ok"


@app.get("/mensajes")
def listar():
    categoria = request.args.get("categoria")
    if categoria is not None and categoria not in CATEGORIAS:
        return jsonify(error="categoria no valida"), 400
    consulta = db.collection("mensajes").order_by(
        "creado", direction=firestore.Query.DESCENDING
    )
    mensajes = []
    for documento in consulta.stream():
        datos = documento.to_dict()
        categoria_guardada = datos.get("categoria")
        categoria_mensaje = categoria_guardada if categoria_guardada in CATEGORIAS else "General"
        if categoria is None or categoria_mensaje == categoria:
            mensajes.append({
                "autor": datos.get("autor"),
                "texto": datos.get("texto"),
                "categoria": categoria_mensaje,
            })
        if len(mensajes) == 20:
            break
    return jsonify(instancia=INSTANCIA, mensajes=mensajes)


@app.post("/mensajes")
def crear():
    datos = request.get_json(silent=True) or {}
    autor = str(datos.get("autor", "")).strip()[:40]
    texto = str(datos.get("texto", "")).strip()[:280]
    categoria = str(datos.get("categoria", "")).strip()
    if not autor or not texto:
        return jsonify(error="faltan autor o texto"), 400
    if categoria not in CATEGORIAS:
        return jsonify(error="categoria no valida"), 400
    db.collection("mensajes").add({
        "autor": autor,
        "texto": texto,
        "categoria": categoria,
        "creado": firestore.SERVER_TIMESTAMP,
    })
    return jsonify(ok=True, instancia=INSTANCIA), 201
