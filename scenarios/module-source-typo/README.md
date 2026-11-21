# module-source-typo

**Class:** `module_source` · **Stage:** `init` · **Route:** `draftPr`

## What the patch does
Changes `module "worker_name"`'s `source` in `main.tf` from `./modules/naming` to `./modules/namig`.

## What a human sees in the run log
The run ends `errored` during `terraform init` (the plan phase of the HCP Terraform run fails before planning starts):

```
Error: Unreadable module directory
Unable to evaluate directory symlink: lstat modules/namig: no such file or directory
The directory  could not be read for module "worker_name" at main.tf:20.
Operation failed: failed running terraform init (exit 1)
```

`module "worker_name"` points at `./modules/namig`, which does not exist, so `terraform init` cannot install the module.

## Expected fix
Point the source back at `./modules/naming`. Draft PR: a wrong module path can also mean a missing module, so a human confirms intent. Files the fix should touch: `main.tf`. Must not touch: `versions.tf`, `modules/naming/main.tf`.
