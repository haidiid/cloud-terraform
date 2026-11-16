# Infrastructure Terraform Configuration

This repository provides Terraform configurations for deploying AWS infrastructure including VPC networking, subnets, route tables, security groups, and an EC2 instance running AlmaLinux 10 on amd64 architecture.

## Specifications

- **Operating System:** AlmaLinux 10 (x86_64 / amd64)
- **Instance Type:** `t3.small` (2 vCPUs, 2 GiB RAM, amd64)
- **Storage:** 15 GB gp3 encrypted root EBS volume
- **Networking:** Public subnet with automated public IP allocation (`associate_public_ip_address = true`)
- **Security:** Public security group attached with inbound/outbound rules

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Review Execution Plan
```bash
terraform plan -var-file=local.tfvars
```

### 3. Apply Configuration
```bash
terraform apply -var-file=local.tfvars
```

## Managing the ZooKeeper EC2 Instance

The ZooKeeper server is the `aws_instance.main` resource in `zookeeper-server/zookeeper-server.tf` (module `zookeeper_server`). It is
provisioned once, on first boot, by the `zookeeper-server/zookeeper-server.tfl` user-data script. That script installs Java and
ZooKeeper, writes `zookeeper.properties`, and installs the TLS keystore and truststore.

### Destroy only the ZooKeeper EC2 instance

Remove the instance and its root volume while keeping the VPC, subnets, route tables, and
security groups:

```bash
terraform destroy -target=module.zookeeper_server.aws_instance.main -var-file=local.tfvars
```

- Check that the plan shows `1 to destroy` and only lists `module.zookeeper_server.aws_instance.main`, then type `yes`.
- Terraform prints a warning about `-target`. It is expected: the rest of the infrastructure is
  intentionally left out of this run.
- **All data on the instance is lost.** That includes ZooKeeper snapshots and transaction logs under
  `/var/opt/zookeeper/lib`, because the root volume has `delete_on_termination = true`.

### Rebuild the ZooKeeper EC2 instance

Replace the instance with a new one so that `zookeeper-server/zookeeper-server.tfl` runs again. Rebuild after changing anything
the instance installs at boot:

- `zookeeper-server/configuration/**`: properties, systemd unit, rsyslog, sudoers, logback, `myid`
- `zookeeper-server/credential/tls/zookeeper-server.p12` and `zookeeper-server/credential/tls/truststore.p12`
- `zookeeper-server/credential/user/user-password.pass`, `credential/ssh-public-key.pub`
- `zookeeper-server/zookeeper-server.tfl`, or the `zookeeper_uri` / `zookeeper_username` variables

> A plain `terraform apply` after such a change only **updates the instance in place**: AWS stops it,
> swaps the user data, and starts it again. Cloud-init does not rerun the script on an existing
> instance, so the new configuration and certificates are **never installed**. Always rebuild.

1. Make sure the files read by `zookeeper-server/zookeeper-server.tf` exist:

   | File | Content |
   |------|---------|
   | `zookeeper-server/credential/user/user-password.pass` | ZooKeeper OS user password |
   | `credential/ssh-public-key.pub` | SSH public key for the ZooKeeper OS user |
   | `zookeeper-server/credential/tls/zookeeper-server.p12` | server keystore (key + cert + CA chain), password `zookeeper-server` |
   | `zookeeper-server/credential/tls/truststore.p12` | CA truststore, password `ca` |

2. Replace the instance in one step (destroy, then create):

   ```bash
   terraform apply -replace=module.zookeeper_server.aws_instance.main -var-file=local.tfvars
   ```

   The plan should show `1 to add, 0 to change, 1 to destroy`. If the instance was already removed
   with `terraform destroy -target=module.zookeeper_server.aws_instance.main`, a plain
   `terraform apply -var-file=local.tfvars` creates it again.

3. The new instance gets a **new public IP**. Read it from the outputs:

   ```bash
   terraform output instance_public_ip
   ```

   Point `haidi.online` (DNS A record, or your local `hosts` file) at the new IP. If you use the IP
   directly, the server certificate must list it as a `subjectAltName`
   (`ca/credential/tls/ca-signing-for-zookeeper-server.cnf`).

4. Provisioning takes a few minutes after the instance shows as running. Check it over SSH:

   ```bash
   ssh -i <path-to-private-key> haidiid@<instance_public_ip>
   ```

   ```bash
   sudo tail -n 50 /var/log/cloud-init-output.log
   ```

   ```bash
   sudo systemctl status zookeeperd
   ```

   ```bash
   sudo ss -tlnp | grep ':443'
   ```

   ZooKeeper is ready when `zookeeperd` is `active (running)` and a Java process listens on port `443`.

