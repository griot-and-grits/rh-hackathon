# Griot & Grits Documentation

> AI-powered preservation of minority oral history.

This documentation covers the infrastructure and operations repository for the Griot & Grits project.

## Quick Links

| Section | Description |
|---------|-------------|
| [Architecture](./architecture/README.md) | System diagrams and component overview |
| [Getting Started](./guides/getting-started.md) | Setup guide (< 30 minutes) |
| [OpenShift Deployment](./guides/openshift-deployment.md) | Deploy to OpenShift/Kubernetes |
| [Configuration](./guides/configuration.md) | Environment variables reference |
| [Admin Setup](./guides/admin-setup.md) | Cluster administration guide |
| [Glossary](./guides/glossary.md) | Terminology and definitions |
| [API Reference](./api/README.md) | Backend API documentation |

## Repository Structure

- `infra/` - Kubernetes/OpenShift manifests
- `scripts/` - Automation scripts
- `env-templates/` - Environment file templates
- `docs/` - This documentation

## Related Repositories

- [gng-backend](https://github.com/griot-and-grits/gng-backend) - FastAPI backend
- [gng-web](https://github.com/griot-and-grits/gng-web) - Next.js frontend
