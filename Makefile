# Griot & Grits - Hackathon Toolkit
# Makefile for simplified deployment commands

.PHONY: help setup-local setup-openshift deploy-services deploy-code sync watch clean status test-e2e test-backend test-all test-services-up test-services-down

# Default target
.DEFAULT_GOAL := help

# Colors
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BOLD := \033[1m
NC := \033[0m

# Variables
USERNAME ?=
WITH_CODE ?= false
MODEL ?= base

# Auto-detect namespace from .openshift-config if not provided
NAMESPACE ?= $(shell if [ -f .openshift-config ]; then grep '^NAMESPACE=' .openshift-config | cut -d= -f2; fi)

##@ General

help: ## Display this help message
	@echo ""
	@echo "$(CYAN)$(BOLD)Griot & Grits - Hackathon Toolkit$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make $(CYAN)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(BOLD)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""

check-oc: ## Check if oc CLI is installed, install if missing
	@if ! command -v oc &> /dev/null; then \
		echo "$(YELLOW)oc CLI not found. Installing...$(NC)"; \
		make install-oc; \
	else \
		echo "$(GREEN)✓ oc CLI is installed: $$(oc version --client 2>/dev/null | head -n1)$(NC)"; \
	fi

install-oc: ## Install oc CLI (auto-detects OS)
	@echo "$(CYAN)Installing oc CLI...$(NC)"
	@if [ "$$(uname)" = "Darwin" ]; then \
		if command -v brew &> /dev/null; then \
			echo "$(CYAN)Using Homebrew to install oc...$(NC)"; \
			brew install openshift-cli; \
		else \
			echo "$(CYAN)Downloading oc CLI for macOS...$(NC)"; \
			curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-mac.tar.gz -o /tmp/oc.tar.gz; \
			tar -xzf /tmp/oc.tar.gz -C /tmp; \
			mkdir -p ~/bin; \
			mv /tmp/oc ~/bin/; \
			chmod +x ~/bin/oc; \
			rm /tmp/oc.tar.gz /tmp/kubectl 2>/dev/null || true; \
			echo "$(GREEN)✓ Installed to ~/bin/oc$(NC)"; \
			echo "$(YELLOW)Add ~/bin to your PATH: export PATH=\"\$$HOME/bin:\$$PATH\"$(NC)"; \
		fi; \
	elif [ "$$(uname)" = "Linux" ]; then \
		echo "$(CYAN)Downloading oc CLI for Linux...$(NC)"; \
		curl -L https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz -o /tmp/oc.tar.gz; \
		tar -xzf /tmp/oc.tar.gz -C /tmp; \
		mkdir -p ~/bin; \
		mv /tmp/oc ~/bin/; \
		chmod +x ~/bin/oc; \
		rm /tmp/oc.tar.gz /tmp/kubectl 2>/dev/null || true; \
		echo "$(GREEN)✓ Installed to ~/bin/oc$(NC)"; \
		echo "$(YELLOW)Add ~/bin to your PATH: export PATH=\"\$$HOME/bin:\$$PATH\"$(NC)"; \
	else \
		echo "$(RED)Unsupported OS: $$(uname)$(NC)"; \
		echo "Please install oc CLI manually from: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/"; \
		exit 1; \
	fi

##@ Local Development

setup-local: ## Setup local development environment (one-time)
	@./scripts/setup.sh

dev: ## Start all services locally (MongoDB + MinIO + Backend + Frontend)
	@./scripts/dev-all.sh

dev-backend: ## Start backend only
	@./scripts/dev-backend.sh

dev-frontend: ## Start frontend only
	@./scripts/dev-frontend.sh

start-services: ## Start MongoDB and MinIO containers
	@./scripts/start-services.sh

stop-services: ## Stop MongoDB and MinIO containers
	@./scripts/stop-services.sh

status: ## Check status of local services
	@./scripts/status.sh

clean-local: ## Remove local containers and volumes
	@./scripts/clean.sh

clean-local-all: ## Remove everything including data
	@./scripts/clean.sh --all

##@ OpenShift - Quick Setup

setup-openshift: check-oc ## Setup OpenShift namespace with MongoDB + MinIO (Usage: make setup-openshift USERNAME=jdoe)
	@if [ -z "$(USERNAME)" ]; then \
		./scripts/setup-openshift.sh; \
	else \
		./scripts/setup-openshift.sh --username $(USERNAME); \
	fi

setup-openshift-with-code: check-oc ## Setup OpenShift with hot-reload code deployment (Usage: make setup-openshift-with-code USERNAME=jdoe)
	@if [ -z "$(USERNAME)" ]; then \
		./scripts/setup-openshift.sh --with-code; \
	else \
		./scripts/setup-openshift.sh --username $(USERNAME) --with-code; \
	fi

delete-namespace: check-oc ## Delete OpenShift namespace (Usage: make delete-namespace USERNAME=jdoe)
	@if [ -z "$(USERNAME)" ]; then \
		./scripts/setup-openshift.sh --delete; \
	else \
		./scripts/setup-openshift.sh --username $(USERNAME) --delete; \
	fi

clean-openshift: ## Delete namespace AND clean up all local OpenShift config files
	@echo "$(CYAN)Cleaning up OpenShift environment...$(NC)"
	@make watch-stop-all 2>/dev/null || true
	@make delete-namespace 2>/dev/null || true
	@echo "$(CYAN)Removing local config files...$(NC)"
	@rm -f .openshift-config .env.openshift .watch-backend.pid .watch-backend.log
	@echo "$(GREEN)✓ OpenShift cleanup complete$(NC)"

##@ OpenShift - Services

deploy-services: check-oc ## Deploy MongoDB and MinIO to OpenShift (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make deploy-services NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@./scripts/deploy-services.sh --namespace $(NAMESPACE)

##@ OpenShift - Code Deployment

deploy-code: check-oc ## Deploy backend + frontend with hot-reload (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make deploy-code NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@./scripts/deploy-code.sh --namespace $(NAMESPACE)

##@ Code Synchronization

sync: check-oc ## Manually sync code to OpenShift pods (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make sync NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@./scripts/sync-code.sh -n $(NAMESPACE)

sync-backend: check-oc ## Sync backend code only (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make sync-backend NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@./scripts/sync-code.sh -b -n $(NAMESPACE)

sync-frontend: check-oc ## Sync frontend code only (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make sync-frontend NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@./scripts/sync-code.sh -f -n $(NAMESPACE)

watch-start: ## Start automatic code sync watcher (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make watch-start NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@./scripts/watch-ctl.sh start $(NAMESPACE)

watch-stop: ## Stop automatic code sync watcher
	@./scripts/watch-ctl.sh stop

watch-status: ## Check watcher status
	@./scripts/watch-ctl.sh status

watch-logs: ## View watcher logs
	@./scripts/watch-ctl.sh logs

watch-restart: ## Restart watcher (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make watch-restart NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@./scripts/watch-ctl.sh restart $(NAMESPACE)

watch-backend: ## Start continuous backend-only sync (instant + periodic) - runs in background
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make watch-backend NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@if [ -f .watch-backend.pid ] && kill -0 $$(cat .watch-backend.pid) 2>/dev/null; then \
		echo "$(YELLOW)⚠ Backend watcher already running (PID: $$(cat .watch-backend.pid))$(NC)"; \
		echo "$(DIM)Use: make watch-backend-stop to stop it first$(NC)"; \
	else \
		echo "$(CYAN)Starting continuous backend sync in background...$(NC)"; \
		nohup ./scripts/watch-backend.sh -n $(NAMESPACE) > .watch-backend.log 2>&1 & \
		echo $$! > .watch-backend.pid; \
		sleep 1; \
		if kill -0 $$(cat .watch-backend.pid) 2>/dev/null; then \
			echo "$(GREEN)✓ Backend watcher started (PID: $$(cat .watch-backend.pid))$(NC)"; \
			echo "$(DIM)Logs: .watch-backend.log$(NC)"; \
			echo "$(DIM)Use: make watch-backend-logs to view logs$(NC)"; \
			echo "$(DIM)Use: make watch-backend-stop to stop$(NC)"; \
		else \
			echo "$(RED)✗ Failed to start backend watcher$(NC)"; \
			rm -f .watch-backend.pid; \
		fi; \
	fi

watch-backend-stop: ## Stop continuous backend sync
	@if [ -f .watch-backend.pid ]; then \
		if kill -0 $$(cat .watch-backend.pid) 2>/dev/null; then \
			echo "$(CYAN)Stopping backend watcher (PID: $$(cat .watch-backend.pid))...$(NC)"; \
			kill $$(cat .watch-backend.pid) 2>/dev/null || true; \
			rm -f .watch-backend.pid; \
			echo "$(GREEN)✓ Backend watcher stopped$(NC)"; \
		else \
			echo "$(YELLOW)Backend watcher not running$(NC)"; \
			rm -f .watch-backend.pid; \
		fi; \
	else \
		echo "$(YELLOW)Backend watcher not running$(NC)"; \
	fi

watch-backend-status: ## Check continuous backend sync status
	@if [ -f .watch-backend.pid ] && kill -0 $$(cat .watch-backend.pid) 2>/dev/null; then \
		echo "$(GREEN)✓ Backend watcher is running (PID: $$(cat .watch-backend.pid))$(NC)"; \
		echo "$(DIM)Logs: .watch-backend.log$(NC)"; \
	else \
		echo "$(YELLOW)Backend watcher is not running$(NC)"; \
		if [ -f .watch-backend.pid ]; then \
			rm -f .watch-backend.pid; \
		fi; \
	fi

watch-backend-logs: ## View continuous backend sync logs
	@if [ -f .watch-backend.log ]; then \
		tail -f .watch-backend.log; \
	else \
		echo "$(YELLOW)No logs found. Is the backend watcher running?$(NC)"; \
	fi

watch-backend-restart: ## Restart continuous backend sync
	@make watch-backend-stop
	@sleep 1
	@make watch-backend

watch-stop-all: ## Stop all watchers (main watcher + backend watcher)
	@echo "$(CYAN)Stopping all watchers...$(NC)"
	@make watch-stop 2>/dev/null || true
	@make watch-backend-stop 2>/dev/null || true
	@echo "$(GREEN)✓ All watchers stopped$(NC)"

##@ Admin Commands (Cluster Admins Only)

admin-import-images: check-oc ## Pre-import container images into cluster (reduces pull time for all users)
	@echo "$(CYAN)$(BOLD)Pre-importing images to OpenShift internal registry...$(NC)"
	@echo "$(YELLOW)This requires cluster-admin permissions$(NC)"
	@echo ""
	@./scripts/admin-import-images.sh

admin-create-namespaces: check-oc
	@echo "$(CYAN)$(BOLD)Creating user namespaces...$(NC)"
	@echo "$(YELLOW)This requires cluster-admin permissions$(NC)"
	@echo ""
	@if [ -n "$(FILE)" ]; then \
		./scripts/admin-create-namespaces.sh --file $(FILE); \
	elif [ -n "$(COUNT)" ]; then \
		./scripts/admin-create-namespaces.sh --numbered $(COUNT); \
	else \
		echo "$(YELLOW)Usage:$(NC)"; \
		echo "  make admin-create-namespaces FILE=users.txt   # From file"; \
		echo "  make admin-create-namespaces COUNT=60         # Numbered users"; \
		exit 1; \
	fi

##@ Optional Services

deploy-whisper: check-oc ## Deploy Whisper ASR service (auto-detects namespace or use NAMESPACE=gng-jdoe MODEL=base)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make deploy-whisper NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@./infra/whisper/deploy.sh --namespace $(NAMESPACE) --model $(MODEL)

delete-whisper: check-oc ## Delete Whisper ASR service (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make delete-whisper NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@./infra/whisper/deploy.sh --namespace $(NAMESPACE) --delete

##@ Utilities

info: ## Show all important links, credentials, and connection details
	@echo ""
	@echo "$(CYAN)$(BOLD)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)$(BOLD)  Griot & Grits - Environment Information$(NC)"
	@echo "$(CYAN)$(BOLD)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@if [ -f .openshift-config ]; then \
		NAMESPACE=$$(grep '^NAMESPACE=' .openshift-config | cut -d= -f2); \
		USERNAME=$$(grep '^USERNAME=' .openshift-config | cut -d= -f2); \
		echo "$(BOLD)OpenShift Environment:$(NC)"; \
		echo "  Namespace: $(CYAN)$$NAMESPACE$(NC)"; \
		echo "  Username:  $(CYAN)$$USERNAME$(NC)"; \
		echo ""; \
		if command -v oc &> /dev/null && oc whoami &> /dev/null; then \
			echo "$(BOLD)Application URLs:$(NC)"; \
			FRONTEND_ROUTE=$$(oc get route frontend -n "$$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo ""); \
			BACKEND_ROUTE=$$(oc get route backend -n "$$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo ""); \
			MINIO_CONSOLE=$$(oc get route minio-console -n "$$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo ""); \
			if [ -n "$$FRONTEND_ROUTE" ]; then \
				echo "  Frontend:      $(GREEN)https://$$FRONTEND_ROUTE$(NC)"; \
			else \
				echo "  Frontend:      $(YELLOW)Not deployed$(NC)"; \
			fi; \
			if [ -n "$$BACKEND_ROUTE" ]; then \
				echo "  Backend API:   $(GREEN)https://$$BACKEND_ROUTE/docs$(NC)"; \
			else \
				echo "  Backend API:   $(YELLOW)Not deployed$(NC)"; \
			fi; \
			if [ -n "$$MINIO_CONSOLE" ]; then \
				echo "  MinIO Console: $(GREEN)https://$$MINIO_CONSOLE$(NC)"; \
			else \
				echo "  MinIO Console: $(YELLOW)Not available$(NC)"; \
			fi; \
		else \
			echo "$(YELLOW)⚠ Not logged into OpenShift - cannot retrieve URLs$(NC)"; \
		fi; \
		echo ""; \
		echo "$(BOLD)Database (MongoDB):$(NC)"; \
		echo "  Host:     $(CYAN)mongodb:27017$(NC) (within cluster)"; \
		echo "  Database: $(CYAN)gngdb$(NC)"; \
		echo "  Username: $(CYAN)admin$(NC)"; \
		echo "  Password: $(CYAN)gngdevpass12$(NC)"; \
		echo "  URI:      $(CYAN)mongodb://admin:gngdevpass12@mongodb:27017/gngdb$(NC)"; \
		echo ""; \
		echo "$(BOLD)Object Storage (MinIO):$(NC)"; \
		echo "  Endpoint:   $(CYAN)minio:9000$(NC) (within cluster)"; \
		echo "  Access Key: $(CYAN)minioadmin$(NC)"; \
		echo "  Secret Key: $(CYAN)minioadmin$(NC)"; \
		echo "  Bucket:     $(CYAN)artifacts$(NC)"; \
		echo ""; \
		echo "$(BOLD)Port Forwarding (for local access):$(NC)"; \
		echo "  MongoDB: $(DIM)oc port-forward service/mongodb 27017:27017 -n $$NAMESPACE$(NC)"; \
		echo "  MinIO:   $(DIM)oc port-forward service/minio 9000:9000 -n $$NAMESPACE$(NC)"; \
		echo ""; \
		echo "$(BOLD)Configuration Files:$(NC)"; \
		echo "  OpenShift config: $(CYAN).openshift-config$(NC)"; \
		if [ -f .env.openshift ]; then \
			echo "  Environment:      $(CYAN).env.openshift$(NC)"; \
		fi; \
		echo ""; \
	elif [ -f ~/gng-backend/.env ]; then \
		echo "$(BOLD)Local Development Environment:$(NC)"; \
		echo ""; \
		echo "$(BOLD)Application URLs:$(NC)"; \
		echo "  Frontend:      $(GREEN)http://localhost:3000$(NC)"; \
		echo "  Backend API:   $(GREEN)http://localhost:8000/docs$(NC)"; \
		echo "  MinIO Console: $(GREEN)http://localhost:9001$(NC)"; \
		echo ""; \
		echo "$(BOLD)Database (MongoDB):$(NC)"; \
		echo "  Host:     $(CYAN)localhost:27017$(NC)"; \
		echo "  Database: $(CYAN)gngdb$(NC)"; \
		echo "  Username: $(CYAN)admin$(NC)"; \
		echo "  Password: $(CYAN)gngdevpass12$(NC)"; \
		echo "  URI:      $(CYAN)mongodb://admin:gngdevpass12@localhost:27017/gngdb$(NC)"; \
		echo ""; \
		echo "$(BOLD)Object Storage (MinIO):$(NC)"; \
		echo "  Endpoint:   $(CYAN)localhost:9000$(NC)"; \
		echo "  Access Key: $(CYAN)minioadmin$(NC)"; \
		echo "  Secret Key: $(CYAN)minioadmin$(NC)"; \
		echo "  Bucket:     $(CYAN)artifacts$(NC)"; \
		echo ""; \
		echo "$(BOLD)Configuration Files:$(NC)"; \
		echo "  Backend env: $(CYAN)~/gng-backend/.env$(NC)"; \
		echo ""; \
	else \
		echo "$(YELLOW)⚠ No environment configured$(NC)"; \
		echo ""; \
		echo "Run one of the following:"; \
		echo "  $(CYAN)make setup-local$(NC)                 - For local development"; \
		echo "  $(CYAN)make setup-openshift USERNAME=xxx$(NC) - For OpenShift development"; \
		echo ""; \
	fi; \
	echo "$(BOLD)Quick Commands:$(NC)"; \
	echo "  $(DIM)make help      # Show all available commands$(NC)"; \
	echo "  $(DIM)make examples  # Show usage examples$(NC)"; \
	echo "  $(DIM)make info      # Show this information again$(NC)"; \
	echo ""

cleanup-jobs: check-oc ## Clean up completed OpenShift jobs
	@./scripts/cleanup-jobs.sh

oc-status: check-oc ## Show all resources in namespace (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		oc get all; \
	else \
		oc get all -n $(NAMESPACE); \
	fi

oc-logs-backend: check-oc ## View backend logs (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make oc-logs-backend NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@oc logs -f deployment/backend -n $(NAMESPACE)

oc-logs-frontend: check-oc ## View frontend logs (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make oc-logs-frontend NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@oc logs -f deployment/frontend -n $(NAMESPACE)

oc-logs-mongodb: check-oc ## View MongoDB logs (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make oc-logs-mongodb NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@oc logs -f deployment/mongodb -n $(NAMESPACE)

oc-logs-minio: check-oc ## View MinIO logs (auto-detects namespace or use NAMESPACE=gng-jdoe)
	@if [ -z "$(NAMESPACE)" ]; then \
		echo "$(YELLOW)Error: Cannot detect namespace. Run setup-openshift first or specify: make oc-logs-minio NAMESPACE=gng-jdoe$(NC)"; \
		exit 1; \
	fi
	@oc logs -f deployment/minio -n $(NAMESPACE)

##@ Testing

# Auto-detect container runtime for compose
COMPOSE_CMD := $(shell if command -v docker > /dev/null 2>&1; then echo "docker compose"; elif command -v podman-compose > /dev/null 2>&1; then echo "podman-compose"; else echo "docker compose"; fi)

test-services-up: ## Start test environment (Docker Compose)
	@echo "$(CYAN)Starting test services...$(NC)"
	@$(COMPOSE_CMD) -f docker-compose.test.yml up -d --build --wait
	@echo "$(GREEN)Test services ready:$(NC)"
	@echo "  Backend:  $(CYAN)http://localhost:8000$(NC)"
	@echo "  Frontend: $(CYAN)http://localhost:3000$(NC)"

test-services-down: ## Stop test environment and remove volumes
	@echo "$(CYAN)Stopping test services...$(NC)"
	@$(COMPOSE_CMD) -f docker-compose.test.yml down -v
	@echo "$(GREEN)Test services stopped$(NC)"

test-backend: ## Run backend API tests (pytest)
	@echo "$(CYAN)Running backend tests...$(NC)"
	@cd $(HOME)/gng-backend && python -m pytest tests/ -v
	@echo "$(GREEN)Backend tests complete$(NC)"

test-e2e: ## Run E2E tests (starts services if not running)
	@echo "$(CYAN)Running E2E tests...$(NC)"
	@cd $(HOME)/gng-web && npx playwright test
	@echo "$(GREEN)E2E tests complete$(NC)"

test-all: ## Run all tests (backend + E2E with Docker Compose)
	@echo "$(CYAN)$(BOLD)Running full test suite...$(NC)"
	@make test-services-up
	@make test-backend || (make test-services-down && exit 1)
	@cd $(HOME)/gng-web && CI=true BACKEND_URL=http://localhost:8000 npx playwright test || (make test-services-down && exit 1)
	@make test-services-down
	@echo "$(GREEN)$(BOLD)All tests passed$(NC)"

##@ Examples

examples: ## Show common usage examples
	@echo ""
	@echo "$(CYAN)$(BOLD)Common Usage Examples$(NC)"
	@echo ""
	@echo "$(BOLD)Local Development:$(NC)"
	@echo "  make setup-local                    # One-time setup"
	@echo "  make dev                            # Start everything"
	@echo "  make status                         # Check what's running"
	@echo "  make stop-services                  # Stop services"
	@echo ""
	@echo "$(BOLD)OpenShift - Quick Start:$(NC)"
	@echo "  make setup-openshift                # Setup namespace (prompts for username)"
	@echo "  make setup-openshift-with-code      # Setup with hot-reload code"
	@echo "  make info                           # View all URLs and credentials"
	@echo ""
	@echo "$(BOLD)OpenShift - Manual Deployment:$(NC)"
	@echo "  make deploy-services                # Deploy MongoDB + MinIO"
	@echo "  make deploy-code                    # Deploy backend + frontend"
	@echo ""
	@echo "$(BOLD)Code Synchronization (auto-detects namespace):$(NC)"
	@echo "  make sync                           # Manual sync"
	@echo "  make watch-start                    # Start auto-sync (background)"
	@echo "  make watch-backend                  # Continuous backend sync (instant, background)"
	@echo "  make watch-backend-status           # Check backend watcher"
	@echo "  make watch-backend-logs             # View backend sync logs"
	@echo "  make watch-stop-all                 # Stop all watchers"
	@echo ""
	@echo "$(BOLD)Monitoring (auto-detects namespace):$(NC)"
	@echo "  make oc-status                      # View all resources"
	@echo "  make oc-logs-backend                # View backend logs"
	@echo "  make oc-logs-frontend               # View frontend logs"
	@echo ""
	@echo "$(BOLD)Cleanup:$(NC)"
	@echo "  make clean-openshift                # Delete namespace + local config files"
	@echo "  make delete-namespace               # Delete namespace only (keep config)"
	@echo "  make clean-local                    # Clean local containers"
	@echo ""
	@echo "$(BOLD)Note:$(NC)"
	@echo "  • Commands auto-detect namespace from .openshift-config (created during setup)"
	@echo "  • Override if needed: make <command> NAMESPACE=gng-custom"
	@echo "  • View config: make info"
	@echo ""
