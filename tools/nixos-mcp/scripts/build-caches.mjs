#!/usr/bin/env node

import fs from "node:fs";
import fsp from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { spawn } from "node:child_process";

const CHANNELS = ["stable", "unstable"];

const memo = {
    flakeLock: null,
    cacheKeyByInput: new Map(),
    flakeInputOutPathByInput: new Map(),
    currentSystem: null,
};

function isNonEmptyString(v) {
    return typeof v === "string" && v.trim().length > 0;
}

function findWorkspaceRoot() {
    let current = process.cwd();
    for (let i = 0; i < 10; i++) {
        if (fs.existsSync(path.join(current, "flake.nix"))) return current;
        const parent = path.dirname(current);
        if (parent === current) break;
        current = parent;
    }
    return process.cwd();
}

function cacheDir(root) {
    if (isNonEmptyString(process.env.NIXOS_MCP_CACHE_DIR)) {
        return process.env.NIXOS_MCP_CACHE_DIR;
    }
    return path.join(root, "tools", "nixos-mcp", ".cache");
}

async function ensureDir(dir) {
    await fsp.mkdir(dir, { recursive: true });
}

async function fileExists(p) {
    try {
        await fsp.access(p, fs.constants.F_OK);
        return true;
    } catch {
        return false;
    }
}

async function readFlakeLock(root) {
    const raw = await fsp.readFile(path.join(root, "flake.lock"), "utf8");
    return JSON.parse(raw);
}

function sanitizeKey(value) {
    return value
        .replace(/^sha256-/, "")
        .replaceAll("/", "_")
        .replaceAll("+", "-")
        .replaceAll("=", "");
}

