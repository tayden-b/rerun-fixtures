# check-block-failure

**Class:** `precondition_failed` · **Stage:** `plan` · **Route:** `autoPr`

## What the patch does
Changes the default of `var.cert_validity_hours` in `variables.tf` from `2160` to `216`.

## What a human sees in the run log
The run ends `errored` during the plan phase of the HCP Terraform run:

```
Error: Resource precondition failed
Release gate: certificate validity (216h) is below the 720h minimum. (preceded by `Warning: Check block assertion failed` from check "certificate_validity")
```

The certificate validity default dropped from 2160h to 216h (a lost digit), below the 720h guardrail in `checks.tf`. The `check "certificate_validity"` block warns and the matching `release_gate` precondition stops the plan.

## Expected fix
Restore `2160`. The guardrails in `checks.tf` must not be weakened. Files the fix should touch: `variables.tf`. Must not touch: `versions.tf`, `checks.tf`.
