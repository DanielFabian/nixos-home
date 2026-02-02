#!/usr/bin/env node
/**
 * NixOS Options MCP Server
 * 
 * Provides tools to search NixOS options, packages, and home-manager options
 * via the search.nixos.org Elasticsearch API.
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const NIXOS_ES_URL = "https://search.nixos.org/backend";
const HM_OPTIONS_URL = "https://home-manager-options.extranix.com/api";

// NixOS channel to search (matches our flake)
const CHANNEL = "unstable";

/**
 * Search NixOS options via Elasticsearch
 */
async function searchNixosOptions(query, limit = 20) {
  const response = await fetch(`${NIXOS_ES_URL}/latest-42-nixos-${CHANNEL}/_search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      from: 0,
      size: limit,
      query: {
        bool: {
          must: [
            {
              multi_match: {
                query,
                fields: [
                  "option_name^3",
                  "option_description",
                  "option_type",
                ],
                type: "best_fields",
                fuzziness: "AUTO",
              },
            },
          ],
        },
      },
      _source: [
        "option_name",
        "option_description",
        "option_type",
        "option_default",
        "option_example",
        "option_source",
      ],
    }),
  });

  if (!response.ok) {
    throw new Error(`NixOS search failed: ${response.status}`);
  }

  const data = await response.json();
  return data.hits.hits.map((hit) => ({
    name: hit._source.option_name,
    type: hit._source.option_type,
    description: hit._source.option_description,
    default: hit._source.option_default,
    example: hit._source.option_example,
    source: hit._source.option_source,
  }));
}

/**
 * Search NixOS packages
 */
async function searchNixosPackages(query, limit = 20) {
  const response = await fetch(`${NIXOS_ES_URL}/latest-42-nixos-${CHANNEL}/_search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      from: 0,
      size: limit,
      query: {
        bool: {
          must: [
            {
              multi_match: {
                query,
                fields: [
                  "package_attr_name^4",
                  "package_pname^3",
                  "package_description^2",
                  "package_programs",
                ],
                type: "best_fields",
                fuzziness: "AUTO",
              },
            },
          ],
        },
      },
      _source: [
        "package_attr_name",
        "package_pname",
        "package_version",
        "package_description",
        "package_homepage",
        "package_programs",
      ],
    }),
  });

  if (!response.ok) {
    throw new Error(`Package search failed: ${response.status}`);
  }

  const data = await response.json();
  return data.hits.hits.map((hit) => ({
    attr: hit._source.package_attr_name,
    name: hit._source.package_pname,
    version: hit._source.package_version,
    description: hit._source.package_description,
    homepage: hit._source.package_homepage,
    programs: hit._source.package_programs,
  }));
}

/**
 * Search Home-Manager options
 */
async function searchHomeManagerOptions(query, limit = 20) {
  // home-manager-options.extranix.com has a simpler API
  const response = await fetch(
    `${HM_OPTIONS_URL}/?query=${encodeURIComponent(query)}&release=master`
  );

  if (!response.ok) {
    throw new Error(`Home-Manager search failed: ${response.status}`);
  }

  const data = await response.json();
  return data.slice(0, limit).map((opt) => ({
    name: opt.name,
    type: opt.type,
    description: opt.description,
    default: opt.default,
    example: opt.example,
  }));
}

// Create MCP server
const server = new Server(
  {
    name: "nixos-mcp",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "search_nixos_options",
      description:
        "Search NixOS configuration options. Use this to find system-level options like services, hardware, networking, etc.",
      inputSchema: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "Search query (e.g., 'zfs', 'nvidia', 'services.xserver')",
          },
          limit: {
            type: "number",
            description: "Maximum results to return (default: 20)",
          },
        },
        required: ["query"],
      },
    },
    {
      name: "search_nixos_packages",
      description:
        "Search Nix packages by name or description. Returns package attributes for use in environment.systemPackages or home.packages.",
      inputSchema: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "Package name or description to search",
          },
          limit: {
            type: "number",
            description: "Maximum results to return (default: 20)",
          },
        },
        required: ["query"],
      },
    },
    {
      name: "search_home_manager_options",
      description:
        "Search Home-Manager options for user-level configuration. Use this for programs.*, services.*, xdg.*, etc.",
      inputSchema: {
        type: "object",
        properties: {
          query: {
            type: "string",
            description: "Search query (e.g., 'programs.zsh', 'wayland')",
          },
          limit: {
            type: "number",
            description: "Maximum results to return (default: 20)",
          },
        },
        required: ["query"],
      },
    },
  ],
}));

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let results;

    switch (name) {
      case "search_nixos_options":
        results = await searchNixosOptions(args.query, args.limit);
        break;
      case "search_nixos_packages":
        results = await searchNixosPackages(args.query, args.limit);
        break;
      case "search_home_manager_options":
        results = await searchHomeManagerOptions(args.query, args.limit);
        break;
      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(results, null, 2),
        },
      ],
    };
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// Run server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("NixOS MCP server running");
}

main().catch(console.error);
