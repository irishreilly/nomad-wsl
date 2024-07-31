#!/usr/bin/env python3

"""
Simple Python HTTP microservice with a JSON greeting. 

Use a framework like Flask or FastAPI for production.

CORS and TLS can also be added for security purposes.
"""

import http.server
import json

class MyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {"message": "Hello!"}
        self.wfile.write(json.dumps(response).encode())

if __name__ == '__main__':
    server_address = ('', 8080)
    httpd = http.server.HTTPServer(server_address, MyHandler)
    print('HTTP server listening on %s:%d' % server_address)
    httpd.serve_forever()

