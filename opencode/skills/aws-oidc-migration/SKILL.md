---
name: aws-oidc-migration
description: Migrate a batman-configs service from static AWS access key/secret pairs to OIDC (IRSA-style web identity token) authentication. Load when asked to migrate a service to AWS OIDC, remove AWS access keys, or when working with deployment_base.yaml files that contain SECRET_AWS_ACCESS_KEY_ID / SECRET_AWS_SECRET_ACCESS_KEY. Triggers: "migrate to AWS OIDC", "remove AWS access keys", vault-init, AWS_WEB_IDENTITY_TOKEN_FILE, AWS_ROLE_ARN, IRSA.
---

# Skill: AWS OIDC Migration

Migrate a service in `batman-configs` from static AWS IAM keys (injected via
Vault into `vault-init`) to OIDC/IRSA-style web identity token authentication.
This mirrors the MongoDB OIDC migration that already happened; permissions on
AWS are already configured, this is purely a Kubernetes deployment change
(plus an app-side dependency check).

## When to use

The user asks to migrate a service (or several) to AWS OIDC. Known-good
reference implementations already in the repo: `lobby-api`, `faceit-connect`,
`notes`, `gateway-external-processing`, `drops-engine`, `drops-api`.

## Step 0 — Branch

Always start from a fresh branch off `origin/master`:

```bash
git fetch origin master
git checkout -b <branch-name> origin/master
```

## Step 1 — Locate the deployment files

```bash
find applications -maxdepth 2 -iname "*<service>*"
```

For each service, read:

- `base/deployment_base.yaml`
- `commons/deployment_common.yaml` (defines the generic `vault-init` container image/args — usually untouched)
- `overlays/prod/deployment.yaml` and `overlays/stage/deployment.yaml` (may add extra vault-init secrets, e.g. CSFLE)

Grep for what needs removing:

```bash
grep -n "AWS_ACCESS_KEY\|AWS_SECRET\|SECRET_AWS\|initContainers\|vault-init" base/deployment_base.yaml
```

## Step 2 — Remove the static AWS keys

In `base/deployment_base.yaml`, remove ONLY the AWS-specific env vars from
`vault-init`:

```yaml
- name: SECRET_AWS_ACCESS_KEY_ID
  value: "team-x/service?aws_access_key_id"
- name: SECRET_AWS_SECRET_ACCESS_KEY
  value: "team-x/service?aws_secret_access_key"
```

**Do NOT blindly delete the whole `vault-init` block.** Check first whether
`vault-init` fetches any OTHER secrets (e.g. `SECRET_MYSQL_DSN`,
`SECRET_MONGODB_CSFLE_*`, `SECRET_API_MIXPANEL_TOKEN`, etc. — check base AND
both overlays). Two cases:

- **Other secrets remain** → just delete the two `SECRET_AWS_*` lines, leave
  `vault-init` and its other env vars untouched.
- **AWS keys were the ONLY secrets** → the `vault-env` binary hard-crashes
  with `Did you forget to specify the SECRET_<...>` when it has zero
  `SECRET_*`/`SECRETFILE_*` vars. You MUST delete the whole `vault-init`
  initContainer via strategic-merge patch (list merge key is `name`):

  ```yaml
  initContainers:
  - $patch: delete
    name: vault-init
  ```

  Precedent for this exact pattern already exists in the repo, e.g.
  `applications/team-matchmaking/blocks-api/base/deployment_base.yaml`.

  ⚠️ This is the #1 mistake in this migration. If you skip AWS keys but
  leave no other secrets, and don't delete the container, pods will go
  `Init:CrashLoopBackOff` in production. If a migration already merged and
  is crash-looping, this is the first thing to check
  (`kubectl logs -n <ns> <pod> -c vault-init --previous`).

## Step 3 — Add the OIDC env vars

Add these to the **container** env (not vault-init), immediately after
`AWS_ACCOUNT_ID`/`AWS_REGION`/`ENV` — order matters because of `$(...)`
interpolation:

```yaml
- name: AWS_ACCOUNT_ID          # add if missing
  valueFrom:
    configMapKeyRef:
      key: aws.accountId
      name: general
- name: AWS_REGION               # add if missing
  valueFrom:
    configMapKeyRef:
      key: aws.region
      name: general
- name: K8S_SERVICE_ACCOUNT
  valueFrom:
    fieldRef:
      fieldPath: spec.serviceAccountName
- name: AWS_ROLE_ARN
  value: arn:aws:iam::$(AWS_ACCOUNT_ID):role/$(K8S_SERVICE_ACCOUNT)-$(ENV)
- name: AWS_WEB_IDENTITY_TOKEN_FILE
  value: /var/run/secrets/aws/serviceaccount/token
- name: AWS_ROLE_SESSION_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
```

