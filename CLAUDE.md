# CLAUDE.md

Terraform configuration for AWS infrastructure (VPC, subnets, route tables, security groups) and a ZooKeeper
EC2 instance on AlmaLinux 10 secured with mutual TLSv1.3. See `README.md` for usage and operations.

## Layout

- `*.tf` (root): providers, networking, variables, outputs.
- `zookeeper-server/`: the ZooKeeper EC2 module, its first-boot user-data script (`zookeeper-server.tfl`),
  `configuration/` (files installed on the instance) and `credential/` (TLS and user material).
- `zookeeper-client/`: client-side `configuration/` and `credential/tls/` for connecting with `zkCli`.
- `ca/`: the self-signed root CA.
- `local.tfvars`: local variable values. Ignored by git; `local.tfvars.asc` is its encrypted copy.

## Credentials

Keys, certificates, keystores (`*.key`, `*.crt`, `*.p12`, `*.csr`) and `*.tfvars` must never be committed.
Only OpenSSL `*.cnf` files are tracked under the `credential/tls/` folders. When moving or adding a
credential folder, update `.gitignore` and confirm with `git check-ignore -v <path>`.

## Always: encrypt and sign local.tfvars when I and Claude finished making changes in local.tfvars

- first, every turn in which I and Claude made any change in local.tfvars, re-encrypt `local.tfvars` into ASCII-armored `local.tfvars.asc` with the GPG key belong to email: haidi.id@hotmail.com
- second, sign the file the same gpp key
- do both as the commands below
  ```powershell
  gpg --encrypt --armor --recipient "haidi.id@hotmail.com" --output local.tfvars.asc local.tfvars
  ```
  ```powershell
  gpg --armor --detach-sign --digest-algo SHA512 local.tfvars.asc
  ```
