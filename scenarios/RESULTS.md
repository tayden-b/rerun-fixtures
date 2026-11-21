# Scenario results

Recorded on 2026-11-21 (UTC) against HCP Terraform workspace `rerun-fixtures` (`ws-pTtvA1dYZKYUfX89`, org `hashi-org-TF`, Terraform 1.14.9). Each scenario was pushed with `scripts/break.sh <name>`, waited to a terminal state, then reverted with `scripts/reset.sh`. Internal IPs are redacted.

| # | Scenario | Actions run | HCP run | Final status | Failed at | First error line |
|---|---|---|---|---|---|---|
| 1 | `missing-required-arg` | [44844071609](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844071609) | `run-jLueoWCXwJt2cegf` | errored | plan | `Error: Missing required argument` — The argument "byte_length" is required, but no definition was found. |
| 2 | `undeclared-reference` | [44844198414](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844198414) | `run-U1QwgjkB6QN4gFMp` | errored | plan | `Error: Reference to undeclared resource` — A managed resource "random_pet" "clustr" has not been declared in the root module. |
| 3 | `unset-variable` | [44844370743](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844370743) | `run-eDQhbs9n5UT8SdT5` | errored | plan | `Error: No value for required variable` — The root module input variable "environment" is not set, and has no default value. |
| 4 | `provider-version-conflict` | [44843915143](https://github.com/tayden-b/rerun-fixtures/actions/runs/44843915143) | `run-MmCfDwGHL3MAyoCX` | errored | init | `Error: Failed to query available provider packages` — locked provider registry.terraform.io/hashicorp/random 3.9.1 does not match configured version constraint ~> 3.5.0, 3.9.1 |
| 5 | `removed-argument` | [44844518017](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844518017) | `run-f6PFRnpTd5jc81ZH` | errored | plan | `Error: Invalid Configuration for Read-Only Attribute` — Cannot set value for this attribute as the provider has marked it as read-only. (`key_algorithm`, main.tf) |
| 6 | `http-404-postcondition` | [44844662265](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844662265) | `run-v3GYTqfHnnLEx3s6` | errored | plan | `Error: Resource postcondition failed` — Upstream https://httpbin.org/status/404 returned HTTP 404; expected 200. |
| 7 | `check-block-failure` | [44844811972](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844811972) | `run-R9mrUiPCcNQSC8Sk` | errored | plan | `Error: Resource precondition failed` — Release gate: certificate validity (216h) is below the 720h minimum. |
| 8 | `dependency-cycle` | [44844953095](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844953095) | `run-CqmHS2iCcM5PzQCu` | errored | plan | `Error: Cycle: random_pet.cluster, random_id.release` |
| 9 | `module-source-typo` | [44845091639](https://github.com/tayden-b/rerun-fixtures/actions/runs/44845091639) | `run-5ELJM53ncPGwyXn1` | errored | init | `Error: Unreadable module directory` — Unable to evaluate directory symlink: lstat modules/namig: no such file or directory |
| 10 | `apply-time-exit-1` | [44845369898](https://github.com/tayden-b/rerun-fixtures/actions/runs/44845369898) | `run-3ytwwidAGVQdc3HA` | errored | apply | `Error: local-exec provisioner error` — Error running command 'echo 'platform platform-demo released with 556f7658' && exit 1': exit status 1. |
| 11 | `bad-http-url` | [44845224270](https://github.com/tayden-b/rerun-fixtures/actions/runs/44845224270) | `run-uDw5DwqRNor1grxR` | errored | plan | `Error: Error making request` — GET https://httpbin.invalid/status/200 giving up after 1 attempt(s): dial tcp: lookup httpbin.invalid on [redacted]:53: no such host |

Baseline runs:

| Run | Actions run | HCP run | Final status |
|---|---|---|---|
| Initial baseline | [44843529304](https://github.com/tayden-b/rerun-fixtures/actions/runs/44843529304) | `run-7KXYbfgHKMiiwEkS` | applied |
| Final `reset: baseline` (after `apply-time-exit-1`) | [44845470025](https://github.com/tayden-b/rerun-fixtures/actions/runs/44845470025) | `run-qqnWfwMHsknQ3zhZ` | applied |

Notes:
- The intermediate `reset: baseline` runs after scenarios 1–9 and 11 ended `planned_and_finished` (no changes): those scenarios failed before anything was applied, so the infrastructure was already at baseline. Only `apply-time-exit-1` changes real state (it replaces `terraform_data.announce`), so it ran last and its reset ends `applied`.
- Init-stage scenarios (4, 9) fail `terraform init` on the Actions runner, so the workflow queues the run through the API instead of the CLI. Their HCP run message is the commit subject (`scenario: <name>`); CLI-driven runs show `Triggered via CLI`. In both cases HCP Terraform reports the init failure in the plan phase log (`Operation failed: failed running terraform init (exit 1)`).
- CLI-driven plan logs are structured JSON lines (`{"@level":"error","@message":"Error: …","diagnostic":{…}}`); API-queued runs (4, 9) produce plain-text logs with `│ Error:` lines.
