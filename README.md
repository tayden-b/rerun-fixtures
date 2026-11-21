# rerun-fixtures

The Terraform configuration that [Rerun](https://github.com/tayden-b/rerun) watches and repairs. It is a small platform module built only from providers that need no cloud account (`random`, `tls`, `http`, `time`, `terraform_data`), plus eleven seeded failure scenarios that break it in known, reproducible ways.

The HCP Terraform workspace `rerun-fixtures` applies `main` through GitHub Actions. Rerun reads every failed run through the Terraform MCP server, and its fix pull requests target this repository.

## The baseline

The live configuration at the repository root applies cleanly. `baseline/` holds a pristine copy that the scripts restore from.

| Construct                                                                 | Where                        | Why it is there                                                                                          |
| ------------------------------------------------------------------------- | ---------------------------- | -------------------------------------------------------------------------------------------------------- |
| `random_pet.cluster`, `random_id.release` (keeps on the pet)              | `main.tf`                    | Names and a release id; the keeper is the edge the cycle and reference scenarios break.                  |
| `module "api_name"`, `module "worker_name"`                               | `main.tf`, `modules/naming/` | A local module used twice; its own `random` constraint is what the version scenario breaks.              |
| `tls_private_key.platform`, `tls_self_signed_cert.platform`               | `main.tf`                    | A key and a self-signed certificate on the pinned tls v4 provider, which made `key_algorithm` read-only. |
| `time_rotating.signing`                                                   | `main.tf`                    | A rotation schedule checked by a guardrail.                                                              |
| `data "http" "upstream"` with a `postcondition` on `status_code`          | `main.tf`, `variables.tf`    | A plan-time external call that can fail on HTTP status or DNS.                                           |
| `check "certificate_validity"` and `terraform_data.release_gate`          | `checks.tf`                  | The same guardrail twice: the check block only warns, the resource precondition stops the plan.          |
| `terraform_data.announce` with a `local-exec` provisioner                 | `main.tf`                    | The only apply-time side effect.                                                                         |
| Exact provider pins, Terraform `~> 1.14`, committed `.terraform.lock.hcl` | `versions.tf`                | Init is deterministic, so version failures are seeded, not accidental.                                   |

## Scenarios

Each `scenarios/<name>/` holds `break.patch` (applies to the baseline), `expected.json` (what Rerun should conclude and which files the fix may touch) and `README.md` (the patch, the run log and the expected fix). Every scenario was run against the real workspace; the run ids are in [`scenarios/RESULTS.md`](scenarios/RESULTS.md).

| Scenario                                                                     | Class                 | Stage | Route     | What a human sees in the run log                                                                                    |
| ---------------------------------------------------------------------------- | --------------------- | ----- | --------- | ------------------------------------------------------------------------------------------------------------------- |
| [`missing-required-arg`](scenarios/missing-required-arg/README.md)           | `config_syntax`       | plan  | `autoPr`  | `Missing required argument`: `byte_length` was deleted from `random_id.release`.                                    |
| [`undeclared-reference`](scenarios/undeclared-reference/README.md)           | `config_reference`    | plan  | `autoPr`  | `Reference to undeclared resource`: `random_pet.clustr`, a typo for `random_pet.cluster`.                           |
| [`unset-variable`](scenarios/unset-variable/README.md)                       | `missing_input`       | plan  | `autoPr`  | `No value for required variable`: the default of `var.environment` was removed.                                     |
| [`provider-version-conflict`](scenarios/provider-version-conflict/README.md) | `provider_version`    | init  | `draftPr` | `Failed to query available provider packages`: the module wants `random ~> 3.5.0`, the root pins `3.9.1`.           |
| [`removed-argument`](scenarios/removed-argument/README.md)                   | `config_syntax`       | plan  | `autoPr`  | `Invalid Configuration for Read-Only Attribute`: `key_algorithm` on `tls_self_signed_cert`, read-only since tls v4. |
| [`http-404-postcondition`](scenarios/http-404-postcondition/README.md)       | `precondition_failed` | plan  | `autoPr`  | `Resource postcondition failed`: the health-check URL now returns HTTP 404.                                         |
| [`check-block-failure`](scenarios/check-block-failure/README.md)             | `precondition_failed` | plan  | `autoPr`  | `Resource precondition failed`: certificate validity dropped from 2160h to 216h, below the 720h gate.               |
| [`dependency-cycle`](scenarios/dependency-cycle/README.md)                   | `dependency_cycle`    | plan  | `autoPr`  | `Cycle: random_pet.cluster, random_id.release`.                                                                     |
| [`module-source-typo`](scenarios/module-source-typo/README.md)               | `module_source`       | init  | `draftPr` | `Unreadable module directory`: `./modules/namig` does not exist.                                                    |
| [`apply-time-exit-1`](scenarios/apply-time-exit-1/README.md)                 | `apply_runtime`       | apply | `autoPr`  | `local-exec provisioner error`: the plan succeeds, the announce command exits 1 during apply.                       |
| [`bad-http-url`](scenarios/bad-http-url/README.md)                           | `provider_api_error`  | plan  | `autoPr`  | `Error making request`: `httpbin.invalid` never resolves.                                                           |

Route is the outcome Rerun's router should reach: `autoPr` opens a ready-for-review PR, `draftPr` opens a draft and flags the incident for a human. The two `draftPr` scenarios have more than one defensible fix (relax the module constraint or move the root pin; fix the path or add the missing module).

`expected.json`: `{ "name", "failureClass", "stage", "route", "fixTouches": [paths], "mustNotTouch": [paths], "humanSummary" }`.

## Break and reset

```bash
scripts/break.sh http-404-postcondition   # baseline + patch, commit "scenario: <name>", push main; prints the Actions run URL
scripts/reset.sh                          # restore baseline/, commit "reset: baseline", push; no-op at baseline
```

`break.sh` refuses to run unless `main` is clean and in sync with `origin/main`. Both scripts push to `main`, so each one produces exactly one HCP Terraform run.

| Script                        | What it does                                                                                                                                                                                                               |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `scripts/ensure-workspace.sh` | With `TFE_TOKEN` and `TFE_ORG` set, creates the `rerun-fixtures` workspace if it is missing (remote execution, auto-apply, Terraform 1.14.x). Idempotent; touches nothing else in the organization.                        |
| `scripts/break.sh <name>`     | Applies one scenario as described above.                                                                                                                                                                                   |
| `scripts/reset.sh`            | Returns `main` to the baseline.                                                                                                                                                                                            |
| `scripts/verify-scenarios.sh` | Offline (Terraform CLI only, temporary copy): the baseline validates and is `fmt`-clean; each patch applies, stays `fmt`-clean, and fails `init`/`validate` where it should or validates and fails later on HCP Terraform. |

## GitHub Actions

`.github/workflows/terraform.yml` uses the repository secret `TFE_TOKEN` and the variable `TFE_ORG`.

- **Push to `main`:** `terraform init`, then `terraform apply -auto-approve` as a CLI-driven remote run. A `concurrency` group with `cancel-in-progress: false` keeps a newer push from cancelling a running apply.
- **Pull request:** `terraform init`, then a speculative `terraform plan` in the same workspace. Rerun's fix PRs get this plan as a second check.
- **Init failures:** a CLI-driven run cannot start when `terraform init` fails on the runner, so the failure would never reach HCP Terraform. The apply job then uploads the same configuration through the HCP Terraform API and queues a run, which fails at HCP Terraform's own init and is recorded on the workspace. The job still fails.

## Using it with your own organization

Change `organization` in the `cloud` block of `versions.tf` and `baseline/versions.tf`, set `TFE_TOKEN` and `TFE_ORG` on the repository, and run `scripts/ensure-workspace.sh` once.
