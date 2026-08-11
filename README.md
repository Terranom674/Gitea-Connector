# Gitea Connector

Open-source MCP connector for self-hosted Gitea instances, intended for use with ChatGPT through OpenAI Secure MCP Tunnel or a publicly reachable MCP endpoint.

## Before you start

For the full Proxmox installation, have these values ready:

- a Gitea base URL, for example `git.example.com`
- a Gitea access token
- an OpenAI Secure MCP Tunnel ID
- an OpenAI Tunnel Runtime API key

The installer does **not** create the OpenAI tunnel credentials for you. Create the Secure MCP Tunnel and its runtime credentials in the OpenAI Platform before starting the installation, then keep the tunnel ID and runtime API key ready for section 4 of the installer.

OpenAI documents Secure MCP Tunnel as the supported way to connect a private/on-premises MCP server to supported OpenAI products without exposing that MCP server directly to the public internet.

### OpenAI Secure MCP Tunnel preparation

Before running the installer:

1. Sign in to the OpenAI Platform with the organization that will own the tunnel.
2. Create or select a Secure MCP Tunnel in the Platform's tunnel management area.
3. Copy the resulting tunnel ID. It begins with `tunnel_`.
4. Create a runtime API key intended for that tunnel/client and give it the required tunnel permissions for runtime use.
5. Store the runtime API key securely. Do not commit it to Git or paste it into public logs.
6. Keep both values ready. The Proxmox installer will ask for them in the `OpenAI Secure MCP Tunnel` section.

The installer stores the runtime key inside the created LXC in a root-only environment file for the `tunnel-client` systemd service.

## Proxmox one-line installation

Run this in the **shell of the Proxmox host**:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Terranom674/Gitea-Connector/main/install/proxmox.sh)
```

The installer then:

1. lets you select German or English,
2. shows the required credentials before configuration starts,
3. asks for an individual LXC name and the Proxmox resource/network settings,
4. asks for the Gitea URL and access token,
5. asks for the OpenAI Secure MCP Tunnel ID and runtime API key,
6. creates a dedicated unprivileged Debian LXC,
7. installs Docker and this repository inside the LXC,
8. builds and starts the Gitea MCP container,
9. installs the official OpenAI `tunnel-client`,
10. configures it as an automatically starting systemd service,
11. checks both the MCP health endpoint and the tunnel readiness endpoint.

Invalid **user input** does not terminate the installer. The relevant question is repeated until a valid value is entered. After the final confirmation, genuine technical failures during LXC creation, package installation, Docker startup, MCP startup, or tunnel startup stop the installation so that a broken partial setup is not silently continued.

## Architecture

```text
ChatGPT
   |
   | OpenAI Secure MCP Tunnel
   v
OpenAI tunnel-client
   |
   v
Gitea MCP (local inside LXC)
   |
   v
Gitea API
```

The MCP is bound locally inside the LXC and does not need to be exposed directly to the public internet when Secure MCP Tunnel is used.

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
