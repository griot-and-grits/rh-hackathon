# Contributing to Griot & Grits Hackathon Toolkit

Thank you for your interest in contributing! This document outlines the process for contributing to this repository.

## Before You Start

**This repository contains infrastructure and deployment automation only.** Application code lives in separate repositories:
- Backend (FastAPI): `gng-backend`
- Frontend (Next.js): `gng-web`

If your contribution involves application code, please contribute to those repositories instead.

## Contribution Workflow

### 1. Open an Issue First

Before starting work, open an issue to discuss your proposed change:

- **Bug reports**: Describe the problem, steps to reproduce, and expected behavior
- **Feature requests**: Explain the use case and proposed solution
- **Infrastructure changes**: Describe what you want to change and why

This helps avoid duplicate work and ensures your contribution aligns with project goals. Wait for feedback before proceeding.

### 2. Fork the Repository

Once your issue is acknowledged:

```bash
# Fork via GitHub UI, then clone your fork
git clone https://github.com/<your-username>/rh-hackathon.git
cd rh-hackathon

# Add upstream remote
git remote add upstream https://github.com/griot-and-grits/rh-hackathon.git
```

### 3. Create a Feature Branch

Create a branch from `main` with a descriptive name:

```bash
git checkout main
git pull upstream main
git checkout -b fix/mongodb-connection-timeout
# or: feat/add-redis-support
# or: docs/improve-troubleshooting
```

Branch naming conventions:
- `fix/` - Bug fixes
- `feat/` - New features
- `docs/` - Documentation updates
- `refactor/` - Code refactoring

### 4. Make Your Changes

Follow these guidelines:

**For scripts (`scripts/`):**
- Use `#!/bin/bash` and `set -euo pipefail`
- Add helpful comments for non-obvious logic
- Test on both local and OpenShift environments if applicable

**For OpenShift manifests (`infra/`):**
- Follow existing directory structure: `infra/<service>/openshift/`
- Use reasonable resource limits
- Test deployments before submitting

**For Makefile changes:**
- Follow existing patterns (use `check-oc` dependency for OpenShift commands)
- Add help text for new targets
- Keep targets simple and composable

**General:**
- Keep commits focused and atomic
- Write clear commit messages (see below)
- Don't include unrelated changes

### 5. Test Your Changes

```bash
# For local development changes
make setup-local
make dev
make status

# For OpenShift changes
oc login <cluster>
make setup-openshift
make oc-status
```

### 6. Commit Your Changes

Write clear commit messages in imperative mood:

```
<type>: <subject line - what changed>

<body - why it changed, context>

<footer - issue references>
```

Example:

```bash
git commit -m "fix: Increase MongoDB connection timeout to 30s

The default 10s timeout was insufficient for slow cluster starts.

Fixes #42"
```

**Commit message structure:**
- **Subject line**: Short summary with conventional prefix (50 chars or less)
- **Body**: Explanation of why the change was made (wrap at 72 chars)
- **Footer**: Issue references go here, on their own line (`Fixes #42`, `Closes #42`, or `Refs #42`)

Use conventional commit prefixes:
- `fix:` - Bug fixes
- `feat:` - New features
- `docs:` - Documentation
- `refactor:` - Code changes that don't fix bugs or add features
- `chore:` - Maintenance tasks

### 7. Push and Create a Pull Request

```bash
git push origin fix/mongodb-connection-timeout
```

Then create a Pull Request via GitHub:

- Reference the issue: "Fixes #42" or "Closes #42"
- Describe what changed and why
- Include testing steps if not obvious
- Add screenshots for UI-related changes

### 8. Address Review Feedback

Maintainers will review your PR. Be responsive to feedback and push additional commits as needed. Once approved, a maintainer will merge your PR.

## Code of Conduct

Be respectful and constructive in all interactions. We're building something meaningful together.

## Questions?

If you're unsure about anything, ask in your issue or reach out to the maintainers. We're happy to help guide your contribution.
