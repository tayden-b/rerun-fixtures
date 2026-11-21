# rerun-fixtures

The Terraform configuration that [tayden-b/rerun](https://github.com/tayden-b/rerun) watches and fixes. It is a small, plausible platform module built only from no-cloud providers (`random`, `tls`, `http`, `time`, `terraform_data`), plus eleven seeded failure scenarios that break it in known ways.

The HCP Terraform workspace `rerun-fixtures` in organization `hashi-org-TF` applies `main` through GitHub Actions (CLI-driven remote runs; no VCS connection).

## Layout

| Path | What it is |
|---|---|
| `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `checks.tf`, `modules/naming/` | The live configuration that the workspace applies. |
| `baseline/` | Pristine copy of the live configuration. `break.sh` and `reset.sh` restore from here. |
| `scenarios/<name>/` | `break.patch` (applies to the baseline), `expected.json` (what Rerun should conclude), `README.md` (what a human sees in the run log). |
| `scenarios/RESULTS.md` | One recorded HCP Terraform run per scenario, proving each fails for the expected reason. |
| `.github/workflows/terraform.yml` | Push to `main` → `terraform apply`; pull request → speculative `terraform plan`. |
| `scripts/` | Workspace setup and scenario tooling (below). |

## The baseline

- `random_pet` / `random_id` names, and the local `modules/naming` module used twice (`api_name`, `worker_name`).
- A `tls_private_key` with a self-signed certificate, and a `time_rotating` rotation schedule.
- `data "http" "upstream"` against `https://httpbin.org/status/200` with a `postcondition` on `status_code`.
- `checks.tf`: a `check "certificate_validity"` block, and a `terraform_data "release_gate"` precondition enforcing the same guardrail (check blocks only warn; the precondition stops the plan).
- `terraform_data "announce"` with a `local-exec` provisioner that echoes the release.
- `versions.tf` pins Terraform `~> 1.14` and each provider to an exact version; `.terraform.lock.hcl` is committed.

## GitHub Actions

`.github/workflows/terraform.yml` uses the repository secret `TFE_TOKEN` and variable `TFE_ORG`.

- **Push to `main`:** `terraform init` then `terraform apply -auto-approve`. The job uses a `concurrency` group with `cancel-in-progress: false`, so a newer push never cancels a running apply.
- **Pull request:** `terraform init` then `terraform plan` (speculative run in the same workspace).
- **Init failures:** a CLI-driven run cannot start when `terraform init` fails on the runner, so the failure would never reach HCP Terraform. In that case the apply job uploads the same configuration through the API and queues a run; it fails at HCP Terraform's own init, so the workspace records it. The job still fails.

## Scripts

All scripts are bash and need `git`; the workspace script also needs `curl` and `jq`.

| Command | What it does |
|---|---|
| `TFE_TOKEN=… TFE_ORG=hashi-org-TF scripts/ensure-workspace.sh` | Creates the `rerun-fixtures` workspace if it is missing (remote execution, auto-apply, latest Terraform 1.14.x HCP Terraform offers). Idempotent; touches nothing else in the organization. |
| `scripts/break.sh <name>` | Requires a clean `main` in sync with `origin/main`. Restores the baseline, applies `scenarios/<name>/break.patch`, commits `scenario: <name>`, pushes `main` and prints the Actions run URL. |
| `scripts/reset.sh` | Restores the live configuration from `baseline/`, commits `reset: baseline` and pushes. Does nothing if already at baseline. |
| `scripts/verify-scenarios.sh` | Offline check (Terraform CLI only) on a temporary copy: the baseline validates and is `fmt`-clean; each patch applies, stays `fmt`-clean, and either fails `terraform init`/`terraform validate` as expected or validates (and fails later on HCP Terraform). |

## Scenarios

| Scenario | Failure class | Stage | Route | Fails offline at |
|---|---|---|---|---|
| `missing-required-arg` | `config_syntax` | plan | `autoPr` | validate |
| `undeclared-reference` | `config_reference` | plan | `autoPr` | validate |
| `unset-variable` | `missing_input` | plan | `autoPr` | — |
| `provider-version-conflict` | `provider_version` | init | `draftPr` | init |
| `removed-argument` | `config_syntax` | plan | `autoPr` | validate |
| `http-404-postcondition` | `precondition_failed` | plan | `autoPr` | — |
| `check-block-failure` | `precondition_failed` | plan | `autoPr` | — |
| `dependency-cycle` | `dependency_cycle` | plan | `autoPr` | validate |
| `module-source-typo` | `module_source` | init | `draftPr` | init |
| `apply-time-exit-1` | `apply_runtime` | apply | `autoPr` | — |
| `bad-http-url` | `provider_api_error` | plan | `autoPr` | — |

`expected.json` schema: `{ "name", "failureClass", "stage", "route", "fixTouches": [paths], "mustNotTouch": [paths], "humanSummary" }`.

Typical loop:

```bash
scripts/break.sh http-404-postcondition   # run errors on HCP Terraform; Rerun opens a fix PR
scripts/reset.sh                          # back to the baseline
```

<!-- rerun live test rerun/test-1795223067051 -->
