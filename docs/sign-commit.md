# Checking signed commits with Flux CD

## Introduction

FluxCD provides the `GitRepository`  API, which defines a source to synchronize deployed resources with a Git
 repository revision. This API includes an optional field, `.spec.verify`, to enable the verification of Git commit
 signatures with a GPG key. This control aims to mitigate the risk of pushing malicious code from a compromised GitLab
 account. Indeed, commits signature allows to prove the authorship and to be sure that the code has not been tampered
 with. It is also needed for the sake of auditability and accountability, required when claiming High-Security Grade.

## How-to use GPG keys

### Configure your personal GPG Keys

[Sign commits with GPG (GitLab documention)](https://docs.gitlab.com/ee/user/project/repository/signed_commits/gpg.html)

> NOTE: This only works if the commit has been done on your local machine or server. Web IDE
 modification does not permit to sign commit with a GPG key.

Special case: merge commit when validating merge request on GitLab UI

> NOTE: Squash or merge actions with verified commit signature must be performed locally (not
 on GitLab UI)

### Configure a kustomization using GitRepository kind object

As mentioned in introduction, Flux CD rely on `GitRepository` and more specially `.spec.verify` to verify the
 authenticity of the commit.

First, we add the public key in a secret:

```bash
gpg --armor --export <KEY ID> > bot.asc
kubectl create secret generic pgp-public-keys --from-file=dev1.asc  -n sylva-units-preview -o yaml
```

This secret will be referenced in the `.spec.verify.secretRef` in the `GitRepository` definition

```yaml

  sylva-core:
    kind: GitRepository
    spec:
      url: https://gitlab.com/sylva-projects/sylva-core.git
      ref:
        branch: main
      verify:
        mode: HEAD
        secretRef:
          name: pgp-public-keys
```

Finally, when definition is applied only signed commits will be accepted:

```bash
kubectl apply -f podinfo.yaml
gitrepository.source.toolkit.fluxcd.io/podinfo created
```

```bash
kubectl describe gitrepository sylva-core -n sylva-units-preview
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Succeeded  9s    source-controller  verified signature of
          - commit '89d14c77df209699b289c7b837df54b79918f5d7' with key '7325B23EFA489F7E'
  Normal  NewArtifact  9s  source-controller  stored artifact for commit 'Add verify in helm release'
```

In case of not signed commit or not allowed signature, this error occurs:

```bash
Wait for Helm release to be ready
⠈⠁ GitRepository/sylva-units-preview/sylva-core - InvalidCommitSignature - signature verification of commit '89d14c77df209699b289c7b837df54b79918f5d7' failed: unable to verify Git commit: unable to verify
```

or via `kubectl` command:

```bash
kubectl describe gitrepositories sylva-core -n sylva-units-preview
...
Events:
  Type     Reason                  Age                From               Message
  ----     ------                  ----               ----               -------
  Warning  VerificationError       10m (x9 over 17m)  source-controller  PGP public keys secret error: secrets "pgp-public-keys" not found
  Warning  InvalidCommitSignature  4m20s              source-controller  signature verification of commit '89d14c77df209699b289c7b837df54b79918f5d7' failed: unable to verify Git commit: unable to verify payload with any of the given key rings

```

## Configure Sylva to verify signature of GitRepository objects

### Apply verification to all GitRepository objects

In the environment value file add the following lines:

```yaml

---
git_repo_spec_default:
  verify:
    mode: HEAD
    secretRef:
      name: pgp-public-keys
```

NB: The `mode` parameter can be defined as `HEAD`, `Tag` or `TagAndHEAD`.

### Apply verification for `sylva-core` unit

In the `environment-values/helm-release.yaml` file modify the GitRepository definition of `sylva-core` as below:

```yaml

---
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: sylva-core
  namespace: default
  labels:
    copy-from-bootstrap-to-management: ""
spec:
  interval: 120m
  ref:
    commit: CURRENT_COMMIT # Placeholder that will be replaced by bootstrap.sh and apply.sh commands
  url: SYLVA_CORE_REPO
  verify:
    mode: HEAD # or Tag or TadAndHEAD
    secretRef:
      name: pgp-public-keys
```

Add the PGP keys to the `pgp-public-keys` secret on the environment kustomization file.
Example `kubeadm-capo/kustomization.yaml`:

```yaml
...
secretGenerator:
- name: sylva-units-secrets
...
- name: pgp-public-keys
  behavior: merge
  options:
    disableNameSuffixHash: true
  files:
  - dev.asc
```

NB: replace `dev.asc` file name with the list of the public key files names to be verified.

## X.509 sign commits

Git and GitLab integrates X.509 sign commits. Flux CD GitRepository verification is not able to check the certificate.
Issue and development is ongoing to address this use case.

See [issue](https://github.com/go-git/go-git/issues/400)

## Use semantic-release to release Sylva

[Semantic-release](https://github.com/semantic-release/semantic-release) automates the whole package release workflow including: determining the next version number, generating the release notes, and publishing the package.

This bot can be used to create and sign Git release tag.

## Create a GPG Key for semantic-release bot

First, retrieve your bot information (name and email) using the GitLab API and group access token:

```bash
curl --header "PRIVATE-TOKEN: <group access token>" "https://gitlab.com/api/v4/user"
{"id":1,"username":"group_xxxx_bot_xxxx","name":"semantic-release","state":"active",...,
"email":"group_xxxx_bot_xxxx@noreply.gitlab.com",...,
"commit_email":"group_xxxx_bot_xxxx@noreply.gitlab.com"}
```

`name`, `commit_email` will be reuse to generate the GPG key and in the GitLab CI/CD environment variables for
 `semantic-release` job.

Generate the GPG key for the bot user:

```bash
gpg --gen-key
gpg (GnuPG) 1.4.23; Copyright (C) 2015 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection?
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 0
Key does not expire at all
Is this correct? (y/N) y

You need a user ID to identify your key; the software constructs the user ID
from the Real Name, Comment and Email Address in this form:
    "Heinrich Heine (Der Dichter) <heinrichh@duesseldorf.de>"

Real name: <bot name>
Email address: <bot commit email>
You selected this USER-ID:
    "<bot name> <bot commit email>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
You need a Passphrase to protect your secret key.
Enter passphrase:
```

> NOTE: Setting a passphrase is highly recommended even in automation use case. This
 passphrase can be stored as a GitLab Ci/CD variable using `masked` and `protected` mechanisms.

Then, import the public key on bot GitLab profile:

* Get the key id

```bash
 gpg --list-secret-keys --keyid-format LONG group_xxxx_bot_xxxx@noreply.gitlab.com
sec   4096R/<KEY ID> 2023-09-21
```

* Export GPG public key

```bash
 gpg --armor --export <KEY ID>
-----BEGIN PGP PUBLIC KEY BLOCK-----
...
-----END PGP PUBLIC KEY BLOCK-----

```

* Import public key on GitLab using API

```bash
curl --data-urlencode "key=-----BEGIN PGP PUBLIC KEY BLOCK-----\n\n...\n-----END PGP PUBLIC KEY 
BLOCK-----\n" \\n     --header "PRIVATE-TOKEN: <group access token>" "https://gitlab.com/api/v4/user/gpg_keys"
```

* Ensure public key is associated to bot account:

```bash
curl --header "PRIVATE-TOKEN: <group access token>" "https://gitlab.com/api/v4/user/gpg_keys"

[{"id":477,"key":"-----BEGIN PGP PUBLIC KEY BLOCK-----\n\...\n-----END PGP PUBLIC KEY BLOCK-----",
"created_at":"2023-09-21T08:49:19.712Z"}]
```

### Get private key from GPG key

As `semantic-release` will use GitLab CI pipelines to commit and sign, private GPG key secret is mandatory and will
 be added as a GitLab CI/CD variable (see below).

```bash
gpg --armor --export-secret-key <KEY ID>
```

### Configure GitLab CI/CD variables to sign commit using bot account and GPG Key

In order to commit and sign using `semantic-release`, first we need to update the template use in `.gitlab-ci.yml`:

```yaml
include:
  - project: 'to-be-continuous/semantic-release'
    ref: '3.5.1'
    file: '/templates/gitlab-ci-semrel.yml'
```

We can also add `@semantic-release/changelog` plugin at each new release to force a new signed commit from
 semantic-release bot. Example of `.releaserc`:

```yaml
debug: false
tagFormat: '${version}'
plugins: 
  - '@semantic-release/commit-analyzer'
  - '@semantic-release/release-notes-generator'
  - '@semantic-release/changelog'
  - '@semantic-release/gitlab'
  - '@semantic-release/git'
branches:
  - 'master'
  - 'main'
```

Then, required variables must be sets according to [sementic-release documentation](https://gitlab.kuleuven.be/to-be-continuous/semantic-release/-/tree/master/#signing-release-commits-with-gpg)

* `SEMREL_GPG_SIGNKEY`: Path to the GPG signkey exported. Declare as a masked project variable of File type.

* `GIT_AUTHOR_EMAIL`: Group bot user commiter email (i.e. `group_xxx_bot_xxx@noreply.gitlab.com`)

* `GIT_AUTHOR_NAME`: Group bot username (i.e. `semantic-release-bot`)

* `GIT_COMMITTER_EMAIL`: Group bot user commiter email (i.e. `group_xxx_bot_xxx@noreply.gitlab.com`)

* `GIT_COMMITTER_NAME`: Group bot username (i.e. `semantic-release-bot`)

## References

* [Flux CD GitRepository verification](https://fluxcd.io/flux/components/source/gitrepositories/#verification)
