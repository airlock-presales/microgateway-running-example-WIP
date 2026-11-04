"""Small stateless Streamable HTTP MCP lab server; no third-party dependencies.

Only implements the tools capability used by this example, without SSE streams,
server-initiated requests, authentication, or persistent sessions.
"""
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SERVER = os.environ.get("MCP_SERVER", "echo")
TOOLS = {
    "echo": {"name": "echo", "description": "Return the supplied text.",
             "inputSchema": {"type": "object", "properties": {"text": {"type": "string"}},
                             "required": ["text"], "additionalProperties": False}},
    "math": {"name": "add", "description": "Add two numbers.",
             "inputSchema": {"type": "object", "properties": {
                 "a": {"type": "number"}, "b": {"type": "number"}},
                 "required": ["a", "b"], "additionalProperties": False}},
}
TOOL = TOOLS[SERVER]


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def reply(self, status, body=None):
        data = json.dumps(body).encode() if body is not None else b""
        self.send_response(status)
        if body is not None:
            self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        # Stateless mode: no standalone SSE stream.
        self.reply(200 if self.path == "/healthz" else 405)

    def do_DELETE(self):
        self.reply(405)

    def do_POST(self):
        if self.path != "/mcp":
            self.close_connection = True
            return self.reply(404)
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= 65536:
                self.close_connection = True
                return self.reply(413)
            message = json.loads(self.rfile.read(length))
            if not isinstance(message, dict) or message.get("jsonrpc") != "2.0":
                raise ValueError("Expected a JSON-RPC 2.0 object")
        except (ValueError, UnicodeDecodeError):
            return self.reply(400, {"jsonrpc": "2.0", "id": None,
                                    "error": {"code": -32700, "message": "Invalid JSON-RPC"}})
        method = message.get("method", "")
        if "id" not in message:
            return self.reply(202)
        response = {"jsonrpc": "2.0", "id": message["id"]}
        params = message.get("params", {})
        if not isinstance(params, dict):
            response["error"] = {"code": -32602, "message": "Invalid params"}
        elif method == "initialize":
            requested = params.get("protocolVersion")
            response["result"] = {
                "protocolVersion": requested if requested in ("2025-03-26", "2025-06-18", "2025-11-25") else "2025-06-18",
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": "demo-" + SERVER, "version": "1.0.0"}}
        elif method == "ping":
            response["result"] = {}
        elif method == "tools/list":
            response["result"] = {"tools": [TOOL]}
        elif method == "tools/call":
            args = params.get("arguments", {})
            try:
                if params.get("name") != TOOL["name"] or not isinstance(args, dict):
                    raise ValueError("Unknown tool or invalid arguments")
                if SERVER == "echo":
                    if set(args) != {"text"} or not isinstance(args["text"], str):
                        raise ValueError("text must be a string")
                    result = args["text"]
                else:
                    if set(args) != {"a", "b"} or any(type(args[k]) not in (int, float) for k in ("a", "b")):
                        raise ValueError("a and b must be numbers")
                    result = str(args["a"] + args["b"])
                response["result"] = {"content": [{"type": "text", "text": result}], "isError": False}
            except ValueError as error:
                response["result"] = {"content": [{"type": "text", "text": str(error)}], "isError": True}
        else:
            response["error"] = {"code": -32601, "message": "Method not found"}
        self.reply(200, response)


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", int(os.environ.get("PORT", "8000"))), Handler).serve_forever()
