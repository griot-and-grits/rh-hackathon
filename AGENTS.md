# AGENTS.md

Guidelines for AI coding assistants (Copilot, Cursor, Cody, Aider, etc.) working on this repository.

## Contributing Workflow

**All contributions must follow [CONTRIBUTING.md](CONTRIBUTING.md).** This applies to AI-assisted work.

The required workflow:
1. **Open an issue first** - Discuss the proposed change before writing code
2. **Fork the repository** - External contributors work from forks
3. **Create a feature branch** - Branch from `main` with a descriptive name
4. **Make changes and test** - Follow the guidelines in CONTRIBUTING.md
5. **Create a Pull Request** - Reference the issue number

Do not push directly to `main`. All changes go through pull requests.

## Project Context

This repository contains **infrastructure and deployment automation only**:
- Makefile orchestration
- Bash scripts in `scripts/`
- OpenShift/Kubernetes manifests in `infra/`

**No application code lives here.** Backend (FastAPI) and frontend (Next.js) are in separate repositories.

## Key Files

- `Makefile` - All commands route through here
- `scripts/` - Bash automation (use `set -euo pipefail`)
- `infra/<service>/openshift/` - Kubernetes manifests per service
- `CLAUDE.md` - Detailed project documentation and design decisions

## Commit Messages

Use conventional commits in imperative mood:
- `fix: Increase MongoDB timeout to 30s`
- `feat: Add Redis deployment manifests`
- `docs: Update troubleshooting section`

## Testing

Before submitting changes:
```bash
# Local development
make setup-local && make dev && make status

# OpenShift (if applicable)
oc login <cluster> && make setup-openshift && make oc-status
```
