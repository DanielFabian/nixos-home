#!/usr/bin/env node
/**
 * NixOS Options MCP Server
 *
 * Local-first search for:
 * - NixOS options (stable + unstable)
 * - Nix packages (stable + unstable)
 * - Home-Manager options (pinned)
 *
 * The upstream HTTP endpoints previously used by this server changed:
 * - search.nixos.org/backend now requires auth
 * - home-manager-options.extranix.com/api now serves HTML
 *
 * So this MCP server shells out to `nix` and caches JSON artifacts locally.
 */

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

import { spawn } from "node:child_process";
import fs from "node:fs";
import fsp from "node:fs/promises";
import path from "node:path";

// Available channels for search (mapped to this repo's pinned flake inputs)
const VALID_CHANNELS = ["stable", "unstable"];
const DEFAULT_CHANNEL = "stable";

const DEFAULT_CACHE_DIR_REL = path.join("tools", "nixos-mcp", ".cache");

function isNonEmptyString(value) {
    return typeof value === "string" && value.trim().length > 0;
}

async function execCommand(command, args, { cwd, env, stdin } = {}) {
    return await new Promise((resolve, reject) => {
        const child = spawn(command, args, {
            cwd,
            env: {
                ...process.env,
                ...(env ?? {}),
            },
            stdio: [stdin ? "pipe" : "ignore", "pipe", "pipe"],
        });

        const stdoutChunks = [];
        const stderrChunks = [];

        child.stdout.on("data", (d) => stdoutChunks.push(d));
        child.stderr.on("data", (d) => stderrChunks.push(d));

        child.on("error", reject);
        child.on("close", (code) => {
            resolve({
                code: code ?? 0,
                stdout: Buffer.concat(stdoutChunks).toString("utf8"),
                stderr: Buffer.concat(stderrChunks).toString("utf8"),
            });
        });

        if (stdin) {
            child.stdin.write(stdin);
            child.stdin.end();
        }
    });
}

async function fileExists(filePath) {
    try {
        await fsp.access(filePath, fs.constants.F_OK);
        return true;
    } catch {
        return false;
    }
}

async function ensureDir(dirPath) {
    await fsp.mkdir(dirPath, { recursive: true });
}

function getWorkspaceRoot() {
    // VS Code MCP config sets cwd to workspace root; fall back to walking upward.
    let current = process.cwd();
    for (let i = 0; i < 10; i++) {
        if (fs.existsSync(path.join(current, "flake.nix"))) return current;
        const parent = path.dirname(current);
        if (parent === current) break;
        current = parent;
    }
    return process.cwd();
}

function getCacheDir() {
    if (isNonEmptyString(process.env.NIXOS_MCP_CACHE_DIR)) {
        return process.env.NIXOS_MCP_CACHE_DIR;
    }
    return path.join(getWorkspaceRoot(), DEFAULT_CACHE_DIR_REL);
}

const memo = {
    flakeInputOutPath: new Map(),
    jsonByPath: new Map(),
    currentSystem: null,
};

async function getCurrentSystem() {
    if (memo.currentSystem) return memo.currentSystem;
    const { code, stdout, stderr } = await execCommand(
        "nix",
        ["eval", "--impure", "--raw", "--expr", "builtins.currentSystem"],
        { cwd: getWorkspaceRoot() }
    );
    if (code !== 0) {
        throw new Error(`Failed to detect current system: ${stderr || stdout}`);
    }
    memo.currentSystem = stdout.trim();
    return memo.currentSystem;
}

async function getFlakeInputOutPath(inputName) {
    if (memo.flakeInputOutPath.has(inputName)) {
        return memo.flakeInputOutPath.get(inputName);
    }

    const root = getWorkspaceRoot();
    const expr = `let f = builtins.getFlake (toString ${JSON.stringify(root)}); in f.inputs.${inputName}.outPath`;
    const { code, stdout, stderr } = await execCommand(
        "nix",
        ["eval", "--impure", "--raw", "--expr", expr],
        { cwd: root }
    );
    if (code !== 0) {
        throw new Error(`Failed to resolve flake input '${inputName}': ${stderr || stdout}`);
    }
    const outPath = stdout.trim();
    memo.flakeInputOutPath.set(inputName, outPath);
    return outPath;
}

