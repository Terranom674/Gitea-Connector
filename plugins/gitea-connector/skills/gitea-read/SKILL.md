---
name: gitea-read
description: Read repositories, files, branches, commits, tags, issues, pull requests, reviews, releases, and other permitted project data from the configured Gitea instance.
---

# Gitea Read

Use the bundled Gitea MCP tools for live repository information from the instance selected by `GITEA_URL`.

## Workflow

1. Resolve the repository with `list_repositories` or an explicit owner and repository name from the user.
2. Use the narrowest read tool that answers the request.
3. Preserve stable identifiers, especially owner, repository name, issue number, pull-request number, branch, and commit SHA.
4. State when access is denied or data is absent. Do not infer private repository contents.
5. For broader requests, use `list_available_operations`, then `describe_operation`, then execute only a GET operation.

## Safety

- Never request, display, or return a Gitea access token in conversation.
- Never substitute another Gitea host during a session; the configured instance is fixed by `GITEA_URL` when the MCP process starts.
- Do not use write operations in a read-only task.
