# Gitea Connector

Controlled read and write connector for `https://git.bratonien.de`.

## Status

Version 1.0 uses Python's standard library and needs no package installation. It supports direct repository tools plus 221 safety-filtered Gitea project operations. The plugin forwards `GITEA_TOKEN` from the local Codex environment to the MCP process. Never store the token in this plugin directory or commit it to source control.

## Architecture

```text
ChatGPT / Codex
    -> Gitea Connector plugin
        -> bundled workflow skill
        -> bundled MCP server over stdio
            -> HTTPS Gitea API /api/v1
                -> git.bratonien.de
```

The MCP server is the security boundary. It validates all inputs, holds or receives credentials, calls only allowlisted Gitea API routes, removes secrets from results, and returns stable structured data.

## Version 1.0 scope

- Read repositories, files, branches, commits, issues, pull requests, reviews, tags, releases, packages, Actions data, and other project information.
- Create, update, move, and delete text files, including up to 50 file operations in one commit.
- Create and delete branches and tags.
- Create, update, comment on, close, review, merge, and delete supported project objects.
- Create, update, and delete releases.
- Require confirmation for writes, merges, branch changes, and deletions.
- Exclude passwords, tokens, secrets, keys, user administration, permissions, runners, and webhooks.
- Redact sensitive user and credential metadata from generic operation results.

## Live verification

Version 1.0 was exercised against `Thomas/LANELA` with temporary branches, multi-file commits, an issue lifecycle, a pull request with comment and review, a squash merge, a tag, and a release. Temporary resources were removed afterward and `main` remained unchanged.

See [docs/architecture.md](docs/architecture.md) and [docs/tool-contracts.md](docs/tool-contracts.md).

## Local verification

```bash
python3 -m unittest discover -s tests -v
```
