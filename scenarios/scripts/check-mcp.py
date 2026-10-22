#!/usr/bin/env python3
"""Exercise MCP discovery and routing through the gateway (standard library only)."""
import argparse
import json
import secrets
import sys
import time
import urllib.error
import urllib.request


class CheckFailure(Exception):
    """A response did not satisfy the MCP routing check."""


def require(condition, message):
    if not condition:
        raise CheckFailure(message)


def compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


class Client:
    def __init__(self, url):
        self.url, self.session, self.next_id = url, None, 0
        self.http_status, self.elapsed_ms = None, 0
        self.requests_sent = 0
        self.matched_tools = 0

    def transport(self):
        return f"HTTP {self.http_status}, {self.elapsed_ms:.0f} ms"

    def send(self, method, params=None, notification=False):
        self.next_id += 1
        message = {"jsonrpc": "2.0", "method": method}
        if not notification:
            message["id"] = self.next_id
        if params is not None:
            message["params"] = params
        headers = {"Content-Type": "application/json", "Accept": "application/json, text/event-stream",
                   "MCP-Protocol-Version": "2025-06-18"}
        if self.session:
            headers["Mcp-Session-Id"] = self.session
        request = urllib.request.Request(self.url, json.dumps(message).encode(), headers)
        # Local lab addresses should not pass through workstation HTTP proxies.
        started = time.monotonic()
        self.requests_sent += 1
        try:
            response = urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request, timeout=30)
        except urllib.error.HTTPError as error:
            self.http_status = error.code
            self.elapsed_ms = (time.monotonic() - started) * 1000
            raise
        with response:
            self.http_status = response.status
            self.session = response.headers.get("Mcp-Session-Id", self.session)
            body = response.read().decode()
            self.elapsed_ms = (time.monotonic() - started) * 1000
            if notification:
                require(response.status in (200, 202, 204), f"Notification returned HTTP {response.status}")
                return
            if response.headers.get("Content-Type", "").startswith("text/event-stream"):
                candidates = [json.loads(line[5:].strip()) for line in body.splitlines() if line.startswith("data:")]
                result = next((item for item in candidates if item.get("id") == message["id"]), {})
            else:
                result = json.loads(body)
            require(result.get("id") == message["id"], f"Response ID mismatch: {compact(result)}")
            return result

    def initialize(self):
        reply = self.send("initialize", {"protocolVersion": "2025-06-18", "capabilities": {},
                                         "clientInfo": {"name": "routing-check", "version": "1.0"}})
        require("result" in reply, f"Initialization failed: {compact(reply)}")
        info = reply["result"]
        server = info.get("serverInfo", {})
        print(f"  Connected     {server.get('name', '?')} {server.get('version', '')} ({self.transport()})")
        print(f"  Protocol      {info.get('protocolVersion', '?')}; session: {'issued' if self.session else 'stateless'}")
        require("tools" in info.get("capabilities", {}), "Server did not advertise the tools capability")
        self.send("notifications/initialized", notification=True)
        print(f"  Initialized   notification accepted ({self.transport()})")

    def check(self, expected):
        self.initialize()
        reply = self.send("tools/list")
        require("result" in reply, f"Tool discovery failed: {compact(reply)}")
        tools = reply["result"]["tools"]
        print(f"  Discovered    {len(tools)} tool(s) ({self.transport()})")
        for tool in tools:
            print(f"                {tool['name']} - {tool.get('description', '')}")
        require({tool["name"] for tool in tools} == set(expected),
                f"Expected tools {sorted(expected)}, received {sorted(tool['name'] for tool in tools)}")
        for name, (arguments, text) in expected.items():
            print(f"\n  Call          {name}({compact(arguments)})")
            reply = self.send("tools/call", {"name": name, "arguments": arguments})
            require("result" in reply, f"Tool call failed: {compact(reply)}")
            result = reply["result"]
            print(f"  Received      {compact(result)} ({self.transport()})")
            print(f"  Expected      {compact(text)}")
            require(not result.get("isError"), f"Tool reported an error: {compact(result)}")
            actual = [item.get("text") for item in result.get("content", []) if item.get("type") == "text"]
            require(actual == [text], f"Expected text {[text]!r}, received {actual!r}")
            self.matched_tools += 1
            print("  MATCH         actual result equals expected result")
        print("\n  Negative test tools/call unknown__missing({})")
        try:
            invalid = self.send("tools/call", {"name": "unknown__missing", "arguments": {}})
            print(f"  Received      {compact(invalid)} ({self.transport()})")
            require("error" in invalid or invalid.get("result", {}).get("isError"),
                    "Unknown tool unexpectedly succeeded")
        except urllib.error.HTTPError as error:
            # The aggregator can reject an unknown backend before a JSON-RPC response.
            detail = " ".join(error.read().decode(errors="replace").split())
            print(f"  Received      {detail[:500] or '(empty body)'} ({self.transport()})")
            require(error.code in (400, 404, 422), f"Unexpected rejection status: HTTP {error.code}")
        print("  REJECTED      unknown tool did not execute")
        print("\n  PASS          discovery, tool results and rejection verified")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--echo-url", default="http://mcp-echo-127-0-0-1.nip.io:8080/mcp")
    parser.add_argument("--math-url", default="http://mcp-math-127-0-0-1.nip.io:8080/mcp")
    parser.add_argument("--dynamic-url", default="http://mcp-127-0-0-1.nip.io:8080/mcp")
    parser.add_argument("--static-only", action="store_true")
    args = parser.parse_args()
    run_id = secrets.token_hex(3)
    echo_text = f"Hello MCP [run {run_id}]"
    a, b = secrets.randbelow(90) + 10, secrets.randbelow(90) + 10
    echo = ({"text": echo_text}, echo_text)
    add = ({"a": a, "b": b}, str(a + b))
    endpoints = [("Static routing / echo", args.echo_url, {"echo": echo}),
                 ("Static routing / math", args.math_url, {"add": add})]
    if not args.static_only:
        endpoints.append(("Dynamic routing / aggregated tools", args.dynamic_url,
                          {"echo__echo": echo, "math__add": add}))
    print("MCP ROUTING VERIFICATION")
    print("=" * 72)
    print(f"Run {run_id} | Streamable HTTP | fresh echo marker and arithmetic inputs")
    started = time.monotonic()
    passed, tool_calls, requests_sent = 0, 0, 0
    for index, (label, url, expected) in enumerate(endpoints, 1):
        print(f"\n[{index}/{len(endpoints)}] {label}\n{url}\n" + "-" * 72)
        client = Client(url)
        try:
            client.check(expected)
            passed += 1
        except (CheckFailure, urllib.error.URLError, TimeoutError, OSError, ValueError, KeyError, TypeError) as error:
            print(f"\n  FAIL          {error}")
        requests_sent += client.requests_sent
        tool_calls += client.matched_tools
    print("\n" + "=" * 72)
    print(f"RESULT: {passed}/{len(endpoints)} endpoints verified | {tool_calls} tool results matched")
    print(f"        {requests_sent} HTTP requests | {time.monotonic() - started:.2f} s elapsed")
    if passed == len(endpoints):
        print("Verified: each endpoint returned its expected tool catalog and results.")
        if not args.static_only:
            print("The aggregated endpoint returned the same echo and sum as the static endpoints.")
        return 0
    print("One or more endpoints failed. Check the FAIL details above.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
