#!/usr/bin/env python3
"""Configurable entry point for the bundled Gitea MCP server.

This keeps the tested server implementation intact while allowing users to
connect the plugin to their own Gitea instance through environment variables.
"""

import os
from urllib.parse import urlparse

import server


def configured_origin() -> str:
    raw = os.environ.get("GITEA_URL", "").strip().rstrip("/")
    if not raw:
        raise SystemExit("GITEA_URL is required, for example https://git.example.com")

    parsed = urlparse(raw)
    if parsed.scheme not in {"http", "https"} or not parsed.netloc:
        raise SystemExit("GITEA_URL must be an absolute http(s) URL")
    if parsed.username or parsed.password:
        raise SystemExit("Do not put credentials into GITEA_URL")
    if parsed.query or parsed.fragment:
        raise SystemExit("GITEA_URL must not contain a query string or fragment")

    return raw


def main() -> None:
    origin = configured_origin()

    server.SERVER_NAME = "gitea-connector"
    server.SERVER_VERSION = "1.1.0"
    server.GITEA_ORIGIN = origin
    server.API_BASE = origin + "/api/v1"

    # Tool descriptions are metadata only, but replacing the old instance name
    # avoids leaking the original Bratonien deployment into public installs.
    for tool in server.TOOLS:
        description = tool.get("description")
        if isinstance(description, str):
            tool["description"] = description.replace("git.bratonien.de", urlparse(origin).netloc)

    original_handle_message = server.handle_message

    def handle_message(message):
        response = original_handle_message(message)
        if isinstance(response, dict):
            result = response.get("result")
            if isinstance(result, dict) and "instructions" in result:
                result["instructions"] = (
                    "Access the configured Gitea instance through dedicated tools and a strict "
                    "catalog of non-security-sensitive operations. Never request or expose passwords, "
                    "tokens, secrets, keys, or user administration. Use describe_operation before "
                    "execute_operation. Before POST, PUT, PATCH, or DELETE, show the exact target and "
                    "complete change and obtain explicit confirmation. Destructive actions and merges "
                    "always require explicit confirmation. Do not retry ambiguous writes."
                )
        return response

    server.handle_message = handle_message
    server.main()


if __name__ == "__main__":
    main()