async function loadJson(jsonPath) {
    if (memo.jsonByPath.has(jsonPath)) return memo.jsonByPath.get(jsonPath);
    const raw = await fsp.readFile(jsonPath, "utf8");
    const parsed = JSON.parse(raw);
    memo.jsonByPath.set(jsonPath, parsed);
    return parsed;
}

function normalizeText(value) {
    if (value == null) return "";
    if (typeof value === "string") return value;
    try {
        return JSON.stringify(value);
    } catch {
        return String(value);
    }
}

function scoreMatch(haystack, needle) {
    if (!haystack || !needle) return 0;
    const idx = haystack.indexOf(needle);
    if (idx === -1) return 0;
    // earlier matches score higher
    return Math.max(1, 100 - idx);
}

function rankAndLimit(items, query, limit, { nameKey, descriptionKey }) {
    const q = query.toLowerCase().trim();
    const ranked = items
        .map((item) => {
            const name = (item[nameKey] ?? "").toString().toLowerCase();
            const description = (item[descriptionKey] ?? "").toString().toLowerCase();
            const score = scoreMatch(name, q) * 3 + scoreMatch(description, q);
            return { item, score };
        })
        .filter((x) => x.score > 0)
        .sort((a, b) => b.score - a.score);
    return ranked.slice(0, limit).map((x) => x.item);
}

async function findFileByName(rootDir, fileName, maxDepth = 6) {
    const queue = [{ dir: rootDir, depth: 0 }];
    while (queue.length > 0) {
        const { dir, depth } = queue.shift();
        let entries;
        try {
            entries = await fsp.readdir(dir, { withFileTypes: true });
        } catch {
            continue;
        }

        for (const entry of entries) {
            const full = path.join(dir, entry.name);
            if (entry.isFile() && entry.name === fileName) return full;
            if (entry.isDirectory() && depth < maxDepth) {
                queue.push({ dir: full, depth: depth + 1 });
            }
        }
    }
    return null;
}

async function buildAndCacheNixosOptionsJson(channel) {
    const cacheDir = getCacheDir();
    await ensureDir(cacheDir);

    const cachePath = path.join(cacheDir, `nixos-options-${channel}.json`);
    if (await fileExists(cachePath)) return cachePath;

    const inputName = channel === "unstable" ? "nixpkgs-unstable" : "nixpkgs";
    const nixpkgsPath = await getFlakeInputOutPath(inputName);

    const { code, stdout, stderr } = await execCommand(
        "nix",
        [
            "build",
            "--no-link",
            "--print-out-paths",
            "--file",
            path.join(nixpkgsPath, "nixos", "release.nix"),
            "options",
        ],
        { cwd: getWorkspaceRoot() }
    );
    if (code !== 0) {
        throw new Error(`Failed to build NixOS options JSON (${channel}): ${stderr || stdout}`);
    }

    const outPath = stdout.trim().split(/\s+/).filter(Boolean)[0];
    if (!outPath) {
        throw new Error(`Failed to build NixOS options JSON (${channel}): no output path`);
    }

    const optionsJson =
        (await findFileByName(outPath, "options.json")) ??
        path.join(outPath, "share", "doc", "nixos", "options.json");

    if (!(await fileExists(optionsJson))) {
        throw new Error(
            `Built NixOS options JSON (${channel}), but could not locate options.json under ${outPath}`
        );
    }

    await fsp.copyFile(optionsJson, cachePath);
    return cachePath;
}

async function buildAndCacheHomeManagerOptionsJson() {
    const cacheDir = getCacheDir();
    await ensureDir(cacheDir);

    const cachePath = path.join(cacheDir, `home-manager-options.json`);
    if (await fileExists(cachePath)) return cachePath;

    const hmPath = await getFlakeInputOutPath("home-manager");
    const system = await getCurrentSystem();

    const installable = `path:${hmPath}#packages.${system}.docs-json`;
    const { code, stdout, stderr } = await execCommand(
        "nix",
        ["build", "--no-link", "--print-out-paths", installable],
        { cwd: getWorkspaceRoot() }
    );
    if (code !== 0) {
        throw new Error(`Failed to build Home-Manager options JSON: ${stderr || stdout}`);
    }

    const outPath = stdout.trim().split(/\s+/).filter(Boolean)[0];
    if (!outPath) {
        throw new Error("Failed to build Home-Manager options JSON: no output path");
    }

    const optionsJson =
        (await findFileByName(outPath, "options.json")) ??
        path.join(outPath, "share", "doc", "home-manager", "options.json");

    if (!(await fileExists(optionsJson))) {
        throw new Error(
            `Built Home-Manager options JSON, but could not locate options.json under ${outPath}`
        );
    }

    await fsp.copyFile(optionsJson, cachePath);
    return cachePath;
}

