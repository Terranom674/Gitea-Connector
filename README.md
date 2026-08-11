# Gitea Connector

Open-source connector that lets Codex and, later, ChatGPT work with a self-hosted Gitea instance through MCP.

The project is based on a connector originally built and tested against a private Gitea installation. It is being generalized so that each user can connect their own Gitea server without sending repository credentials through a centrally hosted service.

## Current status

The project now supports two MCP transports:

- **stdio** for local Codex use
- **Streamable HTTP foundation** for Docker, remote MCP use, and later ChatGPT integration

Users provide their own:

- Gitea base URL (`GITEA_URL`)
- Gitea access token (`GITEA_TOKEN`)

The connector does not contain a fixed Gitea host and does not store access tokens in the repository.

## Repository layout

The plugin lives in [`plugins/gitea-connector`](plugins/gitea-connector).

It currently provides tools for repositories, files, commits, branches, tags, issues, pull requests, reviews, merges, releases and a safety-filtered catalog of additional Gitea project operations.

Security-sensitive operations such as password, token, secret, user-administration, permission, runner and webhook management are intentionally excluded.

## Local stdio start

```bash
export GITEA_URL="https://git.example.com"
export GITEA_TOKEN="your-token"
cd plugins/gitea-connector
python3 entrypoint.py
```

Normally Codex starts the MCP process through the bundled `.mcp.json`.

## HTTP MCP start

```bash
export GITEA_URL="https://git.example.com"
export GITEA_TOKEN="your-token"
export MCP_HTTP_TOKEN="choose-a-long-random-value"
cd plugins/gitea-connector
python3 http_server.py
```

The default MCP endpoint is `http://127.0.0.1:8000/mcp`. This is the transport that the planned Docker self-hosting setup will expose safely through HTTPS.

See [`plugins/gitea-connector/README.md`](plugins/gitea-connector/README.md) for configuration, architecture and verification details.

## Development

Run the test suite from the plugin directory:

```bash
python3 -m unittest discover -s tests -v
```

The original implementation was verified against Gitea 1.24.5. Compatibility with additional Gitea versions will be expanded and documented as the public version develops.
