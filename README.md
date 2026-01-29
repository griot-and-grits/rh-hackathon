# Griot & Grits - Hackathon Toolkit

[![Documentation](https://img.shields.io/badge/docs-current-blue.svg)](docs/README.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

**Preserving minority oral history through AI-powered transcription and semantic search.**

> "Griot & Grits" combines the African tradition of the Griot (storyteller/historian) with the soulful essence of Southern culture. This toolkit empowers communities to digitize, transcribe, and interact with their oral histories using modern AI.

## Documentation

**For detailed documentation, see [docs/](docs/README.md)**.

- [Architecture](./docs/architecture/README.md)
- [Getting Started](./docs/guides/getting-started.md)
- [OpenShift Deployment](./docs/guides/openshift-deployment.md)
- [API Reference](./docs/api/README.md)

---

## Quick Start

Choose your development environment:

### Option 1: Local Development (with containers)

**Prerequisites:** Git, Node.js 18+, Python 3.10+, `uv` or `pip`, `make`

```bash
cd ~/rh-hackathon
make setup-local            # One-time setup (clones repos, installs deps)
make dev                    # Start everything
```

**URLs:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000/docs
- MinIO Console: http://localhost:9001

### Option 2: OpenShift/RHOAI (without containers)

For RHOAI workbenches where containers aren't available.

**Setup:**
```bash
oc login <cluster-url>      # Get login command from web console
cd ~/rh-hackathon
make setup-openshift  # Will prompt for username interactively
```

**Using your services:**
```bash
make oc-status        # View resources
make info             # View connection details
```

---

## Project Structure

```
rh-hackathon/
├── scripts/            # Automation scripts
├── infra/              # Kubernetes/OpenShift manifests
├── env-templates/      # Environment file templates
└── docs/               # Detailed documentation
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for our community standards.

## Getting Help

- View all info: `make info`
- Show commands: `make help` or `make examples`

## License

See [LICENSE](LICENSE) for details.
