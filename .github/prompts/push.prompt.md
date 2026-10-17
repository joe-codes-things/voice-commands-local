---
description: "Manually stage, commit, and push the project using an HTTPS GitHub remote."
name: "push"
agent: "agent"
---
First, check if the project is already a git repository by running 'git status'. If not a git repository, initialize it with 'git init'. Then check if a git remote exists by running 'git remote -v'. If a remote exists, stage all changes with 'git add .', commit with an appropriate message, and push to the remote with 'git push'. If no remote exists, ask the user for the repository HTTPS URL (e.g., https://github.com/username/repo.git). Once provided, add the remote with 'git remote add origin <URL>', then stage, commit, and push. Git will use the configured HTTPS credential helper or prompt for credentials when pushing. Git automatically generates unique commit IDs for each push, so version numbers do not need to change. Report the status of each step clearly.
