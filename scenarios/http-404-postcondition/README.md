# http-404-postcondition

**Class:** `precondition_failed` · **Stage:** `plan` · **Route:** `autoPr`

## What the patch does
Changes the default of `var.health_check_url` in `variables.tf` from `/status/200` to `/status/404`.

## What a human sees in the run log
The run ends `errored` during the plan phase of the HCP Terraform run:

```
Error: Resource postcondition failed
Upstream https://httpbin.org/status/404 returned HTTP 404; expected 200. (on main.tf, in data "http" "upstream")
```

The upstream health-check URL now returns HTTP 404, so the postcondition on `data.http.upstream` fails while reading the data source during plan.

## Expected fix
Restore the `/status/200` URL. The postcondition in `main.tf` must stay as it is. Files the fix should touch: `variables.tf`. Must not touch: `versions.tf`, `main.tf`.
