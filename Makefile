# Use bash as the shell, with environment lookup
SHELL := /usr/bin/env bash

.DEFAULT_GOAL := all

MAKEFLAGS += --no-print-directory --silent

VERSION ?= 0.0.0
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
BUILT_BY ?= $(shell whoami)
PROJECT_ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: help # Print this help message.
help:
	@grep -E '^\.PHONY: [a-zA-Z_-]+ .*?# .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = "(: |#)"}; {printf "%-30s %s\n", $$2, $$3}'

.PHONY: build # Build the controller.
build: preflight-checks
	go build -o ./build/admiral-controller -ldflags="-s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE) -X main.builtBy=$(BUILT_BY)"

.PHONY: dev # Start the controller in development mode.
dev: preflight-checks
	tools/air.sh

.PHONY: lint # Lint the controller code.
lint: preflight-checks
	tools/golangci-lint.sh run --timeout 2m30s

.PHONY: lint-fix # Lint and fix the controller code.
lint-fix: preflight-checks
	tools/golangci-lint.sh run --fix
	go mod tidy

.PHONY: test # Run unit tests for the controller code.
test: preflight-checks
	go test -race -covermode=atomic ./...

.PHONY: verify # Verify go modules' requirements files are clean.
verify: preflight-checks
	go mod tidy
	tools/ensure-no-diff.sh controller

.PHONY: clean # Remove build and cache artifacts.
clean:
	rm -rf build .air

.PHONY: preflight-checks
preflight-checks:
	@tools/preflight-checks.sh

# All target: default full workflow
.PHONY: all
all: clean lint test build