#!/usr/bin/env node

import path from "node:path";
import process from "node:process";

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

function workspaceRoot() {
    // Run from anywhere; assume this script lives at tools/nixos-mcp/scripts/
    return path.resolve(import.meta.dirname, "..", "..", "..");
}

async function main() {
    const root = workspaceRoot();

    const transport = new StdioClientTransport({
        command: "node",
        args: ["tools/nixos-mcp/src/index.js"],
        cwd: root,
        stderr: "pipe",
    });

    const client = new Client({ name: "nixos-mcp-smoke", version: "0.0.0" });
    await client.connect(transport);

    const tools = await client.listTools();
    console.log("tools:", tools.tools.map((t) => t.name).join(", "));

    // Keep the smoke test fast: the server should respond quickly.
    // If caches aren't built yet, tools return {status:"missing_cache", buildCommand:"..."}.
    for (const channel of ["stable", "unstable"]) {
        const res = await client.callTool({
            name: "search_nixos_packages",
            arguments: { query: "firefox", channel, limit: 3 },
        });

        const text = res.content?.[0]?.text;
        if (!text) {
            console.log(`${channel} packages: <no output>`);
            continue;
        }

        let payload;
        try {
            payload = JSON.parse(text);
        } catch {
            console.log(`${channel} packages (raw):`, text.slice(0, 500));
            continue;
        }

        if (payload?.status === "missing_cache") {
            console.log(
                `${channel} packages: missing_cache ->`,
                payload.expectedPath,
                "\n  build:",
                payload.buildCommand
            );
        } else {
            console.log(`${channel} packages:`, JSON.stringify(payload).slice(0, 500));
        }
    }

    await client.close();
}

main().catch((err) => {
    console.error(err);
    process.exitCode = 1;
});
