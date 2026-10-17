---
description: "Scan the codebase for deprecated or redundant code and safely clean up confirmed-unused items."
name: "cleanup"
agent: "agent"
---
Carefully scan the entire codebase for redundant code, unused references, old dependencies, commented-out sections, or anything that appears deprecated or no longer needed. Identify what can be safely removed. CRITICAL: Before removing anything, verify it is truly unused and will not break the project. Check for any indirect dependencies or legacy compatibility concerns. Ask clarifying questions if uncertain. Only remove items that are 100% confirmed as safe to delete. Report findings with clear explanations of what was removed and why. Move all documentation files from the root folder to a /docs folder in the root directory, except for AGENTS.md and MASTER-PROMPT.md which must remain in root as configuration files.