async function flakeInputCacheKey(root, inputName) {
    if (memo.cacheKeyByInput.has(inputName)) {
        return memo.cacheKeyByInput.get(inputName);
    }

    memo.flakeLock ??= await readFlakeLock(root);
    const lock = memo.flakeLock;
    const locked = lock?.nodes?.[inputName]?.locked;

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

async function exec(command, args, { cwd } = {}) {
    return await new Promise((resolve, reject) => {
        const child = spawn(command, args, {
            cwd,
            env: process.env,
            stdio: ["ignore", "pipe", "pipe"],
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
    });
}

async function runPipelineToFile(producer, transformer, outFile, { cwd } = {}) {
    await ensureDir(path.dirname(outFile));

    return await new Promise((resolve, reject) => {
        const producerProc = spawn(producer.command, producer.args, {
            cwd,
            env: process.env,
            stdio: ["ignore", "pipe", "pipe"],
        });

        const transformerProc = spawn(transformer.command, transformer.args, {
            cwd,
            env: process.env,
            stdio: ["pipe", "pipe", "pipe"],
        });

        const outStream = fs.createWriteStream(outFile, { encoding: "utf8" });

        const producerStderr = [];
        const transformerStderr = [];

        producerProc.stderr.on("data", (d) => producerStderr.push(d));
        transformerProc.stderr.on("data", (d) => transformerStderr.push(d));

        producerProc.on("error", reject);
        transformerProc.on("error", reject);
        outStream.on("error", reject);

        producerProc.stdout.pipe(transformerProc.stdin);
        transformerProc.stdout.pipe(outStream);

        let producerCode = null;
        let transformerCode = null;

        const maybeDone = () => {
            if (producerCode === null || transformerCode === null) return;
            if (producerCode === 0 && transformerCode === 0) {
                resolve();
            } else {
                reject(
                    new Error(
                        `Pipeline failed (producer=${producerCode}, transformer=${transformerCode}).\n` +
                        `Producer stderr:\n${Buffer.concat(producerStderr).toString("utf8")}\n` +
                        `Transformer stderr:\n${Buffer.concat(transformerStderr).toString("utf8")}`
                    )
                );
            }
        };

        producerProc.on("close", (code) => {
            producerCode = code ?? 0;
            try {
                transformerProc.stdin.end();
            } catch {
                // ignore
            }
            maybeDone();
        });

        transformerProc.on("close", (code) => {
            transformerCode = code ?? 0;
            maybeDone();
        });
    });
}

async function fileHasNewline(filePath, maxBytes = 64 * 1024) {
    const handle = await fsp.open(filePath, "r");
    try {
        const stat = await handle.stat();
        const size = stat.size ?? 0;
        const toRead = Math.max(0, Math.min(size, maxBytes));
        if (toRead === 0) return false;

        const buf = Buffer.alloc(toRead);
        await handle.read(buf, 0, toRead, 0);
        return buf.includes(0x0a);
    } finally {
        await handle.close();
    }
}

async function runCommandToFile(command, args, outFile, { cwd } = {}) {
    await ensureDir(path.dirname(outFile));

    return await new Promise((resolve, reject) => {
        const child = spawn(command, args, {
            cwd,
            env: process.env,
            stdio: ["ignore", "pipe", "pipe"],
        });

        const stderrChunks = [];
        child.stderr.on("data", (d) => stderrChunks.push(d));

        child.on("error", reject);

        const outStream = fs.createWriteStream(outFile, { encoding: "utf8" });
        outStream.on("error", reject);
        child.stdout.pipe(outStream);

        child.on("close", (code) => {
            const exitCode = code ?? 0;
            if (exitCode === 0) {
                resolve();
                return;
            }
            reject(
                new Error(
                    `Command failed (${command} ${args.join(" ")}):\n${Buffer.concat(stderrChunks).toString("utf8")}`
                )
            );
        });
    });
}

async function ensureMultilineJson(jsonPath, { cwd } = {}) {
    if (!(await fileExists(jsonPath))) return false;

    const hasNewline = await fileHasNewline(jsonPath);
    if (hasNewline) return false;

    const tmpPath = `${jsonPath}.tmp`;
    // Keep size overhead minimal while making it editor/rg friendly.
    // NOTE: jq 1.7 with --indent 0 produces compact one-line output.
    await runCommandToFile("jq", ["--indent", "1", ".", jsonPath], tmpPath, {
        cwd,
    });
    await fsp.rename(tmpPath, jsonPath);
    return true;
}

async function getFlakeInputOutPath(root, inputName) {
    if (memo.flakeInputOutPathByInput.has(inputName)) {
        return memo.flakeInputOutPathByInput.get(inputName);
    }
    const expr = `let f = builtins.getFlake (toString ${JSON.stringify(root)}); in f.inputs.${inputName}.outPath`;
    const { code, stdout, stderr } = await exec("nix", ["eval", "--impure", "--raw", "--expr", expr], {
        cwd: root,
    });
    if (code !== 0) throw new Error(`nix eval flake input outPath failed (${inputName}): ${stderr || stdout}`);
    const outPath = stdout.trim();
    memo.flakeInputOutPathByInput.set(inputName, outPath);
    return outPath;
}

async function getCurrentSystem(root) {
    if (memo.currentSystem) return memo.currentSystem;
    const { code, stdout, stderr } = await exec("nix", ["eval", "--impure", "--raw", "--expr", "builtins.currentSystem"], {
        cwd: root,
    });
    if (code !== 0) throw new Error(`nix eval builtins.currentSystem failed: ${stderr || stdout}`);
    memo.currentSystem = stdout.trim();
    return memo.currentSystem;
}

async function expectedPackagesIndexPath(root, channel) {
    const inputName = channel === "unstable" ? "nixpkgs-unstable" : "nixpkgs";
    const key = await flakeInputCacheKey(root, inputName);
    return path.join(cacheDir(root), `packages-${channel}-${key}.tsv`);
}

async function expectedNixosOptionsPath(root, channel) {
    const inputName = channel === "unstable" ? "nixpkgs-unstable" : "nixpkgs";
    const key = await flakeInputCacheKey(root, inputName);
    return path.join(cacheDir(root), `nixos-options-${channel}-${key}.json`);
}

async function expectedHomeManagerOptionsPath(root) {
    const key = await flakeInputCacheKey(root, "home-manager");
    return path.join(cacheDir(root), `home-manager-options-${key}.json`);
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
            if (entry.isDirectory() && depth < maxDepth) queue.push({ dir: full, depth: depth + 1 });
        }
    }
    return null;
}

function parseArgs(argv) {
    const args = {
        channels: new Set(CHANNELS),
        packages: false,
        options: false,
        homeManager: false,
        all: false,
    };

    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (a === "--all") args.all = true;
        else if (a === "--packages") args.packages = true;
        else if (a === "--options") args.options = true;
        else if (a === "--home-manager") args.homeManager = true;
        else if (a === "--channel") {
            const c = argv[++i];
            if (!CHANNELS.includes(c)) throw new Error(`Invalid --channel ${c}`);
            args.channels.add(c);
        } else if (a === "--channels") {
            // allow: --channels stable unstable
            args.channels.clear();
            while (i + 1 < argv.length && !argv[i + 1].startsWith("--")) {
                const c = argv[++i];
                if (!CHANNELS.includes(c)) throw new Error(`Invalid channel ${c}`);
                args.channels.add(c);
            }
        } else {
            throw new Error(`Unknown arg: ${a}`);
        }
    }

    if (args.all || (!args.packages && !args.options && !args.homeManager)) {
        args.packages = true;
        args.options = true;
        args.homeManager = true;
    }

    return args;
}

