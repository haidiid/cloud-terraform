# CLAUDE.md

Terraform configuration for AWS infrastructure (VPC, subnets, route tables, security groups) and a ZooKeeper
EC2 instance on AlmaLinux 10 secured with mutual TLSv1.3. See `README.md` for usage and operations.

## Layout

- `*.tf` (root): providers, networking, variables, outputs.
- `zookeeper-server/`: the ZooKeeper EC2 module, its first-boot user-data script (`main.tfl`),
  `configuration/` (files installed on the instance) and `credential/` (TLS and user material).
  `configuration/krb5/krb5.conf` is the Kerberos client config, a copy of `kerberos-server/configuration/krb5/krb5.conf`:
  keep its `[libdefaults]`, `[realms]` and `[domain_realm]` in sync with the KDC's file.
- `kafka-broker/`: the Kafka broker EC2 module (Kafka 3.9 in ZooKeeper mode), its first-boot user-data script
  (`kafka-broker.tfl`), `configuration/` and `credential/`. `server.properties` is a Terraform template.
- `kerberos-server/`: the Kerberos KDC EC2 module (t3.micro, 15 GiB, Elastic IP `second_public_ip`) for realm
  `HAIDI.ONLINE`. Its first-boot user-data script (`kerberos-server.tfl`) creates the `haidiid` sudo user and
  installs MIT krb5kdc (tickets on 80) and kadmind (kadmin on 9811, kpasswd on 9812).
  `configuration/krb5/` holds `krb5.conf`, `kdc.conf` and `kadm5.acl` as plain files with hard-coded realm,
  hostname and ports (keep them in sync with the `kerberos_*` variables used by the security group and script).
  Every principal requires pre-auth and SPAKE (edwards25519) is the only pre-auth the KDC accepts, so Java's
  built-in Kerberos and Windows SSPI clients cannot get tickets;
  `credential/kerberos/*.pass` holds the KDC master, client (`haidiid`), admin (`haidiid/admin`) and ZooKeeper service
  (`zookeeper/zookeeper.haidi.online`, file `zookeeper-principal.pass`) principal passwords.
- `zookeeper-client/`: client-side `configuration/` and `credential/tls/` for connecting with `zkCli`.
- `ca/`: the self-signed root CA.
- `local.tfvars`: local variable values. Ignored by git; `local.tfvars.asc` is its encrypted copy.
- `kerberos-server/local.tfvars`: values for every `kerberos_*` root variable (none have defaults). Ignored by git;
  pass it with `-var-file=local.tfvars -var-file=kerberos-server/local.tfvars`.

## Credentials

Keys, certificates, keystores (`*.key`, `*.crt`, `*.p12`, `*.csr`) and `*.tfvars` must never be committed.
Only OpenSSL `*.cnf` files are tracked under the `credential/tls/` folders. Kerberos keytabs (`*.keytab`, e.g.
`zookeeper-server/credential/kerberos/zookeeper.keytab`) are ignored too; the ZooKeeper keytab is exported with
`ktadd -norandkey`, so it stays valid while `zookeeper-principal.pass` is unchanged. When moving or adding a
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
