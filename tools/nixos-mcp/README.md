# NixOS MCP Server

MCP server that provides NixOS/Home-Manager option search directly to Claude.

## Tools

- **search_nixos_options** - Search NixOS system options (services, hardware, etc.)
- **search_nixos_packages** - Search Nix packages by name/description
- **search_home_manager_options** - Search Home-Manager user options

## Setup

```bash
cd tools/nixos-mcp
npm install
```

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

Once configured, Claude can use these tools to look up NixOS options instead of guessing or asking you to grep nixpkgs.

Example queries:
- "What options are available for ZFS?"
- "How do I configure nvidia prime?"
- "What's the home-manager option for zsh vi mode?"
