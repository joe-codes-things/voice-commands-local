---
description: "Review project onboarding documentation and master prompt guidelines."
name: "go"
agent: "agent"
---
Read and apply the master guidelines from `.github/instructions/master-prompt.instructions.md`. Additionally, search for and read all other .md files in the entire project directory to understand the full context and documentation. Check if a codebase exists: if it does but documentation files are missing, create the required documentation files (PROJECT-ONBOARDING.md, BUGS.md, VERSIONS.md) in the `/docs/` folder. If a codebase exists, also check for missing or outdated dependencies, verify paths, and resolve any version issues. After ingesting the project guidance and all other .md documentation files found in the project, reply with this exact message: Onboarding successfully completed. Awaiting your next instruction. NOTE: Do not create documentation files if the project contains no codebase.
