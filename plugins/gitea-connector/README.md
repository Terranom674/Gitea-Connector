# Gitea Connector

A self-hostable Codex and ChatGPT connector for Gitea.

The plugin connects to a Gitea instance chosen by the user. The instance URL and access token are supplied through environment variables; no Gitea host or credentials are stored in the repository.

## Requirements

- Python 3
- A reachable Gitea instance
- A Gitea access token with only the permissions you actually want the connector to use

No additional Python packages are required.

## Configuration

Set these environment variables before starting the connector:

```bash
export GITEA_URL="https://git.example.com"
export GITEA_TOKEN="your-token"
```

`GITEA_URL` must be the base URL of the Gitea instance without `/api/v1`. Credentials must never be placed in the URL.

The plugin forwards both variables to the MCP process. Never store the token in this plugin directory or commit it to source control.

## Two MCP transports

### Local stdio transport

Codex can continue to start the connector locally through the bundled `.mcp.json`:

```bash
python3 entrypoint.py
```

### Streamable HTTP transport

For Docker, remote MCP use, and later ChatGPT integration, start the independent HTTP process:

```bash
export MCP_HTTP_TOKEN="choose-a-long-random-value"
python3 http_server.py
```

Defaults:

- MCP endpoint: `http://127.0.0.1:8000/mcp`
- Health endpoint: `http://127.0.0.1:8000/health`
- Bind address: `127.0.0.1`
- Port: `8000`

Override the bind address or port with `MCP_HOST` and `MCP_PORT`. A Docker container will later set `MCP_HOST=0.0.0.0` inside the container and publish only the desired host port.

`MCP_HTTP_TOKEN` enables Bearer authentication for the MCP endpoint. If it is empty, the endpoint is intentionally unauthenticated and should only be used for trusted local development.

If a client sends an HTTP `Origin` header, that origin must be listed in the comma-separated `MCP_ALLOWED_ORIGINS` environment variable. Requests without an `Origin` header are unaffected.

The HTTP implementation is currently stateless: JSON-RPC messages are sent with HTTP POST to `/mcp`. It does not yet expose a long-lived SSE receive stream, so GET on `/mcp` returns `405 Method Not Allowed`.

## Architecture

```text
Codex -- stdio --------------------┐
                                   v
                            Gitea MCP core -> Gitea API
                                   ^
ChatGPT / remote client -- HTTP ---┘
```

The MCP server is the security boundary. It validates inputs, calls only allowlisted Gitea API routes, removes secrets from results, and returns stable structured data.

## Scope

- Read repositories, files, branches, commits, issues, pull requests, reviews, tags, releases, packages, Actions data, and other project information.
- Create, update, move, and delete text files, including up to 50 file operations in one commit.
- Create and delete branches and tags.
- Create, update, comment on, close, review, merge, and delete supported project objects.
- Create, update, and delete releases.
- Require confirmation for writes, merges, branch changes, and deletions.
- Exclude passwords, tokens, secrets, keys, user administration, permissions, runners, and webhooks.
- Redact sensitive user and credential metadata from generic operation results.

The current operation catalog contains 221 safety-filtered Gitea project operations inherited from the tested original implementation.

## Compatibility note

The original implementation was tested against Gitea 1.24.5. Other Gitea versions may expose slightly different API operations. The connector should therefore be tested against the target instance before relying on write operations in production.

## Local verification

```bash
python3 -m unittest discover -s tests -v
```

See [docs/architecture.md](docs/architecture.md) and [docs/tool-contracts.md](docs/tool-contracts.md).