## Connecting to ZooKeeper over Mutual TLS with `zkCli.cmd` (Windows)

The server accepts clients only on `secureClientPort=443`, using TLS 1.3 with `ssl.clientAuth=need`.
The plaintext port is disabled. Every client must therefore:

- **trust the self-signed root CA**, to verify the server certificate;
- **present a client certificate signed by the same CA**, to pass `ssl.clientAuth=need`;
- **connect by a name or IP listed in the server certificate's `subjectAltName`**: `haidi.online`,
  `localhost`, `127.0.0.1`, or the IP in `ca-signing-for-zookeeper-server.cnf`.

### 1. Prerequisites

- **Java 11 or newer**, with `JAVA_HOME` set (Java 25 works).
- **ZooKeeper 3.8.8 binaries**, the same version as the server, from
  `https://dlcdn.apache.org/zookeeper/zookeeper-3.8.8/apache-zookeeper-3.8.8-bin.tar.gz`.
  Extract them, for example to `C:\opt\apache-zookeeper-3.8.8-bin`:

  ```cmd
  tar -xzf apache-zookeeper-3.8.8-bin.tar.gz -C C:\opt
  ```

- **The client keystores**, signed by the same CA as the server:

  | File | Content | Password |
  |------|---------|----------|
  | `zookeeper-client/credential/tls/zookeeper-client.p12` | client key + cert (`extendedKeyUsage = clientAuth`) + CA chain | `zookeeper-client` |
  | `zookeeper-client/credential/tls/truststore.p12` | self-signed root CA (`trustedCertEntry`) | `ca` |

- **Name resolution:** `haidi.online` must resolve to the instance's public IP. For a quick local
  setup, add a line to `C:\Windows\System32\drivers\etc\hosts`, editing it as Administrator:

  ```text
  <instance_public_ip>  haidi.online
  ```

### 2. Create the client TLS configuration

Create `zookeeper-client/credential/tls/zkcli-tls.properties`. The `credential/` folder is ignored
by git, so these passwords stay local:

```properties
# use the Netty client: TLS is not supported by the default NIO client socket
zookeeper.clientCnxnSocket=org.apache.zookeeper.ClientCnxnSocketNetty
zookeeper.client.secure=true

# client identity presented to the server (ssl.clientAuth=need)
# use forward slashes: a backslash is an escape character in .properties files
zookeeper.ssl.keyStore.location=C:/Users/<you>/Workspace/cloud-terraform/zookeeper-client/credential/tls/zookeeper-client.p12
zookeeper.ssl.keyStore.password=zookeeper-client
zookeeper.ssl.keyStore.type=PKCS12

# the self-signed root CA used to verify the server certificate
zookeeper.ssl.trustStore.location=C:/Users/<you>/Workspace/cloud-terraform/zookeeper-client/credential/tls/truststore.p12
zookeeper.ssl.trustStore.password=ca
zookeeper.ssl.trustStore.type=PKCS12

# must match the server (ssl.protocol / ssl.enabledProtocols)
zookeeper.ssl.protocol=TLSv1.3
zookeeper.ssl.enabledProtocols=TLSv1.3
# required with TLSv1.3 only: ZooKeeper 3.8 default cipher suites are TLSv1.2 suites
zookeeper.ssl.ciphersuites=TLS_AES_256_GCM_SHA384,TLS_AES_128_GCM_SHA256,TLS_CHACHA20_POLY1305_SHA256

# keep true: the client checks that the -server host matches the server certificate's SANs
zookeeper.ssl.hostnameVerification=true
```

### 3. Connect

```cmd
set JAVA_HOME=C:\Program Files\BellSoft\Liberica JDK\25
```

```cmd
C:\opt\apache-zookeeper-3.8.8-bin\bin\zkCli.cmd -server haidi.online:443 -client-configuration C:/Users/<you>/Workspace/cloud-terraform/zookeeper-client/credential/tls/zkcli-tls.properties
```

A successful connection ends with `WatchedEvent state:SyncConnected` and the prompt
`[zk: haidi.online:443(CONNECTED) 0]`.

### 4. Send and read data

Run these at the `zkCli` prompt:

```text
create /demo "hello from windows"
ls /
get /demo
set /demo "updated over mTLS"
get -s /demo
delete /demo
quit
```

