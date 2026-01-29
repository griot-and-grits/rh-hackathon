# Contributing to Griot & Grits

Thank you for your interest in contributing to the Griot & Grits project! We welcome contributions from everyone.

## Getting Started

1.  **Fork the repository** on GitHub.
2.  **Clone your fork** locally:
    ```bash
    git clone https://github.com/your-username/rh-hackathon.git
    cd rh-hackathon
    ```
3.  **Set up your environment** following the [Getting Started Guide](docs/guides/getting-started.md).

## Reporting Issues

If you find a bug or have a feature request, please open an issue on GitHub.

-   **Search existing issues** first to avoid duplicates.
-   **Be descriptive**: Include steps to reproduce, expected behavior, and screenshots if possible.
-   **Use labels**: If you can, tag your issue (e.g., `bug`, `documentation`, `enhancement`).

## Submitting Pull Requests

1.  **Create a branch** for your changes:
    ```bash
    git checkout -b feature/my-awesome-feature
    ```
2.  **Make your changes**.
3.  **Test your changes** locally (`make dev`).
4.  **Commit your changes** with clear messages:
    ```bash
    git commit -m "feat: Add new transcription mode"
    ```
5.  **Push to your fork**:
    ```bash
    git push origin feature/my-awesome-feature
    ```
6.  **Open a Pull Request** against the `main` branch of the upstream repository.

## Code Standards

-   **Documentation**: Update `docs/` if you change functionality. Run `./scripts/verify-docs.sh` to check links.
-   **Scripts**: Shell scripts should start with `set -e` and follow the project's scripting standards.
-   **Formatting**: Keep code clean and readable.

## Documentation Contributions

We value documentation improvements!

-   All documentation lives in `docs/`.
-   Use **Mermaid.js** for diagrams.
-   Ensure all `make` commands referenced actually exist.

## License

By contributing, you agree that your contributions will be licensed under the project's [LICENSE](../LICENSE).
