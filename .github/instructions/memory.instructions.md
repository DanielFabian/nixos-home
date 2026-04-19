---
applyTo: '**'
---
## Working Memory Protocol

Maintain a MEMORY.md document that updates with EVERY interaction. Structure:
- **Mission** (3-4 paragraphs max): Why we're here, core problem we're solving, key constraints discovered
- **Active Tasks** (1-2 paragraphs each): For each todo item, maintain context on what we've tried, what failed, why, and current approach. When marking done, fold key learnings into Mission or other tasks and prune ruthlessly, we don't want for it to grow out of control.

Before responding to any technical question, first read MEMORY.md to restore context. After each interaction that advances understanding, update the relevant section. Ask yourself: "If I had to continue this work tomorrow with only this document, what would I need to know?"

Do NOT summarize conversation history. Do NOT retain code snippets or technical details in memory - these can be re-read from source. DO capture the 'why' behind decisions, discovered constraints, and failed approaches that inform future work.

When updating: be specific about what changed in understanding, not just what was done. Example: "Discovered Windows paths break our regex due to backslash escaping in JSON" not "Updated regex pattern."