| Command | What it does |
|---------|--------------|
| `create /demo "..."` | creates the znode `/demo` with the given data |
| `ls /` | lists the children of the root znode; `demo` should be listed |
| `get /demo` | prints the data stored in `/demo` |
| `set /demo "..."` | replaces the data in `/demo` |
| `get -s /demo` | prints the data plus its stat (version, mtime, data length, ...) |
| `delete /demo` | removes the znode |
| `quit` | closes the session |

### 5. Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| Stays at `CONNECTING`, then `Session ... timed out` | Instance not ready, `zookeeperd` not running, or the wrong IP in DNS / `hosts`. Check the steps in "Rebuild the ZooKeeper EC2 instance". |
| `PKIX path building failed` / `unable to find valid certification path` | The client `truststore.p12` does not contain the CA that signed the server certificate, for example after reissuing the CA. Rebuild the truststore. |
| `No subject alternative names matching IP address ...` / `... DNS name ... found` | The `-server` host is not listed in the server certificate's `subjectAltName`. Connect by `haidi.online` or add the name/IP and re-sign. |
| `Received fatal alert: certificate_required` or `bad_certificate` | The client keystore is missing, has the wrong password, or the client cert is not signed by the server's trusted CA or lacks `clientAuth`. |
| `No appropriate protocol (protocol is disabled or cipher suites are inappropriate)` | `enabledProtocols=TLSv1.3` without TLSv1.3 cipher suites. Set `ssl.ciphersuites` on the server and `zookeeper.ssl.ciphersuites` on the client. |
| `Keystore was tampered with, or password was incorrect` | Wrong `keyStore.password` / `trustStore.password` in `zkcli-tls.properties`. |

## Kafka Broker EC2 Instance

The Kafka broker is the `aws_instance.main` resource in `kafka-broker/kafka-broker.tf` (module `kafka_broker`),
tagged `Name = kafka-0-vm` and `Version = 0.0.1`. Like the ZooKeeper server it is provisioned once, on first
boot, by the `kafka-broker/kafka-broker.tfl` user-data script, so rebuild it with
`terraform apply -replace=module.kafka_broker.aws_instance.main -var-file=local.tfvars` after changing anything
it installs.

- **Kafka 3.9.2** on Java 21. Kafka 4 no longer supports ZooKeeper, so `kafka_uri` must stay on a 3.x release.
- **Listener:** `SSL://0.0.0.0:443`, TLS 1.3 with `ssl.client.auth=required`, advertised as
  `kafka-0.haidi.online:443` (`kafka_advertised_host`).
- **ZooKeeper:** connects to the ZooKeeper Elastic IP on port `443` over mutual TLS 1.3, presenting the broker
  certificate.

### 1. Create the files read by `kafka-broker/kafka-broker.tf`

| File | Content |
|------|---------|
| `kafka-broker/credential/user/kafka-password.pass` | Kafka OS user password |
| `credential/ssh-public-key.pub` | SSH public key for the Kafka OS user (shared with ZooKeeper) |
| `kafka-broker/credential/tls/kafka-broker.p12` | broker keystore (key + cert + CA chain), password `kafka-broker` |
| `kafka-broker/credential/tls/truststore.p12` | CA truststore, password `ca` (same file as the ZooKeeper one) |

Create the broker key, sign it with the root CA and bundle it, from the repository root:

```bash
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 -out kafka-broker/credential/tls/kafka-broker.key
```

```bash
openssl req -new -key kafka-broker/credential/tls/kafka-broker.key -config kafka-broker/credential/tls/kafka-broker.cnf -out kafka-broker/credential/tls/kafka-broker.csr
```

```bash
openssl x509 -req -in kafka-broker/credential/tls/kafka-broker.csr -CA ca/credential/tls/ca.crt -CAkey ca/credential/tls/ca.key -CAserial ca/credential/tls/ca.srl -extfile ca/credential/tls/ca-signing-for-kafka-broker.cnf -sha384 -days 825 -out kafka-broker/credential/tls/kafka-broker.crt
```

```bash
openssl pkcs12 -export -name kafka-broker -inkey kafka-broker/credential/tls/kafka-broker.key -in kafka-broker/credential/tls/kafka-broker.crt -certfile ca/credential/tls/ca.crt -passout pass:kafka-broker -out kafka-broker/credential/tls/kafka-broker.p12
```

```bash
cp zookeeper-server/credential/tls/truststore.p12 kafka-broker/credential/tls/truststore.p12
```

### 2. Apply and point the advertised host at the broker

```bash
terraform apply -var-file=local.tfvars
```

```bash
terraform output kafka_instance_public_ip
```

Point `kafka-0.haidi.online` (DNS A record, or your local `hosts` file) at that IP. The broker has no
Elastic IP, so the address changes on every rebuild.