async function buildPackagesIndex(root, channel) {
    const inputName = channel === "unstable" ? "nixpkgs-unstable" : "nixpkgs";
    const outDir = cacheDir(root);
    await ensureDir(outDir);

    const finalPath = await expectedPackagesIndexPath(root, channel);
    if (await fileExists(finalPath)) return finalPath;

    const nixpkgsPath = await getFlakeInputOutPath(root, inputName);

    const tmpPath = `${finalPath}.tmp`;

    const jqFilter = [
        "(.packages? // .)",
        "| to_entries[]",
        "| [",
        "  .key,",
        "  (.value.pname // .value.name // \"\"),",
        "  (.value.version // \"\"),",
        "  ((.value.meta.description // \"\") | tostring | gsub(\"\\t\"; \" \" ) | gsub(\"\\n\"; \" \")),",
        "  ((.value.meta.homepage // null) | tostring | gsub(\"\\t\"; \" \" ) | gsub(\"\\n\"; \" \"))",
        "] | @tsv",
    ].join(" ");

    const packagesInfoPath = path.join(nixpkgsPath, "pkgs", "top-level", "packages-info.nix");

    if (await fileExists(packagesInfoPath)) {
        const expr = `import ${JSON.stringify(packagesInfoPath)} { trace = false; }`;
        await runPipelineToFile(
            { command: "nix", args: ["eval", "--impure", "--raw", "--expr", expr] },
            { command: "jq", args: ["-r", jqFilter] },
            tmpPath,
            { cwd: root }
        );
    } else {
        const packagesConfigPath = path.join(nixpkgsPath, "pkgs", "top-level", "packages-config.nix");
        const configExpr = `import ${JSON.stringify(packagesConfigPath)}`;

        await runPipelineToFile(
            {
                command: "nix-env",
                args: [
                    "-f",
                    nixpkgsPath,
                    "-qa",
                    "--meta",
                    "--json",
                    "--show-trace",
                    "--arg",
                    "config",
                    configExpr,
                ],
            },
            { command: "jq", args: ["-r", jqFilter] },
            tmpPath,
            { cwd: root }
        );
    }

    await fsp.rename(tmpPath, finalPath);
    return finalPath;
}

