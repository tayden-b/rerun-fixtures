# dependency-cycle

**Class:** `dependency_cycle` · **Stage:** `plan` · **Route:** `autoPr`

## What the patch does
Changes `random_pet.cluster`'s `prefix` in `main.tf` to `"${local.name_prefix}-${random_id.release.hex}"`.

## What a human sees in the run log
The run ends `errored` during the plan phase of the HCP Terraform run:

```
Error: Cycle: random_pet.cluster, random_id.release
```

`random_pet.cluster` now uses `random_id.release.hex` in its prefix, while `random_id.release` already keeps on `random_pet.cluster.id`; the two resources depend on each other.

## Expected fix
Remove the `random_id.release` reference from `random_pet.cluster` (prefix back to `local.name_prefix`). Files the fix should touch: `main.tf`. Must not touch: `versions.tf`.
