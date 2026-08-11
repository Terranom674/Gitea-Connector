# Architecture

## Goal

The connector is a reusable bridge between Codex and a self-hosted Gitea instance. It must not depend on a specific hostname, repository owner, or deployment.

Gitea exposes the required project data through its `/api/v1` REST API and normally publishes an instance-specific OpenAPI document at `/swagger.v1.json`.

## Current deployment model

The current plugin bundles a dependency-free Python MCP server that communicates with Codex over stdio.

```text
Codex
  -> plugin
    -> entrypoint.py
      -> server.py
        -> configured Gitea /api/v1
```

The target instance is selected at runtime with `GITEA_URL`. Authentication is supplied separately with `GITEA_TOKEN`.

This keeps one published plugin usable with many independent Gitea installations without routing credentials or repository traffic through infrastructure operated by the plugin author.

## Configuration boundary

`GITEA_URL` is configuration, not a tool argument. The model cannot redirect an individual request to another host. The entry point validates that it is an absolute HTTP(S) URL and rejects embedded credentials, query strings, and fragments.

`GITEA_TOKEN` is forwarded only as process environment and must never be returned by a tool or committed to the repository.

For internet-facing deployments, HTTPS should be used. Plain HTTP is only appropriate where the operator deliberately accepts that risk, for example inside a trusted local network.

## Safety boundary

- The Gitea origin is fixed for the lifetime of the MCP process.
- Repository-specific operations require explicit `owner` and `repo` inputs.
- Pagination limits are enforced server-side.
- Authorization headers, tokens, internal errors, and unnecessary personal data are redacted.
- Read, write, and destructive operations carry separate MCP annotations.
- Passwords, token management, secrets, keys, user administration, permissions, runners, and webhooks remain excluded.
- Consequential writes such as merges, deletions, and branch changes require explicit user confirmation.
- Ambiguous writes must not be retried automatically.

## Compatibility

The original implementation and operation catalog were verified against Gitea 1.24.5. Because Gitea API surfaces can vary between releases, operators should validate the connector against their own Gitea version before enabling consequential write workflows.

## Future remote-MCP deployment

The bundled stdio server is appropriate for Codex and self-hosted use. A later hosted or remotely reachable edition should expose streamable HTTP over HTTPS and implement the applicable MCP authorization flow. That remote service should remain optional; self-hosting is the baseline distribution model so users do not need to send Gitea credentials through infrastructure run by the plugin author.
