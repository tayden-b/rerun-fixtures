# provider-version-conflict

**Class:** `provider_version` · **Stage:** `init` · **Route:** `draftPr`

## What the patch does
Changes the module's `random` constraint in `modules/naming/main.tf` from `>= 3.5.0` to `~> 3.5.0`.

## What a human sees in the run log
The run ends `errored` during `terraform init` (the plan phase of the HCP Terraform run fails before planning starts):

```
Error: Failed to query available provider packages
Could not retrieve the list of available versions for provider hashicorp/random: locked provider registry.terraform.io/hashicorp/random 3.9.1 does not match configured version constraint 3.9.1, ~> 3.5.0; must use terraform init -upgrade to allow selection of new versions
```

The naming module now requires hashicorp/random `~> 3.5.0` while the root pins `3.9.1`; no version satisfies both, so `terraform init` fails.

## Expected fix
Relax the module constraint back to `>= 3.5.0`. Draft PR: whether the module or the root pin should win is a human call. Files the fix should touch: `modules/naming/main.tf`. Must not touch: `versions.tf`.
