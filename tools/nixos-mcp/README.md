# NixOS MCP Server

MCP server that provides NixOS/Home-Manager option search directly to your AI.

This server is **local-first**: it shells out to `nix` using the flake inputs pinned in `flake.lock` and caches JSON artifacts under `tools/nixos-mcp/.cache/`.

## Tools

- **search_nixos_options** - Search NixOS system options (services, hardware, etc.)
- **search_nixos_packages** - Search Nix packages by name/description
- **search_home_manager_options** - Search Home-Manager user options
- **warm_cache** - Build/caches option JSONs (recommended once per container)

Channels: `stable` and `unstable` (mapped to this repo's `nixpkgs` and `nixpkgs-unstable` inputs).

## Setup

```bash
cd tools/nixos-mcp
npm install
```

Optional (recommended): warm caches once so first queries are instant.

The MCP client can call `warm_cache`, or you can just run a query and let it build on-demand.

## VS Code Configuration

Add to your VS Code settings (or `.vscode/mcp.json`):

```json
{
  "mcp": {
    "servers": {
      "nixos": {
        "command": "node",
        "args": ["tools/nixos-mcp/src/index.js"],
        "cwd": "${workspaceFolder}"
      }
    }
  }
}
```

## Usage

Once configured, your AI can use these tools to look up NixOS/Home-Manager options instead of guessing.

Example queries:
- "What options are available for ZFS?"
- "How do I configure nvidia prime?"
- "What's the home-manager option for zsh vi mode?"

## Notes

- Cache dir: `tools/nixos-mcp/.cache/` (override with `NIXOS_MCP_CACHE_DIR`).
- If you want local corpora for grepping too, see `scripts/sync-nixpkgs.sh` and `scripts/sync-home-manager.sh`.