Some services already have `AWS_ACCOUNT_ID`/`AWS_REGION` defined elsewhere in
the env list — don't duplicate them, just insert the four new vars
(`K8S_SERVICE_ACCOUNT`, `AWS_ROLE_ARN`, `AWS_WEB_IDENTITY_TOKEN_FILE`,
`AWS_ROLE_SESSION_NAME`) right after wherever `AWS_REGION` currently sits.

## Step 4 — Add the projected token volume

Add a `volumeMounts` entry to the container and a `volumes` entry at
`spec.template.spec` level:

```yaml
containers:
- name: <service>
  ...
  volumeMounts:
  - name: aws-iam-token
    mountPath: /var/run/secrets/aws/serviceaccount
    readOnly: true
volumes:
  - name: aws-iam-token
    projected:
      sources:
        - serviceAccountToken:
            audience: sts.amazonaws.com
            path: token
```

Kustomize strategic-merge combines this with any `volumes`/`volumeMounts`
already defined in `commons/deployment_common.yaml` (merge key is `name`), so
this is additive and safe.

## Step 5 — Verify with kustomize (mandatory, do not skip)

```bash
kubectl kustomize applications/<team>/<service>/overlays/prod  > /tmp/prod.yaml
kubectl kustomize applications/<team>/<service>/overlays/stage > /tmp/stage.yaml
```

For each rendered file, confirm:

```bash
grep -c "AWS_ROLE_ARN"   /tmp/prod.yaml   # expect 1
grep -c "aws-iam-token"  /tmp/prod.yaml   # expect 2 (volumeMount + volume)
grep -c "SECRET_AWS"     /tmp/prod.yaml   # expect 0
grep -A5 "name: vault-init" /tmp/prod.yaml  # if kept, confirm it still has >=1 SECRET_* var
```

Do this for both prod and stage overlays for every service being migrated.

## Step 6 — Check the app repo's dependencies (read-only, informational only)

The app source repo is a *different* repo from `batman-configs` — do not
edit it, only inspect it to flag risks in the MR description. It's usually a
sibling directory, e.g. `~/workspace/<service-name>` (find it, don't guess).

```bash
grep -E "gokit/activity|gokit/broker|mongoclient" go.mod
```

Requirements from the OIDC migration guide:

- `gokit/broker >= v0.40`
- `gokit/activity >= v0.2.0` (if used)
- `gokit/dbfactory/mongoclient/v2 >= v2.3.1` (fixes the driver swapping the
  k8s OIDC token for the AWS web identity token via
  `AWS_WEB_IDENTITY_TOKEN_FILE`)
- `mongoclient/v2 >= v2.4.1` if the app uses aggregation pipelines and any
  Mongo `_id` fields are decoded into Go `string` (BSONOptions bug in v2.4.0)

If any dependency is below threshold, **do not silently proceed** — call it
out explicitly in the MR description as a blocker for production rollout.
Below-threshold `gokit/broker` is extremely common; expect to flag it almost
every time.

## Step 7 — Commit, push, open a draft MR

Use the `commit` skill for the commit message and the `gitlab-mr` skill for
the MR description. Always call out in the MR:

- Which services/deployments were touched
- Whether `vault-init` was kept (with remaining secrets) or fully removed
- The dependency-version findings from Step 6, as a Breaking Changes item if
  anything is below threshold
- That no new configmap keys are required if `AWS_ACCOUNT_ID`/`AWS_REGION`
  already existed in the `general` configmap

Open as **draft** unless the user says otherwise, or unless this is a
hotfix for something already broken in production (see Step 8).

## Step 8 — If a previous OIDC migration is already live and broken

Symptom: pods stuck in `Init:CrashLoopBackOff` after an AWS OIDC migration
MR was merged.

```bash
kubectl get pods -n <namespace> -l app=<service>
kubectl describe pod -n <namespace> <pod>
kubectl logs -n <namespace> <pod> -c vault-init --previous
```

If the log says `Did you forget to specify the SECRET_<...>`, this is the
Step 2 mistake — go delete the `vault-init` initContainer entirely (see Step
2, case 2). Branch off latest `origin/master` (the broken change is already
merged), fix, and open a **non-draft** MR since production is actively
impacted — don't leave a live incident sitting in draft.

## Common mistakes checklist

- [ ] Deleted only the AWS lines but left `vault-init` with zero secrets → crash loop
- [ ] Forgot to add `AWS_ACCOUNT_ID`/`AWS_REGION` when they weren't already present
- [ ] Put the new env vars before `AWS_ACCOUNT_ID`/`ENV` are defined → `$(...)` interpolation breaks
- [ ] Didn't verify both `prod` and `stage` overlays with `kubectl kustomize`
- [ ] Didn't check the app repo's `gokit/broker`/`mongoclient` versions
- [ ] Edited the application source repo instead of just inspecting it (out of scope for `batman-configs` work unless explicitly asked)
