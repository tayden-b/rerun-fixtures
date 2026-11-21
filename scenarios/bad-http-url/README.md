# bad-http-url

**Class:** `provider_api_error` · **Stage:** `plan` · **Route:** `autoPr`

## What the patch does
Changes the host in `var.health_check_url`'s default in `variables.tf` from `httpbin.org` to `httpbin.invalid`.

## What a human sees in the run log
The run ends `errored` during the plan phase of the HCP Terraform run:

```
Error: Error making request
GET https://httpbin.invalid/status/200 giving up after 1 attempt(s): Get "https://httpbin.invalid/status/200": dial tcp: lookup httpbin.invalid ... no such host
```

The health-check URL host became `httpbin.invalid`, which can never resolve, so the http provider's request fails while reading `data.http.upstream` during plan.

## Expected fix
Restore `https://httpbin.org/status/200`. Files the fix should touch: `variables.tf`. Must not touch: `versions.tf`, `main.tf`.
