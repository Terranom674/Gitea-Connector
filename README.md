# Gitea Connector

Open-source MCP connector for self-hosted Gitea instances, intended for use with ChatGPT through a private tunnel or a publicly reachable MCP endpoint.

## Proxmox one-line installation

Run this in the **shell of the Proxmox host**:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Terranom674/Gitea-Connector/main/install/proxmox.sh)"
```

The installer then:

1. asks for the Gitea URL and access token,
2. creates a Docker LXC using the current Proxmox VE Community Scripts Docker helper,
3. installs this repository inside that LXC,
4. builds and starts the Gitea MCP container,
5. creates an MCP HTTP bearer token if none was supplied,
6. prints the resulting LXC information and token.

The MCP remains private at this stage. The next setup step is connecting it to ChatGPT through the OpenAI Secure MCP Tunnel.

## Architecture

```text
ChatGPT
   |
   | Secure MCP Tunnel or public HTTPS
   v
Gitea MCP
   |
   v
Gitea API
```

## Manual Docker installation

The MCP implementation lives in [`plugins/gitea-connector`](plugins/gitea-connector).

Required values:

- `GITEA_URL` — base URL of the Gitea instance
- `GITEA_TOKEN` — Gitea access token
- `MCP_HTTP_TOKEN` — bearer token protecting the MCP endpoint

From the plugin directory:

```bash
cp .env.example .env
# edit .env
docker compose up -d --build
```

The Compose setup binds the MCP only to `127.0.0.1` by default. It is not exposed directly to the internet.

## Current scope

The connector provides tools for repositories, files, commits, branches, tags, issues, pull requests, reviews, merges, releases and a safety-filtered catalog of additional Gitea project operations.

Security-sensitive operations such as password, token, secret, user-administration, permission, runner and webhook management are intentionally excluded.

The original implementation was verified against Gitea 1.24.5. Compatibility with additional Gitea versions will be expanded and documented as the public version develops.
