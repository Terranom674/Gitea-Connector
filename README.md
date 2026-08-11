# Gitea Connector

Open-source MCP connector for self-hosted Gitea instances, intended for use with ChatGPT through OpenAI Secure MCP Tunnel or a publicly reachable MCP endpoint.

## Before you start

For the full Proxmox installation, have these values ready:

- a Gitea base URL, for example `git.example.com`
- a Gitea access token
- an OpenAI Secure MCP Tunnel ID
- an OpenAI Tunnel Runtime API key

The installer does **not** create the OpenAI tunnel credentials for you. Create the Secure MCP Tunnel and its runtime credentials in the OpenAI Platform before starting the installation, then keep the tunnel ID and runtime API key ready for section 4 of the installer.

## Important: OpenAI Platform account required

The tunnel is created in the **OpenAI Platform**, not inside the normal ChatGPT settings.

If you have not used the OpenAI Platform before, first create/activate a Platform account and sign in. After that, open the Platform's **Tunnels** area and select **Create tunnel**.

### 1. Create the tunnel

1. Sign in to the OpenAI Platform.
2. Open **Tunnels**.
3. Click **Create tunnel**.
4. Give the tunnel a descriptive name, for example `Gitea MCP`.
5. Create the tunnel.
6. Copy the displayed tunnel ID. It begins with `tunnel_`.

Keep this ID. The Proxmox installer asks for it as:

```text
OpenAI Secure MCP Tunnel-ID (tunnel_...):
```

### 2. Create the tunnel runtime API key

The runtime key is created separately from the tunnel.

1. In the OpenAI Platform, open **API Keys**.
2. Click **Create new secret key**.
3. Under **Owned by**, select **You**.
4. Enter a descriptive name, for example `Gitea MCP Tunnel`.
5. Select the project that owns the key.
6. Under **Permissions**, select **Restricted**.
7. Leave all unrelated permission categories set to **None**.
8. Find **Tunnels** and set it to **All selected**. In the current August 2026 Platform UI this selects the two tunnel permissions required for runtime use.
9. Click **Create secret key**.
10. Copy the generated `sk-...` key immediately and store it securely. The secret is only shown when it is created.

The finished restricted key should therefore have only the tunnel permissions enabled; model, assistant, file, batch and other API permissions remain disabled.

This key is the value requested by the installer as:

```text
OpenAI Tunnel Runtime API-Key:
```

Do **not** commit the key to Git, paste it into public logs, or reuse an unrestricted general-purpose API key when a dedicated tunnel key can be used.

### Preparation checklist

Before starting the Proxmox installer, make sure you have:

1. your Gitea URL,
2. your Gitea access token,
3. the OpenAI tunnel ID (`tunnel_...`),
4. the dedicated restricted tunnel runtime key (`sk-...`).

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
