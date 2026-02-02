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

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

import { z } from "zod";

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

async function readFlakeLock() {
    const lockPath = path.join(getWorkspaceRoot(), "flake.lock");
    const raw = await fsp.readFile(lockPath, "utf8");
    return JSON.parse(raw);
}

function sanitizeKey(value) {
    return value
        .replace(/^sha256-/, "")
        .replaceAll("/", "_")
        .replaceAll("+", "-")
        .replaceAll("=", "");
}

async function getFlakeInputCacheKey(inputName) {
    if (memo.cacheKeyByInput.has(inputName)) {
        return memo.cacheKeyByInput.get(inputName);
    }

    memo.flakeLock ??= await readFlakeLock();
    const lock = memo.flakeLock;
    const node = lock?.nodes?.[inputName];
    const locked = node?.locked;

    const narHash = locked?.narHash;
    if (isNonEmptyString(narHash)) {
        const key = sanitizeKey(narHash.trim());
        memo.cacheKeyByInput.set(inputName, key);
        return key;
    }

    const rev = locked?.rev;
    if (isNonEmptyString(rev)) {
        const key = sanitizeKey(rev.trim());
        memo.cacheKeyByInput.set(inputName, key);
        return key;
    }

    const lastModified = locked?.lastModified;
    if (typeof lastModified === "number") {
        const key = `lm-${lastModified}`;
        memo.cacheKeyByInput.set(inputName, key);
        return key;
    }

    memo.cacheKeyByInput.set(inputName, "unknown");
    return "unknown";
}

function shellQuote(value) {
    return `'${String(value).replaceAll("'", `'"'"'`)}'`;
}

function cacheBuildCommand() {
    // Intentionally synchronous/external to avoid MCP client timeouts.
    return `cd ${shellQuote(getWorkspaceRoot())} && npm --prefix tools/nixos-mcp run -s build-caches`;
}

const memo = {
    jsonByPath: new Map(),
    flakeLock: null,
    cacheKeyByInput: new Map(),
};

