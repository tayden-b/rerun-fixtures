# apply-time-exit-1

**Class:** `apply_runtime` · **Stage:** `apply` · **Route:** `autoPr`

## What the patch does
Appends `&& exit 1` to `local.announce_command` in `main.tf` (which also forces `terraform_data.announce` to be replaced, so the provisioner runs).

## What a human sees in the run log
The run ends `errored` during the apply phase, after a successful plan:

```
Error: local-exec provisioner error
Error running command 'echo 'platform platform-demo released with <hex>' && exit 1': exit status 1. Output: platform platform-demo released with <hex>
```

The release announcement command now ends in `exit 1`; the plan succeeds, but the `local-exec` provisioner on `terraform_data.announce` fails during apply.

## Expected fix
Remove `&& exit 1` from `local.announce_command`. Files the fix should touch: `main.tf`. Must not touch: `versions.tf`.
