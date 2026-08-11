# Architecture

## Goal

The plugin provides reusable Gitea workflows for ChatGPT while keeping the user's Gitea instance, MCP server, endpoint, and credentials under the user's control.

The plugin must not depend on a specific hostname, repository owner, deployment, or MCP display name.

## ChatGPT deployment model

The Gitea MCP server is configured separately in ChatGPT as a custom Streamable HTTP MCP server. The plugin does not create, start, host, proxy, or provision that connection.

```text
ChatGPT
  -> Gitea Connector plugin
    -> bundled workflow skills
      -> already configured callable Gitea MCP tools
        -> Streamable HTTP MCP endpoint
          -> self-hosted Gitea MCP
            -> self-hosted Gitea /api/v1
```

The plugin contains no `.mcp.json` and no workspace-specific `.app.json` binding. This is deliberate: the same plugin can be used with independently operated Gitea MCP servers, while the connection itself remains configured and authenticated separately in ChatGPT.

## Connection boundary

The plugin must use only Gitea-related MCP tools that are already callable in the current ChatGPT session.

It must not:

- invent or provision another MCP connection,
- require a fixed MCP display name,
- create a Codex stdio MCP configuration,
- fall back to GitHub for private Gitea data,
- ask the model to handle Gitea or MCP credentials directly.

If no suitable Gitea MCP tools are callable, the plugin should report that the separately configured self-hosted Gitea MCP must be enabled in ChatGPT.

## MCP server boundary

The self-hosted MCP server is responsible for the actual Gitea API connection and authentication. A typical deployment exposes a Streamable HTTP endpoint over HTTPS, directly or through the operator's own reverse proxy or secure tunnel.

The MCP implementation in this repository uses the configured Gitea base URL and access token on the server side. Those credentials are not plugin inputs and must not be returned through MCP tools.

## Safety boundary

- Repository-specific operations require explicit owner and repository inputs where the MCP tool requires them.
- Pagination and upstream API validation are enforced by the MCP server.
- Authorization headers, tokens, internal errors, and unnecessary personal data are redacted by the MCP implementation.
- Read, write, and destructive operations remain distinct.
- Passwords, token management, secrets, keys, user administration, permissions, runners, and webhooks remain excluded.
- Consequential writes such as merges, deletions, and branch changes require explicit confirmation when no product-level confirmation is already provided.
- Ambiguous writes must not be retried automatically.

## Compatibility

The original operation catalog was verified against Gitea 1.24.5. Gitea API surfaces can vary between releases, so operators should validate the self-hosted MCP against their target Gitea version before relying on consequential write workflows.

## Separation from Codex stdio support

The repository may contain MCP server implementation files useful for self-hosting and development, but the ChatGPT plugin does not bind or launch them through Codex stdio. For this plugin workflow, the source of truth is the separately configured Streamable HTTP MCP connection already present in ChatGPT.
