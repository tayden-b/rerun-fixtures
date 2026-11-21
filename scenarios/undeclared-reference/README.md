# undeclared-reference

**Class:** `config_reference` · **Stage:** `plan` · **Route:** `autoPr`

## What the patch does
Changes the keeper on `random_id.release` from `random_pet.cluster.id` to `random_pet.clustr.id`.

## What a human sees in the run log
The run ends `errored` during the plan phase of the HCP Terraform run:

```
Error: Reference to undeclared resource
A managed resource "random_pet" "clustr" has not been declared in the root module. (Terraform may suggest `random_pet.cluster`.)
```

`random_id.release` refers to `random_pet.clustr`, a typo for `random_pet.cluster`; the referenced resource is not declared.

## Expected fix
Point the reference back at `random_pet.cluster.id`. Files the fix should touch: `main.tf`. Must not touch: `versions.tf`.
