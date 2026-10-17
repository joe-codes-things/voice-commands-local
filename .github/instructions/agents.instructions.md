---
description: "Use when applying this workspace's custom agent commands for onboarding, documentation, cleanup, review, research, or Git push workflows."
---

# Agent Custom Commands Configuration
**Version: v1 | Date: May 17, 2026**

Use these commands by typing them in chat (e.g., "/go", "/cleanup", "/docs").

## Custom Commands

### go
**Description:** Review the project onboarding documentation and master prompt guidelines

**Context:** Read and apply the master guidelines from `.github/instructions/master-prompt.instructions.md`. Additionally, search for and read all other .md files in the entire project directory to understand the full context and documentation. Check if a codebase exists: if it does but documentation files are missing, create the required documentation files (PROJECT-ONBOARDING.md, BUGS.md, VERSIONS.md) in the `/docs/` folder. If a codebase exists, also check for missing or outdated dependencies, verify paths, and resolve any version issues. After ingesting the project guidance and all other .md documentation files found in the project, reply with this exact message: Onboarding successfully completed. Awaiting your next instruction. NOTE: Do not create documentation files if the project contains no codebase.

### docs
**Description:** Update all project documentation

**Context:** If the `/docs/` folder does not exist in the root folder, create it and move documentation files from the root folder into it. Leave agent instructions and prompts in their existing configuration directories. Then review the current state of the project by examining code, git history, issues, and the conversation so far. Update all project documentation files in `/docs/` to reflect the current status, progress, and state of the project. Update PROJECT-ONBOARDING.md, BUGS.md, and VERSIONS.md as needed. Only update or create docs that track the actual project state.

### cleanup
**Description:** Scan and remove deprecated or redundant code; reorganize documentation to /docs folder

**Context:** Carefully scan the entire codebase for redundant code, unused references, old dependencies, commented-out sections, or anything that appears deprecated or no longer needed. Identify what can be safely removed. CRITICAL: Before removing anything, verify it is truly unused and will not break the project. Check for any indirect dependencies or legacy compatibility concerns. Ask clarifying questions if uncertain. Only remove items that are 100% confirmed as safe to delete. Report findings with clear explanations of what was removed and why. Move root-level documentation files to `/docs/` where appropriate. Leave agent instructions and prompts in their existing configuration directories.

### review
**Description:** Comprehensive code review and quality check

**Context:** Adopt the mindset of a senior software developer with genius-level IQ who cares about code correctness like their life depends on it. Conduct a comprehensive review of the entire project: check for compilation errors, linter violations, type errors, logical inconsistencies, and anything that would prevent the project from functioning as intended. Identify and fix all issues systematically. Report all findings and corrections with clear explanations. Do not let a single error slip through.

### research
**Description:** Search online for answers to project issues

**Context:** When encountering snags or problems, search online for answers using forums (Stack Overflow, Reddit, GitHub Issues) and official documentation. Check dependency manuals, library documentation, and existing software documentation. Compile findings and present solutions with clear attribution to sources. Prioritize official documentation, then community Q&A, then general discussions.

### push
**Description:** Manually push the project to git repository

**Context:** First, check if the project is already a git repository by running 'git status'. If not a git repository, initialize it with 'git init'. Then check if a git remote exists by running 'git remote -v'. If a remote exists, stage all changes with 'git add .', commit with an appropriate message, and push to the remote with 'git push'. If no remote exists, ask the user for the repository HTTPS URL (e.g., https://github.com/username/repo.git). Once provided, add the remote with 'git remote add origin <URL>', then stage, commit, and push. Git will use the configured HTTPS credential helper or prompt for credentials when pushing. Git automatically generates unique commit IDs for each push, so version numbers do not need to change. Report the status of each step clearly.

### /.
**Description:** Run comprehensive project maintenance sequence

**Context:** Execute the following commands in this exact order: /cleanup, /review, docs. This runs a complete maintenance cycle that cleans up deprecated code, performs a comprehensive code review, and updates all project documentation to reflect the current state.
