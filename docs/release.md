# Release Process for `admiral-controller`

This document outlines the steps to release a new version of the admiral-controller project, including dependency
updates, container publishing, and downstream considerations. The process ensures that the controller remains compatible
with the api server and that releases are automated via GitHub Actions.

## Prerequisites

- **Tools:**
  - [svu](https://github.com/caarlos0/svu) (Semantic Version Utility) installed for tag version management.
- **Permissions:** Write access to the repository for tagging and pushing.
- **Dependencies:** Familiarity with the `admiral` and `admiral-helm` repositories, as they are tightly coupled with this project.

## Release Steps

### 1. Prepare the Release

#### Update Go Dependencies

- Ensure all Go dependencies are up-to-date:

```bash
go get -u ./...
go mod tidy
```

- Verify no breaking changes affect the controller:

```bash
make test
```

#### Sync with `admiral`

The admiral-controller is coupled to the admiral-api-client and admiral-server. Before releasing:

1. Check the latest versions of admiral client in their respective repositories.
2. Update the dependencies in `go.mod` if needed:

```bash
go get go.admiral.io/admiral/client@<version>
```

3. Test compatibility locally:

```bash
make test
make build
./build/admiral-controller # Basic sanity check
```

4. If changes are required (e.g., API updates), implement and commit them.

---

#### Verify Code Quality

- Run linting and formatting checks:

```bash
make lint
make fmt
```

- Fix any issues or run auto-fixes:

```bash
make lint-fix
```

#### Commit Changes

- Commit and push updates to a feature branch, then merge into `master` via a pull request:

```bash
git add .
git commit -m "Prepare for release: update dependencies and sync with API"
git push origin <branch>
```

- After PR approval and merge:

```bash
git checkout master
git pull origin master
```

### 2. Tag and Release Containers

#### Create a New Version Tag

- Use `svu` to determine the next semantic version (e.g., `v1.0.1`):

```bash
svu next
```

- Tag the release:

```bash
git tag $(svu next)
git push --tags
```

_Example: If `svu next` outputs `v1.0.1`, this creates and pushes the `v1.0.1` tag._

#### Automated Container Publishing

- Pushing the tag triggers the `Publish Containers` GitHub Actions workflow (`.github/workflows/publish.yml`).
- **What Happens:**
  - Goreleaser builds the `admiral-controller` binary for `linux/amd64` and `linux/arm64`.
  - Docker images are published to `ghcr.io/mberwanger/admiral-controller` with tags:
    - `v1.0.1-amd64`, `v1.0.1-arm64` (exact tag).
    - `v1-amd64`, `v1-arm64` (major version).
    - `v1.0-amd64`, `v1.0-arm64` (major.minor version).
    - `latest-amd64`, `latest-arm64` (rolling latest).
  - Multi-arch manifests are created: `v1.0.1`, `v1.0`, `latest`.
  - Provenance attestation is attached (for tagged releases only).
- **Edge Builds:** Merges to `master` (without tags) publish an `edge` tag (e.g., `edge-amd64`, `edge-arm64`, `edge` manifest).

#### Verify the Release

- Check the GitHub Actions run in the repository’s “Actions” tab to ensure success.
- Confirm images are available:

```bash
docker pull ghcr.io/mberwanger/admiral-controller:v1.0.1
docker pull ghcr.io/mberwanger/admiral-controller:edge # For master merges
```

### 3. Update Downstream Components

#### Helm Chart

- The `admiral-controller` Helm chart (in a separate repository) depends on this container image.
- After the container is published:

1. Update the Helm chart’s `values.yaml` or `Chart.yaml` with the new image tag (e.g., `v1.0.1` or `edge`).

```yaml
image:
  repository: ghcr.io/mberwanger/admiral-controller
  tag: v1.0.1
```

2. Test the chart locally:

```bash
helm install --dry-run admiral-controller ./charts/admiral-controller
```

3. Release the updated chart (follow its own release process).

#### Notify Consumers

- If applicable, inform downstream users (e.g., via GitHub release notes, Slack, or email) about the new version and any breaking changes.

## Additional Notes

- **Snapshot Releases:** For testing unreleased changes, use:

```bash
goreleaser release --snapshot --clean
```

_This builds and tags images with a -dev suffix locally (e.g., 1.0.1-dev)._

- **Edge Tag:** The `edge` tag is overwritten with each `master` merge, providing a rolling preview of the latest development state.
- **Troubleshooting:**
  - If the workflow fails, check logs for Goreleaser or Docker errors.
  - Ensure **GH_PAT** has the required scopes (**write:packages**).
- **Versioning:** Follow [Semantic Versioning](https://semver.org/) (e.g., increment patch for fixes, minor for features, major for breaking changes).
