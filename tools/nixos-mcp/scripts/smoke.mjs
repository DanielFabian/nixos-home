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

    // Keep the smoke test fast: packages search uses `nix search` and should succeed
    // even if option JSON caches are not built yet.
    const resStable = await client.callTool({
        name: "search_nixos_packages",
        arguments: { query: "firefox", channel: "stable", limit: 3 },
    });
    console.log("stable packages:", resStable.content?.[0]?.text?.slice(0, 200) ?? "<no output>");

    const resUnstable = await client.callTool({
        name: "search_nixos_packages",
        arguments: { query: "firefox", channel: "unstable", limit: 3 },
    });
    console.log(
        "unstable packages:",
        resUnstable.content?.[0]?.text?.slice(0, 200) ?? "<no output>"
    );

    await client.close();
}

main().catch((err) => {
    console.error(err);
    process.exitCode = 1;
});
