# Scenario results

Every scenario was pushed with `scripts/break.sh <name>`, left to reach a terminal state on HCP Terraform, then reverted with `scripts/reset.sh`. Recorded 2026-11-21 (UTC) on workspace `rerun-fixtures` (`ws-pTtvA1dYZKYUfX89`, Terraform 1.14.9). All 11 ended `errored` at the expected stage.

| #   | Scenario                    | Stage | HCP run                | Actions run                                                                        | Error                                         |
| --- | --------------------------- | ----- | ---------------------- | ---------------------------------------------------------------------------------- | --------------------------------------------- |
| 1   | `missing-required-arg`      | plan  | `run-jLueoWCXwJt2cegf` | [44844071609](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844071609) | Missing required argument                     |
| 2   | `undeclared-reference`      | plan  | `run-U1QwgjkB6QN4gFMp` | [44844198414](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844198414) | Reference to undeclared resource              |
| 3   | `unset-variable`            | plan  | `run-eDQhbs9n5UT8SdT5` | [44844370743](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844370743) | No value for required variable                |
| 4   | `provider-version-conflict` | init  | `run-MmCfDwGHL3MAyoCX` | [44843915143](https://github.com/tayden-b/rerun-fixtures/actions/runs/44843915143) | Failed to query available provider packages   |
| 5   | `removed-argument`          | plan  | `run-f6PFRnpTd5jc81ZH` | [44844518017](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844518017) | Invalid Configuration for Read-Only Attribute |
| 6   | `http-404-postcondition`    | plan  | `run-v3GYTqfHnnLEx3s6` | [44844662265](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844662265) | Resource postcondition failed                 |
| 7   | `check-block-failure`       | plan  | `run-R9mrUiPCcNQSC8Sk` | [44844811972](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844811972) | Resource precondition failed                  |
| 8   | `dependency-cycle`          | plan  | `run-CqmHS2iCcM5PzQCu` | [44844953095](https://github.com/tayden-b/rerun-fixtures/actions/runs/44844953095) | Cycle: random_pet.cluster, random_id.release  |
| 9   | `module-source-typo`        | init  | `run-5ELJM53ncPGwyXn1` | [44845091639](https://github.com/tayden-b/rerun-fixtures/actions/runs/44845091639) | Unreadable module directory                   |
| 10  | `apply-time-exit-1`         | apply | `run-3ytwwidAGVQdc3HA` | [44845369898](https://github.com/tayden-b/rerun-fixtures/actions/runs/44845369898) | local-exec provisioner error                  |
| 11  | `bad-http-url`              | plan  | `run-uDw5DwqRNor1grxR` | [44845224270](https://github.com/tayden-b/rerun-fixtures/actions/runs/44845224270) | Error making request                          |

The full message of each error is in the scenario's `README.md`.

## Baseline runs

| Run                                                 | HCP run                | Actions run                                                                        | Status  |
| --------------------------------------------------- | ---------------------- | ---------------------------------------------------------------------------------- | ------- |
| Initial baseline                                    | `run-7KXYbfgHKMiiwEkS` | [44843529304](https://github.com/tayden-b/rerun-fixtures/actions/runs/44843529304) | applied |
| Final `reset: baseline` (after `apply-time-exit-1`) | `run-qqnWfwMHsknQ3zhZ` | [44845470025](https://github.com/tayden-b/rerun-fixtures/actions/runs/44845470025) | applied |

## Notes

- **Resets.** The `reset: baseline` runs after scenarios 1–9 and 11 ended `planned_and_finished` with no changes: those scenarios fail before anything is applied. Only `apply-time-exit-1` replaces real state (`terraform_data.announce`), so it ran last and its reset ends `applied`.
- **Init-stage runs (4, 9).** `terraform init` fails on the Actions runner, so the workflow queues the run through the HCP Terraform API instead of the CLI. The run message is the commit subject (`scenario: <name>`) instead of `Triggered via CLI`. HCP Terraform reports the init failure inside the plan phase: `Operation failed: failed running terraform init (exit 1)`.
- **Log formats.** CLI-driven plan logs are JSON lines (`{"@level":"error","@message":"Error: …","diagnostic":{…}}`). API-queued runs (4, 9) produce plain-text logs with `│ Error:` lines. Rerun parses both.
- Internal resolver IPs in the `bad-http-url` log are redacted.
