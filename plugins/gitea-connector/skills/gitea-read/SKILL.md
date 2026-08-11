---
name: gitea-read
description: Read repositories, files, branches, commits, tags, issues, pull requests, reviews, releases, and other permitted project data through a separately configured self-hosted Gitea MCP server.
---

# Gitea Read

Use the callable tools exposed by the user's already configured self-hosted Gitea MCP server for live repository information.

The plugin does not start, host, provision, or configure an MCP connection. Do not require a fixed MCP display name. Identify the configured Gitea MCP by its Gitea-related tools and capabilities available in the current ChatGPT session.

## Workflow

1. Before answering a request that depends on Gitea data, use the available Gitea MCP tools rather than conversation history or guesses.
2. Resolve the repository with `list_repositories` or an explicit owner and repository name from the user.
3. Use the narrowest read tool that answers the request.
4. Preserve stable identifiers, especially owner, repository name, issue number, pull-request number, branch, and commit SHA.
5. State when access is denied or data is absent. Do not infer private repository contents.
6. For broader requests, use `list_available_operations`, then `describe_operation`, then execute only a GET operation.

If the Gitea MCP tools are not callable in the current session, tell the user that their separately configured self-hosted Gitea MCP must be enabled in ChatGPT. Do not create or substitute a `.mcp.json`, Codex stdio MCP, GitHub connector, or public web search for private Gitea data.

## Safety

- Never request, display, or return a Gitea access token or MCP bearer token in conversation.
- Do not attempt to change the Gitea server or MCP connection from the plugin.
- Do not use write operations in a read-only task.
