---
name: gitea-selfhosted
description: Use a separately configured self-hosted Gitea MCP server for repository, issue, pull request, release, branch, tag, commit, and file workflows.
---

# Self-hosted Gitea

Use this skill when the user wants to work with a Gitea instance through their own configured MCP server.

## Source access

The plugin does not declare or provision a workspace app binding. Treat an already configured custom Gitea MCP server as the source of truth when its tools are callable in the current ChatGPT session.

Before answering a request that depends on Gitea data, use the available Gitea MCP tools rather than guessing from conversation history. If the custom MCP tools are not callable in the current session, tell the user that the self-hosted Gitea MCP connection must be enabled/configured in ChatGPT; do not substitute GitHub or a public web search for private Gitea data.

Do not require a fixed MCP display name. Identify the configured MCP by its Gitea-related tools and capabilities.

## Operation rules

- Prefer direct purpose-built tools for repositories, files, commits, branches, tags, issues, pull requests, reviews, merges, and releases.
- Use read operations without changing external state.
- Ask for confirmation before writes, merges, branch/tag deletion, file deletion, release deletion, or other destructive changes when the tool does not already provide a product confirmation step.
- Never request, expose, read back, or manipulate passwords, access tokens, secrets, private keys, runner credentials, or webhook secrets.
- Do not perform user administration, permission administration, runner administration, or webhook administration.
- Preserve repository owner/name, branch, issue/PR numbers, commit SHAs, and paths exactly as returned by the MCP.
- If Gitea returns an error or an operation is unavailable on the target Gitea version, report that limitation instead of inventing a result.

## Common workflows

For repository overview requests, list repositories first and then fetch details only for the repositories needed to answer the question.

For code/file questions, fetch the relevant file or commit content before making claims about implementation.

For issue and pull-request summaries, retrieve the current open items and summarize status, blockers, review state, and next actions from the returned data.

For requested changes, inspect the current target state first, make the smallest requested change, and report the resulting branch/commit/object identifier returned by Gitea.
