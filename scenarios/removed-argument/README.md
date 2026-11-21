# removed-argument

**Class:** `config_syntax` · **Stage:** `plan` · **Route:** `autoPr`

## What the patch does
Adds `key_algorithm = "ECDSA"` to `tls_self_signed_cert.platform` in `main.tf`.

## What a human sees in the run log
The run ends `errored` during the plan phase of the HCP Terraform run:

```
Error: Invalid Configuration for Read-Only Attribute
Cannot set value for this attribute as the provider has marked it as read-only. Remove the configuration line setting the value. (on main.tf, in resource "tls_self_signed_cert" "platform": key_algorithm = "ECDSA")
```

`tls_self_signed_cert.platform` sets `key_algorithm`, which tls v4 turned into a read-only attribute (it was an argument in v3); the pinned provider rejects it.

## Expected fix
Delete the `key_algorithm` line; tls v4 derives it from `private_key_pem`. Do not downgrade the provider. Files the fix should touch: `main.tf`. Must not touch: `versions.tf`.
