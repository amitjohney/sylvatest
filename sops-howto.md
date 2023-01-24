# Manage secrets with Mozilla SOPS

## Install sops binary

 Install the latest stable release of SOPS from https://github.com/mozilla/sops/releases.

```bash
wget https://github.com/mozilla/sops/releases/download/v3.7.3/sops_3.7.3_amd64.deb
sudo dpkg -i sops_3.7.3_amd64.deb
```

## Generate a PGP key with GPG

https://www.gnupg.org/documentation/manuals/gnupg-devel/Unattended-GPG-key-generation.html

```bash
$ gpg --generate-key --batch <<EOF
%no-protection
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Real: Joe Tester
Name-Comment: sops key
Name-Email: joe@foo.bar
EOF
```

Retrieve the GPG key fingerprint (second row of the sec column):

```bash
$ gpg --list-secret-keys "Joe Tester"
sec   rsa4096 2023-01-06 [SCEA]
      89C54D2FDE4B50263B1652F23E79A69E0A0BF323
uid          [  ultime ] Joe Tester (sops key) <joe@foo.bar>
ssb   rsa4096 2023-01-06 [SEA]
```

Store the key fingerprint as an environment variable:

```bash
export KEY_FP=89C54D2FDE4B50263B1652F23E79A69E0A0BF323
```

## Encrypt file using Mozilla SOPS

All the files storing sensitive information can be secured by using Mozilla SOPS,  it mitigates the risk to leak this information on GitLab. The files `git-secrets.env`, which stores your GitLab credentials, are typical examples of sensitive files:

```yaml
# These secrets will be used by the GitRepository of the telco-cloud-init HelmRelease
# It is highly recommended to encrypt this file with SOPS
username=GIT_USERNAME
password=GIT_TOKEN
```

Secure your GitLab password, stored in `git-secrets.env`, with Mozilla SOPS:

```shell
sops --pgp $KEY_FP --in-place --encrypted-regex 'password' --encrypt git-secrets.env 
```

The generated output will look something like this:

```yaml
# These secrets will be used by the GitRepository of the telco-cloud-init HelmRelease
# It is highly recommended to encrypt this file with SOPS
username=GIT_USERNAME
password=ENC[AES256_GCM,data:gaLx4x+rFvoY,iv:5k0vIJncMVkCkM2kodH0drXO2mvZ/p7ysJyRKS7t8Zc=,tag:sAlAkL6J2Kn/Rqp+vYHFUg==,type:str]
sops_pgp__list_0__map_enc=-----BEGIN PGP MESSAGE-----\n\nhQIMAwdWdd0IkREPAQ/8CwWiRxVMRUxqqCiNjkd2IyJSeG58IVHZo/csjmE2Aw3s\nOix25Mm1EE933U/WU0ma...7X0g3zk1U+FkQLAIZpd+WDNKT0CdKfz7rpaAk/vUTSalHq\n=mgLX\n-----END PGP MESSAGE-----\n
sops_lastmodified=2023-01-06T15:10:45Z
sops_version=3.7.3
sops_pgp__list_0__map_created_at=2023-01-06T15:10:45Z
sops_pgp__list_0__map_fp=89C54D2FDE4B50263B1652F23E79A69E0A0BF323
sops_mac=ENC[AES256_GCM,data:gjqo6nZYucHesK767fzT7o4uwXuRF3yhYhJJpTf0bynNO9s3ZK/Mn5W0n96/bX3WlUg88j7nTgCkzkgp8Uu/2W9BMQodxPv2SAT6LwQSNXzE/1wKMLgmISC1gyzEqE+adv3sGCAC6rostziQx2Rc2LJ9Pjo3LRToGGd/5FpokDE=,iv:kUikWXDeS5G5NYiwJ/WcmhvEmcoCa/CDhjCdDl5PlEk=,tag:POWvlTKs5YPPJwrkVpqsBA==,type:str]
sops_encrypted_regex=password
```

Decrypt the secrets file before launching a deployment:

````shell
sops --in-place --decrypt git-secrets.env
````

## Bulk encryption/decryption

There is one `git-secrets.env` file per environment, so, when working on several environments, it may be worth to blindly encrypt all `git-secrets.env` files:

```shell
find capi-bootstrap/ -name git-secrets.env -exec sops --pgp $KEY_FP --in-place --encrypted-regex 'password' --encrypt {} \;
```

Then, to decrypt all `git-secrets.env` files:

```shell
find  capi-bootstrap/ -name git-secrets.env -exec sops --in-place --decrypt {} \;
```

## References

- https://github.com/mozilla/sops
- https://github.com/mozilla/sops#11stable-release
- https://github.com/mozilla/sops#43encrypt-or-decrypt-a-file-in-place