async function buildNixosOptions(root, channel) {
    const inputName = channel === "unstable" ? "nixpkgs-unstable" : "nixpkgs";
    const outDir = cacheDir(root);
    await ensureDir(outDir);

    const finalPath = await expectedNixosOptionsPath(root, channel);
    if (await fileExists(finalPath)) {
        await ensureMultilineJson(finalPath, { cwd: root });
        return finalPath;
    }

    const nixpkgsPath = await getFlakeInputOutPath(root, inputName);

    const { code, stdout, stderr } = await exec(
        "nix",
        [
            "build",
            "--no-link",
            "--print-out-paths",
            "--file",
            path.join(nixpkgsPath, "nixos", "release.nix"),
            "options",
        ],
        { cwd: root }
    );

    if (code !== 0) throw new Error(`nix build nixos options failed (${channel}): ${stderr || stdout}`);

    const outPath = stdout.trim().split(/\s+/).filter(Boolean)[0];
    if (!outPath) throw new Error(`nix build nixos options returned no out path (${channel})`);

    const optionsJson = (await findFileByName(outPath, "options.json")) ?? path.join(outPath, "share", "doc", "nixos", "options.json");
    if (!(await fileExists(optionsJson))) throw new Error(`could not locate options.json under ${outPath}`);

    await fsp.copyFile(optionsJson, finalPath);
    await ensureMultilineJson(finalPath, { cwd: root });
    return finalPath;
}

async function buildHomeManagerOptions(root) {
    const outDir = cacheDir(root);
    await ensureDir(outDir);

    const finalPath = await expectedHomeManagerOptionsPath(root);
    if (await fileExists(finalPath)) {
        await ensureMultilineJson(finalPath, { cwd: root });
        return finalPath;
    }

    const hmPath = await getFlakeInputOutPath(root, "home-manager");
    const system = await getCurrentSystem(root);

    const installable = `path:${hmPath}#packages.${system}.docs-json`;
    const { code, stdout, stderr } = await exec("nix", ["build", "--no-link", "--print-out-paths", installable], {
        cwd: root,
    });

    if (code !== 0) throw new Error(`nix build home-manager docs-json failed: ${stderr || stdout}`);

    const outPath = stdout.trim().split(/\s+/).filter(Boolean)[0];
    if (!outPath) throw new Error("nix build home-manager docs-json returned no out path");

    const optionsJson = (await findFileByName(outPath, "options.json")) ?? path.join(outPath, "share", "doc", "home-manager", "options.json");
    if (!(await fileExists(optionsJson))) throw new Error(`could not locate options.json under ${outPath}`);

    await fsp.copyFile(optionsJson, finalPath);
    await ensureMultilineJson(finalPath, { cwd: root });
    return finalPath;
}

async function main() {
    const args = parseArgs(process.argv.slice(2));
    const root = findWorkspaceRoot();

    console.log(`workspace: ${root}`);
    console.log(`cacheDir:  ${cacheDir(root)}`);

    const channels = Array.from(args.channels);

    if (args.packages) {
        for (const c of channels) {
            const expected = await expectedPackagesIndexPath(root, c);
            if (await fileExists(expected)) {
                console.log(`packages index (${c}) already present`);
                console.log(`  -> ${expected}`);
            } else {
                console.log(`building packages index (${c})...`);
                const p = await buildPackagesIndex(root, c);
                console.log(`  -> ${p}`);
            }
        }
    }

    if (args.options) {
        for (const c of channels) {
            const expected = await expectedNixosOptionsPath(root, c);
            if (await fileExists(expected)) {
                console.log(`nixos options (${c}) already present`);
                console.log(`  -> ${expected}`);
                const reformatted = await ensureMultilineJson(expected, { cwd: root });
                if (reformatted) console.log("  (reformatted to multiline JSON)");
            } else {
                console.log(`building nixos options (${c})...`);
                const p = await buildNixosOptions(root, c);
                console.log(`  -> ${p}`);
            }
        }
    }

    if (args.homeManager) {
        const expected = await expectedHomeManagerOptionsPath(root);
        if (await fileExists(expected)) {
            console.log("home-manager options already present");
            console.log(`  -> ${expected}`);
            const reformatted = await ensureMultilineJson(expected, { cwd: root });
            if (reformatted) console.log("  (reformatted to multiline JSON)");
        } else {
            console.log("building home-manager options...");
            const p = await buildHomeManagerOptions(root);
            console.log(`  -> ${p}`);
        }
    }
}

main().catch((err) => {
    console.error(err);
    process.exitCode = 1;
});
