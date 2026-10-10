import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

BACKEND = os.environ.get("BACKEND_URL", "http://localhost:8081")

with open("index.html", encoding="utf-8") as archivo:
    PAGINA = archivo.read().replace("__BACKEND_URL__", BACKEND).encode()


class Frontend(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(PAGINA)))
        self.end_headers()
        self.wfile.write(PAGINA)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("", int(os.environ.get("PORT", 8080))), Frontend).serve_forever()
