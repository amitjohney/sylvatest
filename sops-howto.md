# Manage secrets with Mozilla SOPS

## Introduction

SOPS (Secrets OPerationS) is a tool that can be used in conjunction with FluxCD to securely manage and encrypt sensitive information, such as passwords and API keys, within configuration files. To use SOPS in FluxCD, you would first need to install SOPS on your system and configure it to use the appropriate encryption keys.

Once SOPS is set up, you can use it to encrypt sensitive information in your configuration files. For example, you can use the sops command to encrypt a plain-text file containing a password, and then use the resulting encrypted file in your FluxCD configuration.

FluxCD can be configured to use SOPS by providing the necessary flags or environment variables while installing flux. You can use the --set flag to configure SOPS as the encryption provider for FluxCD.

After that you need to add the encrypted files in your Git repo and configure FluxCD to read from that repository. Once you push changes to the repository, FluxCD will automatically deploy the updated configuration to your cluster, using the encrypted information managed by SOPS.

## Install sops binary

SOPS (Secrets OPerationS) is a command-line tool that can be installed on various platforms. The process for installing SOPS will depend on your specific operating system and package manager. Here are some examples of how to install SOPS on different platforms:

Linux (RHEL/CentOS):
You can install SOPS by downloading the binary from the GitHub release page and placing it in your PATH.

```bash
curl -LO https://github.com/mozilla/sops/releases/download/v3.7.0/sops-v3.7.0_linux_amd64.tar.gz
tar xvf sops-v3.7.0_linux_amd64.tar.gz
sudo mv sops /usr/local/bin/
```

macOS:
You can install SOPS using the Homebrew package manager by running the following command:

```bash
brew install sops
```

Linux (Debian/Ubuntu):
You can install SOPS using the apt package manager by running the following commands:

```bash
apt-add-repository -y ppa:ansible/bubblewrap
apt update
apt install sops
```

Windows:
You can install SOPS using the Scoop package manager by running the following command:

```bash
scoop install sops
```

Windows:
You can install SOPS using the Chocolatey package manager by running the following command:

```bash
choco install sops
```

## Key encryption provider (KMS)

SOPS (Secrets OPerationS) is an open-source tool that supports several key encryption providers that can be used to encrypt and decrypt keys. The available key encryption providers are:

PGP: Uses PGP keys to encrypt and decrypt keys.
AwsKms: Uses the AWS Key Management Service (KMS) to encrypt and decrypt keys.
AzureKeyVault: Uses the Azure Key Vault to encrypt and decrypt keys.
GcpKms: Uses the Google Cloud Key Management Service (KMS) to encrypt and decrypt keys.
Local: Stores the encryption keys locally on the file system.
SecretsStore: Uses the Secrets Store API for Azure KeyVault and AWS SSM Parameter Store to encrypt and decrypt keys.

You can specify one or more key encryption providers, separated by a comma.

### PGP

PGP (Pretty Good Privacy) key refers to a public key encryption system that can be used as a key encryption provider to encrypt and decrypt keys. PGP is a widely used encryption standard that allows users to encrypt and sign data, as well as verify digital signatures. In SOPS, PGP keys can be used to encrypt the data encryption keys that SOPS uses to encrypt the configuration files.

When using PGP key as a key encryption provider in SOPS, you will need to have PGP keys in a supported format, such as ASCII-armored or binary, and you will also need to provide the key ID or fingerprint of the key you want to use.

For example, when encrypting a file using the sops command, you can specify the key ID or fingerprint of the PGP key to use:

```bash
sops -e --pgp <key-id-or-fingerprint> my-config-file.yaml
```

When using PGP keys, it's important to keep in mind that anyone who has access to the private key can decrypt the data, so it's important to properly secure the private key and make sure that only authorized individuals have access to it.

It's also important to note that PGP key is one of the key encryption providers that SOPS supports and you can use it alone or combined with other key encryption providers.

Now, Generate a PGP key with GPG (GPG is implementation of OpenPGP standard that can be used to generate PGP keys).

Link: https://www.gnupg.org/documentation/manuals/gnupg-devel/Unattended-GPG-key-generation.html

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

## What to encrypt

All the files storing sensitive information can be secured by using Mozilla SOPS, it mitigates the risk to leak this information on GitLab. Following files are good candidates to be secured:

- `git-secrets.env`: It stores your GitLab credentials which are typical examples of sensitive files.
- `environment-values/kubeadm-capo/secrets.yaml`: Stores capo user creds.
- `charts/sylva-units/values.yaml`: Stores capo user creds.
- TODO

## Encrypt file using Mozilla SOPS

Secure your sensitive info stored in for example `git-secrets.env` file with Mozilla SOPS:

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

## Decrypt the secrets

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

## How to have Flux controllers themselves handle the SOPS decryption

To use FluxCD to automatically decrypt files encrypted with SOPS, we need to set up the key encryption providers in SOPS (discussed above) and provide the necessary credentials. Below are the steps that we need to follow to have Flux controllers themselves handle the SOPS decryption:

- Install SOPS on your system, if it's not already installed.

- Choose one or more key encryption providers that you want to use with SOPS. Let's use PGP in our case.

- Set up the PGP key encryption provider. Create PGP private key , note key ID or fingerprint of the PGP key.

- Create a Kubernetes secret that holds the SOPS configuration and PGP private key credentials:
  Create a YAML file with the following content, which defines the Kubernetes secret:

```shell
apiVersion: v1
kind: Secret
metadata:
  name: sops-secret
  namespace: default
type: Opaque
stringData:
  SOPS_PGP_KEY: |
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    <Your PGP private key content>
    -----END PGP PRIVATE KEY BLOCK-----
```

Apply the YAML file to create the Kubernetes secret:

```shell
kubectl apply -f sops-secret.yaml
```

  or To create a secret with a PGP private key, you can also create it by saving the private key in a file and using "kubectl create secret" to create the secret using "--from-file".

- Update your FluxCD configuration to use the Kubernetes secret created in step 4 to automatically decrypt SOPS-encrypted files. To do so, add a patch with below content to your fluxCD kustomize file.
  
```shell
      env:
        - name: SOPS_PGP_KEY
          valueFrom:
            secretKeyRef:
              name: sops-secret
              key: SOPS_PGP_KEY
```

  This sets the SOPS_PGP_KEY environment variable to the value of the SOPS_PGP_KEY key in the sops-secret secret.

- Use the kustomize or kubectl apply command to apply the updated FluxCD configuration to your cluster.

- Verify that the FluxCD controllers are able to automatically decrypt the SOPS-encrypted files. You can do this by checking the logs or using kubectl get pods to see if any errors are reported.

It's important to keep in mind that you need to have the right permissions and access to the key encryption providers you selected to use SOPS. Additionally, you should also properly secure any sensitive information, such as credentials and private keys, stored in the Kubernetes secret.

NOTE: The exact process for using FluxCD to automatically decrypt SOPS-encrypted files can vary depending on the version of FluxCD, the key encryption providers you use, and the platform you are using.

## References

- https://github.com/mozilla/sops
- https://github.com/mozilla/sops#11stable-release
- https://github.com/mozilla/sops#43encrypt-or-decrypt-a-file-in-place
