GO ?= go
GO_MOD := $(shell go list -m 2>/dev/null || echo "unknown-module")
APP_NAME ?= $(shell basename $(shell pwd))
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
LDFLAGS := -X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME)

.PHONY: fmt test test-race test-cover vet lint build run \
        clean tidy help \
        init-all init-docker init-cicd init-docs init-internal

# --- Code Quality ---
fmt:
	$(GO) fmt ./...

test:
	$(GO) test ./...

test-race:
	$(GO) test -race ./...

test-cover:
	$(GO) test -coverprofile=coverage.out ./...
	$(GO) tool cover -html=coverage.out -o coverage.html

vet:
	$(GO) vet ./...

lint:
	golangci-lint run ./...

quality: fmt vet lint test
	@echo "quality gate passed"

# --- Build ---
build:
	CGO_ENABLED=0 $(GO) build -ldflags "$(LDFLAGS)" -o ./bin/$(APP_NAME) ./cmd/...

# --- Run ---
run:
	$(GO) run ./cmd/... -config configs/config.yaml

# --- Docker ---
docker-build:
	docker build -t $(APP_NAME):$(VERSION) -t $(APP_NAME):latest .

docker-push: docker-build
	docker tag $(APP_NAME):$(VERSION) $(REGISTRY)/$(APP_NAME):$(VERSION)
	docker push $(REGISTRY)/$(APP_NAME):$(VERSION)

# --- Harness ---
lint-arch:
	go run .claude/skills/plugins/harness-go/scripts/lint-deps.go $(GO_MOD)
	go run .claude/skills/plugins/harness-go/scripts/lint-quality.go

harness-audit:
	go run .claude/skills/plugins/harness-go/scripts/harness-audit.go

# --- Cleanup ---
clean:
	rm -rf bin/ tmp/ coverage.out coverage.html

tidy:
	$(GO) mod tidy

# ========================================
# Init — 按需展开模板
# ========================================

init-all: init-docker init-cicd init-docs init-internal
	@echo ""
	@echo "All templates expanded. See templates/global-skills/ for global skills."

init-docker:
	@echo "→ Expanding Docker templates..."
	cp templates/init/docker/Dockerfile Dockerfile 2>/dev/null || true
	cp templates/init/docker/docker-compose.yml docker-compose.yml 2>/dev/null || true
	@echo "  Done: Dockerfile, docker-compose.yml"

init-cicd:
	@echo "→ Expanding CI/CD templates..."
	mkdir -p .github/workflows
	cp templates/init/ci/.github/workflows/ci.yml .github/workflows/ci.yml 2>/dev/null || true
	@echo "  Done: .github/workflows/ci.yml"

init-docs:
	@echo "→ Expanding docs/ template..."
	cp -r templates/init/docs/* docs/ 2>/dev/null || true
	@echo "  Done: docs/"

init-internal:
	@echo "→ Expanding project skeleton..."
	cp -r templates/init/internal . 2>/dev/null || true
	cp -r templates/init/cmd . 2>/dev/null || true
	cp -r templates/init/configs . 2>/dev/null || true
	cp -r templates/init/scripts . 2>/dev/null || true
	@echo "  Done: internal/, cmd/, configs/, scripts/"

# --- Global Skills ---
init-global-skills:
	@echo "Global skills are in templates/global-skills/"
	@echo "Install them once to ~/.claude/skills/:"
	@echo ""
	@echo "  cp templates/global-skills/deep-thinking.md ~/.claude/skills/"
	@echo "  cp templates/global-skills/prompt-engineering.md ~/.claude/skills/"
	@echo "  cp templates/global-skills/technical_writing.md ~/.claude/skills/"
	@echo "  cp templates/global-skills/devex-tooling.md ~/.claude/skills/"
	@echo "  cp templates/global-skills/coordinator-delegation.md ~/.claude/skills/"
	@echo "  cp templates/global-skills/competitive-analysis.md ~/.claude/skills/"
	@echo ""
	@echo "They're shared across all projects — no need to copy per-project."

# --- Help ---
help:
	@echo "=== Build & Quality ==="
	@echo "  make fmt           Format Go code"
	@echo "  make test          Run tests"
	@echo "  make test-race     Run tests with race detector"
	@echo "  make test-cover    Run tests with coverage"
	@echo "  make vet           Run go vet"
	@echo "  make lint          Run golangci-lint"
	@echo "  make quality       Run fmt + vet + lint + test"
	@echo "  make build         Build binary"
	@echo "  make run           Run application"
	@echo ""
	@echo "=== Harness ==="
	@echo "  make lint-arch     Run harness lint (deps + quality)"
	@echo "  make harness-audit Run harness audit (0-100)"
	@echo ""
	@echo "=== Init (expand templates) ==="
	@echo "  make init-all      Expand everything"
	@echo "  make init-docker   Expand Dockerfile + docker-compose.yml"
	@echo "  make init-cicd     Expand .github/workflows/ci.yml"
	@echo "  make init-docs     Expand docs/ directory"
	@echo "  make init-internal Expand cmd/ + internal/ + configs/ + scripts/"
	@echo ""
	@echo "=== Global Skills ==="
	@echo "  make init-global-skills  Show global skill install instructions"
	@echo ""
	@echo "=== Maintenance ==="
	@echo "  make clean         Clean build artifacts"
	@echo "  make tidy          Run go mod tidy"
