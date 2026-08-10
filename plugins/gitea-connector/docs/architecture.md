# Technical feasibility and minimal architecture

## Feasibility

The connector is technically feasible. Gitea exposes the required data through its `/api/v1` REST API and publishes an instance-specific OpenAPI document at `/swagger.v1.json`. ChatGPT and Codex plugins can package an MCP server whose tools connect to an external system.

The target instance was verified as Gitea 1.24.5, and the version 0.1 routes and query parameters were checked against its live OpenAPI document.

There is no special built-in ChatGPT interface for arbitrary self-hosted Git services. The supported integration boundary is MCP. The plugin packages that MCP connection plus model instructions.

## Minimal deployment

1. The local prototype is a dependency-free Python MCP server using stdio.
2. The service calls only `https://git.bratonien.de/api/v1`.
3. The first release exposes read-only tools from `tool-contracts.md`.
4. Authentication is required because repositories may be private.
5. This bundled stdio form is suitable for local Codex use. A later ChatGPT deployment needs streamable HTTP over public HTTPS or Secure MCP Tunnel during private development.

## Authentication decision

For a single-user local prototype, a Gitea token supplied to the MCP process is the smallest implementation. It must have read-only repository and issue permissions and must never be returned by a tool.

For a distributable or multi-user ChatGPT connector, static shared tokens are unsuitable. The MCP endpoint must implement the MCP OAuth 2.1 authorization contract. Gitea can act as an OAuth2 provider, but an adapter may still be required to satisfy MCP protected-resource metadata, discovery, client registration, PKCE, token audience/resource handling, and per-request authorization.

## Safety boundary

- Allowlist the Gitea origin; never accept an arbitrary base URL from a tool call.
- Require explicit `owner` and `repo` inputs for repository-specific operations.
- Enforce pagination limits server-side.
- Return stable identifiers and web URLs, not raw upstream responses.
- Redact authorization headers, tokens, internal errors, and unnecessary personal data.
- Keep read and write tools separate.
- Add write scopes only when the corresponding write tool is implemented.
- Require confirmation for consequential write operations such as merge, close, delete, or branch changes.

## Write phase 0.2

Version 0.2 adds `create_issue`, `comment_on_issue`, and `create_pull_request`. They use separate write annotations, return compact audit-friendly results, and require explicit confirmation of the exact target and content. Merge, close, branch modification, deletion, admin, sudo, token management, and secret management remain out of scope.