### 3. Check the broker over SSH

```bash
sudo systemctl status kafkad
```

```bash
sudo tail -n 50 /var/opt/kafka/log/kafka.log
```

Kafka is ready when `kafkad` is `active (running)` and the log shows `[KafkaServer id=0] started`.

## Kerberos Server EC2 Instance

The Kerberos server is the `aws_instance.main` resource in `kerberos-server/kerberos-server.tf` (module
`kerberos_server`), tagged `Name = <environment_tag>-<kerberos_name_tag>-vm0` (`local-kerberos-vm0`) and
`Version = <kerberos_version_tag>` (`0.0.1`). The three values are set in `local.tfvars`; `vm0` is hard-coded
in the module. It sits in the same public subnet and security group
as the ZooKeeper server and is reached on the pre-allocated Elastic IP `kerberos_eip_public_ip`
(`16.178.63.195`), which must already exist in the account and region.

The first-boot user-data script `kerberos-server/kerberos-server.tfl` replicates the ZooKeeper access setup
(the OS user `kerberos_username` with its password, the shared SSH public key and passwordless `sudo`), then
updates the system and installs `krb5-server`, `krb5-workstation` and `krb5-libs`. No realm or KDC is
configured yet, and the public security group does not open the Kerberos ports (88, 464, 749).

Files read by `kerberos-server/kerberos-server.tf`:

| File | Content |
|------|---------|
| `kerberos-server/credential/user/kerberos-password.pass` | Kerberos OS user password |
| `credential/ssh-public-key.pub` | SSH public key for the OS user (shared with ZooKeeper) |
| `kerberos-server/configuration/sudoers.d/kerberos` | sudoers rule installed as `/etc/sudoers.d/kerberos` |

```powershell
ssh haidiid@16.178.63.195
```

Rebuild it with `terraform apply -replace=module.kerberos_server.aws_instance.main -var-file=local.tfvars`
after changing the user-data script or the files it reads.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `aws_region` | AWS region to deploy resources | `string` | `"ap-southeast-2"` |
| `name` | Resource name prefix | `string` | `"main"` |
| `instance_type` | EC2 instance type (2 GiB RAM, amd64) | `string` | `"t3.small"` |
| `instance_root_volume_size` | Size of the root volume in GB | `number` | `15` |
| `instance_ami_id` | Optional AMI ID override | `string` | `null` |
| `key_name` | Optional SSH Key Pair name | `string` | `null` |
| `zookeeper_username` | Username for the ZooKeeper user | `string` | `"haidiid"` |
| `kafka_username` | Username for the Kafka OS user | `string` | `"haidiid"` |
| `kafka_uri` | Kafka binary tarball (3.x only) | `string` | Kafka 3.9.2 on `archive.apache.org` |
| `kafka_advertised_host` | Host name clients use to reach the broker | `string` | `"kafka-0.haidi.online"` |
| `kerberos_username` | Username for the Kerberos OS user | `string` | `"haidiid"` |
| `kerberos_eip_public_ip` | Pre-allocated Elastic IP for the Kerberos instance | `string` | `"16.178.63.195"` |
| `kerberos_instance_type` | EC2 instance type of the Kerberos instance (1 GiB RAM) | `string` | none, set in `local.tfvars` (`t3.micro`) |
| `environment_tag` | Environment component of the Name tag | `string` | none, set in `local.tfvars` |
| `kerberos_name_tag` | Service component of the Kerberos Name tag | `string` | none, set in `local.tfvars` |
| `kerberos_version_tag` | Version tag of the Kerberos instance | `string` | none, set in `local.tfvars` |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | ID of the created EC2 instance |
| `instance_public_ip` | Public IPv4 address assigned to the instance |
| `instance_public_dns` | Public DNS hostname of the instance |
| `instance_ami_id` | AMI ID used to launch the instance |
| `kafka_instance_id` | ID of the Kafka broker EC2 instance |
| `kafka_instance_public_ip` | Public IPv4 address of the Kafka broker instance |
| `kafka_instance_private_ip` | Private IPv4 address of the Kafka broker instance |
| `kafka_instance_public_dns` | Public DNS hostname of the Kafka broker instance |
| `kerberos_instance_id` | ID of the Kerberos server EC2 instance |
| `kerberos_instance_public_ip` | Elastic IP address of the Kerberos server instance |
| `kerberos_instance_private_ip` | Private IPv4 address of the Kerberos server instance |
| `kerberos_instance_public_dns` | Public DNS hostname of the Kerberos server instance |
