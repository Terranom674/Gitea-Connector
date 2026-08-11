# Gitea Connector

A ChatGPT plugin for working with a self-hosted Gitea instance through a separately configured custom Gitea MCP server.

## Architecture

The plugin provides workflow instructions and presentation. It does not start, host, proxy, or provision the MCP server itself.

```text
ChatGPT plugin / skills
      |
      v
callable custom Gitea MCP tools
      |
      v
public HTTPS MCP endpoint
      |
      v
reverse proxy / user's infrastructure
      |
      v
self-hosted Gitea MCP
      |
      v
self-hosted Gitea instance
```

The Gitea instance, MCP server, reverse proxy, domain, TLS certificate and credentials remain under the user's control. The plugin itself does not host Gitea, proxy traffic, store credentials or require the OpenAI model API.

## Requirements

Before using the plugin, the user must have:

- a self-hosted Gitea instance,
- a running Gitea MCP server from this repository,
- an HTTPS endpoint reachable by ChatGPT, for example `https://mcp.example.com/mcp`,
- Bearer authentication configured for that endpoint,
- the MCP server added and enabled in ChatGPT as a custom Streamable HTTP MCP server.

A typical reverse-proxy setup is:

```text
https://mcp.example.com/mcp
        -> reverse proxy
        -> http://MCP-SERVER:8000/mcp
```

## ChatGPT MCP configuration

Create a custom MCP server in ChatGPT with:

- Type: `Streamable HTTP`
- URL: `https://mcp.example.com/mcp`
- Header name: `Authorization`
- Header value: `Bearer YOUR_MCP_HTTP_TOKEN`

Do not enter the token itself in the field labelled `Bearer token environment variable`. That field expects the name of an environment variable. For the tested self-hosted setup, the explicit `Authorization` header is used instead.

A successful MCP handshake produces POST requests to `/mcp` with HTTP `200` and `202` responses.

## Plugin and MCP separation

This plugin intentionally contains no `.app.json` workspace binding and no bundled `.mcp.json` connection definition.

That is deliberate for the self-hosted model: every user can run their own MCP server at their own domain with their own credentials, while the same plugin supplies the Gitea workflows. The plugin's Gitea skill uses an already configured custom Gitea MCP when its tools are callable in the current ChatGPT session.

The plugin must not assume a fixed MCP display name or a Bratonien-specific hostname.

## Server configuration

The MCP server itself uses:

```bash
GITEA_URL="https://git.example.com"
GITEA_TOKEN="your-gitea-token"
MCP_HTTP_TOKEN="choose-a-long-random-value"
```

`GITEA_URL` is the base URL without `/api/v1`. The Gitea token should have only the permissions needed for the desired operations.

The HTTP server exposes:

- MCP endpoint: `/mcp`
- Health endpoint: `/health`

`MCP_HTTP_TOKEN` protects `/mcp` with Bearer authentication. The health endpoint intentionally remains available for service checks.

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

The original implementation was tested against Gitea 1.24.5. Other Gitea versions may expose slightly different API operations. Test the connector against the target instance before relying on write operations in production.

## Local verification

```bash
python3 -m unittest discover -s tests -v
```

See [docs/architecture.md](docs/architecture.md) and [docs/tool-contracts.md](docs/tool-contracts.md).
