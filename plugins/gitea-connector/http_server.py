#!/usr/bin/env python3
"""Minimal stateless Streamable HTTP transport for the Gitea MCP server."""

import hmac
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Optional

import entrypoint
import server


MAX_REQUEST_SIZE = 2_000_000
MCP_PATH = "/mcp"
HEALTH_PATH = "/health"


def _allowed_origins():
    raw = os.environ.get("MCP_ALLOWED_ORIGINS", "")
    return {value.strip() for value in raw.split(",") if value.strip()}


def _authorized(header: Optional[str]) -> bool:
    expected = os.environ.get("MCP_HTTP_TOKEN", "").strip()
    if not expected:
        return True
    if not header or not header.startswith("Bearer "):
        return False
    return hmac.compare_digest(header[7:], expected)


class MCPHandler(BaseHTTPRequestHandler):
    server_version = "GiteaMCP/1.1"

    def log_message(self, format, *args):
        # Keep normal HTTP access logs on stderr, never on MCP response streams.
        super().log_message(format, *args)

    def _send_json(self, status: int, payload) -> None:
        body = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _origin_allowed(self) -> bool:
        origin = self.headers.get("Origin")
        if not origin:
            return True
        return origin in _allowed_origins()

    def _check_common_security(self) -> bool:
        if not self._origin_allowed():
            self._send_json(403, {"jsonrpc": "2.0", "id": None, "error": {"code": -32000, "message": "Origin is not allowed."}})
            return False
        if not _authorized(self.headers.get("Authorization")):
            self._send_json(401, {"jsonrpc": "2.0", "id": None, "error": {"code": -32001, "message": "Authentication required."}})
            return False
        return True

    def do_GET(self):
        if self.path == HEALTH_PATH:
            self._send_json(200, {"status": "ok"})
            return
        if self.path != MCP_PATH:
            self._send_json(404, {"error": "not found"})
            return
        if not self._check_common_security():
            return

        # This first HTTP implementation is stateless and does not expose an SSE
        # receive stream. Streamable HTTP permits servers to reject GET when they
        # do not offer server-initiated streaming.
        self.send_response(405)
        self.send_header("Allow", "POST")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_DELETE(self):
        if self.path != MCP_PATH:
            self._send_json(404, {"error": "not found"})
            return
        if not self._check_common_security():
            return
        self.send_response(405)
        self.send_header("Allow", "POST")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_POST(self):
        if self.path != MCP_PATH:
            self._send_json(404, {"error": "not found"})
            return
        if not self._check_common_security():
            return

        content_type = self.headers.get("Content-Type", "").split(";", 1)[0].strip().lower()
        if content_type != "application/json":
            self._send_json(415, {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "Content-Type must be application/json."}})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if length <= 0 or length > MAX_REQUEST_SIZE:
            self._send_json(413, {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "Invalid request size."}})
            return

        try:
            message = json.loads(self.rfile.read(length).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            self._send_json(400, {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "Parse error"}})
            return

        if not isinstance(message, dict):
            self._send_json(400, {"jsonrpc": "2.0", "id": None, "error": {"code": -32600, "message": "Invalid Request"}})
            return

        response = server.handle_message(message)
        if response is None:
            self.send_response(202)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return

        self._send_json(200, response)


def main() -> None:
    entrypoint.configure_server()
    host = os.environ.get("MCP_HOST", "127.0.0.1").strip() or "127.0.0.1"
    port = int(os.environ.get("MCP_PORT", "8000"))
    httpd = ThreadingHTTPServer((host, port), MCPHandler)
    print(f"Gitea MCP HTTP server listening on http://{host}:{port}{MCP_PATH}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
