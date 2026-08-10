---
name: gitea-write
description: Perform explicit, confirmed Gitea project writes through dedicated tools or the safety-filtered operations catalog on git.bratonien.de.
---

# Gitea Write

Use the bundled Gitea MCP write tools only for explicit user-requested writes.

## Required workflow

1. Resolve and read the exact repository and target first.
2. For catalog operations, call `describe_operation` before execution.
3. Prepare the complete final change.
4. Show the exact repository, target, operation, and content to the user and obtain confirmation.
5. Perform exactly one write call after confirmation.
6. Report the returned stable identifier and URL when provided.

## Safety

- Never request, display, or return a Gitea access token.
- Never infer a repository, branch, issue number, pull-request number, title, or body for a write.
- Immediately before updating or deleting a file, call `get_file` and use its current SHA.
- Before a multi-file commit, read every file that will be updated or deleted and use its current SHA.
- Before merging a pull request, read the pull request and bind the confirmed merge to its current head commit SHA.
- Creating files is allowed only at a confirmed new path; deleting files requires explicit confirmation of that exact path.
- Merges, closing, branch changes, and deletions are allowed only after explicit confirmation.
- Never manage passwords, tokens, secrets, keys, users, permissions, runners, webhooks, or administrator functions.
- Do not retry a write automatically after an ambiguous timeout or transport failure.
