# missing-required-arg

**Class:** `config_syntax` · **Stage:** `plan` · **Route:** `autoPr`

## What the patch does
Removes `byte_length = 4` from `random_id.release` in `main.tf`.

## What a human sees in the run log
The run ends `errored` during the plan phase of the HCP Terraform run:

```
Error: Missing required argument
The argument "byte_length" is required, but no definition was found.
```

The `byte_length` argument was deleted from `random_id.release`; Terraform rejects the resource because a required argument is missing.

## Expected fix
Restore `byte_length = 4` on `random_id.release`. Files the fix should touch: `main.tf`. Must not touch: `versions.tf`.