async function warmCache() {
    const results = {
        cacheDir: getCacheDir(),
        nixos: {},
        homeManager: null,
    };

    // Build both stable + unstable NixOS options.
    for (const channel of VALID_CHANNELS) {
        results.nixos[channel] = await buildAndCacheNixosOptionsJson(channel);
    }

    results.homeManager = await buildAndCacheHomeManagerOptionsJson();
    return results;
}

async function searchNixosOptions(query, channel = DEFAULT_CHANNEL, limit = 20) {
    if (!VALID_CHANNELS.includes(channel)) channel = DEFAULT_CHANNEL;

    const jsonPath = await buildAndCacheNixosOptionsJson(channel);
    const data = await loadJson(jsonPath);

    const optionsObj = data.options ?? data;
    const items = Object.entries(optionsObj).map(([name, opt]) => {
        const description = normalizeText(opt.description ?? opt.option_description);
        const type = normalizeText(opt.type ?? opt.option_type);
        return {
            name,
            type,
            description,
            default: opt.default ?? opt.option_default,
            example: opt.example ?? opt.option_example,
            source: opt.declarations ?? opt.option_source ?? opt.declaration,
        };
    });

    return rankAndLimit(items, query, limit, {
        nameKey: "name",
        descriptionKey: "description",
    });
}

async function searchNixosPackages(query, channel = DEFAULT_CHANNEL, limit = 20) {
    if (!VALID_CHANNELS.includes(channel)) channel = DEFAULT_CHANNEL;

    const inputName = channel === "unstable" ? "nixpkgs-unstable" : "nixpkgs";
    const nixpkgsPath = await getFlakeInputOutPath(inputName);

    const { code, stdout, stderr } = await execCommand(
        "nix",
        ["search", "--json", `path:${nixpkgsPath}`, query],
        { cwd: getWorkspaceRoot() }
    );
    if (code !== 0) {
        throw new Error(`nix search failed (${channel}): ${stderr || stdout}`);
    }

    const raw = stdout.trim();
    const obj = raw.length === 0 ? {} : JSON.parse(raw);
    const entries = Object.entries(obj);

    return entries.slice(0, limit).map(([key, value]) => ({
        attr: key,
        name: value.pname ?? value.name ?? key,
        version: value.version ?? "",
        description: value.description ?? "",
        homepage: value.homepage ?? null,
        programs: value.programs ?? null,
    }));
}

async function searchHomeManagerOptions(query, limit = 20) {
    const jsonPath = await buildAndCacheHomeManagerOptionsJson();
    const data = await loadJson(jsonPath);

    const optionsObj = data.options ?? data;
    const items = Object.entries(optionsObj).map(([name, opt]) => {
        const description = normalizeText(opt.description ?? opt.option_description);
        const type = normalizeText(opt.type ?? opt.option_type);
        return {
            name,
            type,
            description,
            default: opt.default ?? opt.option_default,
            example: opt.example ?? opt.option_example,
        };
    });

    return rankAndLimit(items, query, limit, {
        nameKey: "name",
        descriptionKey: "description",
    });
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
                    channel: {
                        type: "string",
                        description: "Channel to search: 'stable' or 'unstable' (default: stable)",
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
                    channel: {
                        type: "string",
                        description: "Channel to search: 'stable' or 'unstable' (default: stable)",
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
        {
            name: "warm_cache",
            description:
                "Build and cache option JSONs locally (NixOS stable+unstable and Home-Manager). Run this once to avoid first-query build latency.",
            inputSchema: {
                type: "object",
                properties: {},
            },
        },
    ],
}));

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    try {
        let results;
        const channel = args.channel || DEFAULT_CHANNEL;

        switch (name) {
            case "search_nixos_options":
                results = await searchNixosOptions(args.query, channel, args.limit);
                break;
            case "search_nixos_packages":
                results = await searchNixosPackages(args.query, channel, args.limit);
                break;
            case "search_home_manager_options":
                results = await searchHomeManagerOptions(args.query, args.limit);
                break;
            case "warm_cache":
                results = await warmCache();
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
