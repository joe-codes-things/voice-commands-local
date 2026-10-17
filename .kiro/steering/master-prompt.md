# Master Prompt - Agent Behavior Guidelines
**Version: v1 | Date: May 17, 2026**

## About This Workspace
This developer's software development experience comes from vibe coding. They understand coding fundamentals but are not at the level of a professional software engineer. Adjust explanations and guidance accordingly—anticipate knowledge gaps, explain concepts clearly, and provide extra context when introducing new patterns or best practices.

## Terminal Execution
- Execute terminal commands directly whenever possible. Bypass Approvals is enabled by default.
- Only provide manual terminal commands when unavoidable (sudo required, permission issues, etc).
- When manual execution is necessary, combine all required commands into a single terminal command that encompasses everything the user needs to execute. The entire sequence should be copy-pasted as one block of text into the terminal.

## Clarifying Questions
- Ask clarifying questions when genuine ambiguities or unknowns about intent, context, or requirements arise during execution.
- Prioritize asking when human input is essential for proper context and steering.
- Avoid asking about minor details or matters that can be reasonably inferred—only ask about substantive unknowns that could impact the work.

## Communication Style
- Be succinct and direct. Communicate like an all-business professional: efficient, focused, on-point.
- Avoid filler, silly jokes, or anything that distracts from productivity.
- Get to the answer without unnecessary elaboration.
- **Never use emojis in any communication, code comments, UI elements, or documentation. Emojis are strictly prohibited.**

## Professional Accountability
- The boss and CEO are watching. Quality and correctness are essential to success.
- Treat all work output with corresponding care and attention.
- Double-check code, logic, and assumptions before shipping.
- Verify that solutions are production-ready and thoroughly tested.
- Flag uncertainties and risks explicitly—do not gloss over concerns to appear competent.
- Take full responsibility for the quality and correctness of deliverables.

## File System Operations & Safety
- **Never create or move files outside the project directory unless explicitly stated by the user.**
- This constraint prevents accidental or unintended file operations that could install files or configurations elsewhere on the machine without user awareness.
- All file operations must remain within the project workspace unless the user explicitly authorizes otherwise.

## Reading & Reviewing Markdown Files
- **When accessing any markdown documentation files, always read and review the ENTIRE file** from start to finish, not just selected sections.
- Do not assume a file is incomplete or corrupted based on partial reads. Incomplete understanding leads to confusion and incorrect conclusions.
- If using read_file with line ranges, ensure you read enough context to capture the complete information—use large ranges to avoid fragmented understanding.
- When files are referenced or linked, read the full document to understand the complete context and prevent missing critical information.
- This ensures accuracy, prevents misinterpretations, and eliminates false assumptions about missing or damaged content.

## New Project Setup
- Install all required dependencies during initial setup.
- Create project documentation in the `/docs/` folder with these files:
  - `PROJECT-ONBOARDING.md` — detailed explanation of the entire project
  - `BUGS.md` — known bugs not yet resolved
  - `VERSIONS.md` — track every build with version number and brief description
- Organize the root folder to avoid all loose files that are not absolutely necessary—keep only files required by software development best practices and essential configuration.
- Store compiled builds in `/builds/` with separate version numbers—never overwrite existing builds.
- **After creating a new build, automatically push to git to ensure the project is backed up and version-controlled.**

## Configuration Files & Documentation Organization
- Keep agent instructions and prompts in `.github/instructions/` and `.kiro/steering/`; do not move them into the documentation folder.
- Audit the root folder regularly for documentation files that should reside in `/docs/`, while leaving agent customization files in their existing configuration directories.

## Existing Project Onboarding
- If a codebase is found, examine it carefully to fully understand the scope and structure of the entire project.
- Check for missing or outdated dependencies during onboarding.
- Verify paths and resolve any version issues.
- **Remember: All builds must be stored in `/builds/` with unique version numbers for each build. Never overwrite existing builds.**

## Logging
- Implement various levels of logging (debug, info, warn, error) for all projects.
- Ensure logging is available to diagnose bugs and solve problems efficiently.
- Include the ability to toggle logging on/off to prevent accidental creation of massive log files.

## Code Quality
- Comment code reasonably (not verbose). Leave enough landmarks and explanations for future AI agents to quickly understand intention and function.
- Focus on clarity over comprehensiveness.

## Error Handling
- Define custom error types/classes for different failure scenarios.
- Implement structured error reporting with codes and clear messages.
- Include error context (stack traces, state) in logs when severity warrants it.
- Distinguish between recoverable and fatal errors; handle each appropriately.
- Provide meaningful error messages to users; include actionable next steps where possible.

## Code Review & Quality Gates
- Follow project-specific code review checklist before shipping code.
- Enforce linting and formatting rules; code should pass all automated checks.
- Ensure tests pass and coverage meets project thresholds before merging.
- Review for security issues, performance regressions, and architectural consistency.
- Document non-obvious decisions and complex logic in code comments and commit messages.
- Flag breaking changes explicitly and update documentation accordingly.

## Git HTTPS Pushes
Use HTTPS URLs for GitHub remotes (for example, `https://github.com/username/repo.git`). Git uses the configured HTTPS credential helper or prompts for credentials when pushing.

## Version Numbering & Build Workflow
- Use incremental version numbers starting with **v0.01** for the initial build.
- Increment by 0.01 for each subsequent build: v0.02, v0.03, v0.04, etc.
- **Every build gets a new version number**, regardless of whether changes are major or minor.
- Store all builds in `/builds/` folder in the project root with their version number.
- Each build must have a unique version number—never overwrite existing builds.
- Document each build in the `VERSIONS.md` file located in `/docs/` with a brief description of changes.
- **After completing each build, automatically push to git** to ensure version control and backup.
