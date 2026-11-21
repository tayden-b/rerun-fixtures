# unset-variable

**Class:** `missing_input` · **Stage:** `plan` · **Route:** `autoPr`

## What the patch does
Deletes `default = "demo"` from `variable "environment"` in `variables.tf`.

## What a human sees in the run log
The run ends `errored` during the plan phase of the HCP Terraform run:

```
Error: No value for required variable
The root module input variable "environment" is not set, and has no default value.
```

The default was removed from `var.environment` and the workspace sets no value for it, so the plan cannot start.

## Expected fix
Restore `default = "demo"` on `var.environment` (or set the variable in the workspace — Rerun only edits code). Files the fix should touch: `variables.tf`. Must not touch: `versions.tf`, `main.tf`.
