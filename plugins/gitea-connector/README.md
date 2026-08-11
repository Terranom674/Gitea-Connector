# Gitea Connector

A self-hostable Codex connector for Gitea.

The plugin connects Codex to a Gitea instance chosen by the user. The instance URL and access token are supplied through environment variables; no Gitea host or credentials are stored in the repository.

## Requirements

- Python 3
- A reachable Gitea instance
- A Gitea access token with only the permissions you actually want the connector to use

No additional Python packages are required.

## Configuration

Set these environment variables before starting Codex:

```bash
export GITEA_URL="https://git.example.com"
export GITEA_TOKEN="your-token"
```

`GITEA_URL` must be the base URL of the Gitea instance without `/api/v1`. Credentials must never be placed in the URL.

The plugin forwards both variables to the bundled MCP process. Never store the token in this plugin directory or commit it to source control.

## Architecture

```text
Codex
    -> Gitea Connector plugin
        -> bundled workflow skill
        -> bundled MCP server over stdio
            -> HTTPS Gitea API /api/v1
                -> user-configured Gitea instance
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

The current operation catalog contains 221 safety-filtered Gitea project operations inherited from the tested Bratonien implementation.

## Compatibility note

The original implementation was tested against Gitea 1.24.5. Other Gitea versions may expose slightly different API operations. The connector should therefore be tested against the target instance before relying on write operations in production.

## Local verification

```bash
python3 -m unittest discover -s tests -v
```

A minimal MCP startup test can also be run by setting `GITEA_URL` and `GITEA_TOKEN` and launching:

```bash
python3 entrypoint.py
```

The process then communicates over MCP stdio.

See [docs/architecture.md](docs/architecture.md) and [docs/tool-contracts.md](docs/tool-contracts.md).