function toolJson(payload) {
    return {
        content: [
            {
                type: "text",
                text: JSON.stringify(payload, null, 2),
            },
        ],
    };
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

function parseTsvLine(line) {
    // Expected format: attr\tpname\tversion\tdescription\thomepage
    const parts = line.split("\t");
    return {
        attr: parts[0] ?? "",
        name: parts[1] ?? "",
        version: parts[2] ?? "",
        description: parts[3] ?? "",
        homepage: parts[4] ? (parts[4] === "null" ? null : parts[4]) : null,
        programs: null,
    };
}

function ok(results) {
    return { status: "ok", results };
}

function missingCache({ kind, channel, expectedPath }) {
    return {
        status: "missing_cache",
        kind,
        ...(channel ? { channel } : {}),
        expectedPath,
        buildCommand: cacheBuildCommand(),
        message: "Required cache is missing. Run buildCommand synchronously, then retry this tool.",
    };
}

function scorePackage(pkg, tokens) {
    const attr = (pkg.attr ?? "").toLowerCase();
    const pname = (pkg.name ?? "").toLowerCase();
    const desc = (pkg.description ?? "").toLowerCase();

    let score = 0;
    for (const token of tokens) {
        if (!token) continue;

        if (attr === token) score += 1000;
        else if (attr.startsWith(token)) score += 450;
        else score += scoreMatch(attr, token) * 5;

        if (pname === token) score += 700;
        else if (pname.startsWith(token)) score += 300;
        else score += scoreMatch(pname, token) * 4;

        score += scoreMatch(desc, token);
    }

    // Mild preference for shorter attribute paths when scores tie.
    score -= Math.min(attr.length, 200) / 200;
    return score;
}

async function expectedNixosOptionsPath(channel) {
    const inputName = channel === "unstable" ? "nixpkgs-unstable" : "nixpkgs";
    const key = await getFlakeInputCacheKey(inputName);
    return path.join(getCacheDir(), `nixos-options-${channel}-${key}.json`);
}

async function expectedPackagesIndexPath(channel) {
    const inputName = channel === "unstable" ? "nixpkgs-unstable" : "nixpkgs";
    const key = await getFlakeInputCacheKey(inputName);
    return path.join(getCacheDir(), `packages-${channel}-${key}.tsv`);
}

async function expectedHomeManagerOptionsPath() {
    const key = await getFlakeInputCacheKey("home-manager");
    return path.join(getCacheDir(), `home-manager-options-${key}.json`);
}

async function searchNixosOptions(query, channel = DEFAULT_CHANNEL, limit = 20) {
    if (!VALID_CHANNELS.includes(channel)) channel = DEFAULT_CHANNEL;

    const jsonPath = await expectedNixosOptionsPath(channel);
    if (!(await fileExists(jsonPath))) {
        return missingCache({ kind: "nixos-options", channel, expectedPath: jsonPath });
    }

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

    return ok(
        rankAndLimit(items, query, limit, {
            nameKey: "name",
            descriptionKey: "description",
        })
    );
}

async function searchNixosPackages(query, channel = DEFAULT_CHANNEL, limit = 20) {
    if (!VALID_CHANNELS.includes(channel)) channel = DEFAULT_CHANNEL;

    const tsvPath = await expectedPackagesIndexPath(channel);
    if (!(await fileExists(tsvPath))) {
        return missingCache({ kind: "packages", channel, expectedPath: tsvPath });
    }

    const trimmed = query.trim();
    if (trimmed.length === 0) return ok([]);

    const tokens = trimmed
        .toLowerCase()
        .split(/\s+/)
        .filter(Boolean);

    // Single rg: search by the longest token, then filter by the rest in Node.
    const rgNeedle = tokens.reduce((a, b) => (b.length > a.length ? b : a), tokens[0]);
    const { code, stdout, stderr } = await execCommand(
        "rg",
        ["-i", "--fixed-strings", "--max-count", "400", rgNeedle, tsvPath],
        { cwd: getWorkspaceRoot() }
    );

    // rg returns code 1 when no matches.
    if (code !== 0 && code !== 1) {
        throw new Error(`rg search failed (${channel}): ${stderr || stdout}`);
    }

    const lines = stdout
        .split("\n")
        .map((l) => l.trimEnd())
        .filter((l) => l.length > 0);

    const candidates = lines
        .map(parseTsvLine)
        .filter((pkg) => {
            const hay = `${pkg.attr}\t${pkg.name}\t${pkg.description}`.toLowerCase();
            return tokens.every((t) => hay.includes(t));
        })
        .map((pkg) => ({ pkg, score: scorePackage(pkg, tokens) }))
        .sort((a, b) => b.score - a.score)
        .slice(0, limit)
        .map((x) => x.pkg);

    return ok(candidates);
}

async function searchHomeManagerOptions(query, limit = 20) {
    const jsonPath = await expectedHomeManagerOptionsPath();
    if (!(await fileExists(jsonPath))) {
        return missingCache({ kind: "home-manager-options", expectedPath: jsonPath });
    }
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

    return ok(
        rankAndLimit(items, query, limit, {
            nameKey: "name",
            descriptionKey: "description",
        })
    );
}

const ChannelSchema = z.enum(VALID_CHANNELS).optional().describe("Channel: stable or unstable (default: stable)");
const LimitSchema = z
    .number()
    .int()
    .positive()
    .max(100)
    .optional()
    .describe("Maximum results to return (default: 20)");

const SearchWithChannelSchema = z.object({
    query: z.string().min(1).describe("Search query"),
    channel: ChannelSchema,
    limit: LimitSchema,
});

const SearchSchema = z.object({
    query: z.string().min(1).describe("Search query"),
    limit: LimitSchema,
});

// Create MCP server (high-level API)
const server = new McpServer({
    name: "nixos-mcp",
    version: "0.1.0",
});

server.registerTool(
    "search_nixos_options",
    {
        description:
            "Search NixOS configuration options. Use this to find system-level options like services, hardware, networking, etc.",
        inputSchema: SearchWithChannelSchema,
    },
    async ({ query, channel, limit }) => {
        const payload = await searchNixosOptions(
            query,
            channel ?? DEFAULT_CHANNEL,
            limit ?? 20
        );
        return toolJson(payload);
    }
);

server.registerTool(
    "search_nixos_packages",
    {
        description:
            "Search Nix packages by name or description. Returns package attributes for use in environment.systemPackages or home.packages.",
        inputSchema: SearchWithChannelSchema,
    },
    async ({ query, channel, limit }) => {
        const payload = await searchNixosPackages(
            query,
            channel ?? DEFAULT_CHANNEL,
            limit ?? 20
        );
        return toolJson(payload);
    }
);

server.registerTool(
    "search_home_manager_options",
    {
        description:
            "Search Home-Manager options for user-level configuration. Use this for programs.*, services.*, xdg.*, etc.",
        inputSchema: SearchSchema,
    },
    async ({ query, limit }) => {
        const payload = await searchHomeManagerOptions(query, limit ?? 20);
        return toolJson(payload);
    }
);

// Run server
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("NixOS MCP server running");
}

main().catch(console.error);
