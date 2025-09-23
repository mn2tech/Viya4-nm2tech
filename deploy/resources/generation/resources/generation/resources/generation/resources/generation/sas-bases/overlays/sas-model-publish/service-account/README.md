---
category: Model Publish service
tocprty: 5
---

# Configure SAS Model Publish Service to Add Service Account

**Note:** This guide applies **only** to SAS Viya platform
deployments in a **Red Hat OpenShift** environment.

In OpenShift, a security context constraint (SCC) is required for publishing objects
(models or decisions), as well as updating and validating published objects.
These actions create jobs within the cluster that
must run as user 1001 (sas), must have permission to mount volumes containing
container registry credentials, and must have access existing image pull secrets.
This README explains how to apply the `sas-model-publish` SCC to the appropriate
service accounts:

- Apply the SCC to the `sas-model-publish` service account
  to grant permissions to the sas-model-publish service.
- Apply the SCC to the `sas-model-publish-buildkit` and
  `sas-decisions-runtime-builder-buildkit` service accounts
  for publishing and updating.
- Apply the SCC to the `default` service account only if you expect
  validation to be run within that specific OpenShift cluster and namespace.
  For example, if the SAS Viya platform is deployed on AWS but the validation
  jobs are executed in an OpenShift cluster, the `sas-model-publish` SCC must
  be applied to the `default` service account in the namespace where validation runs.
  This ensures those jobs have the necessary permissions in that environment.
  If validation is not executed in OpenShift, applying the SCC to the `default`
  service account is not required.

## Prerequisites

### Granting SCC on an OpenShift Cluster

The `/$deploy/sas-bases/overlays/sas-model-publish/service-account` directory
contains a file to grant SCC to sas-model-publish and
sas-decisions-runtime-builder jobs.

A Kubernetes cluster administrator should add this SCC
to their OpenShift cluster prior to deploying the SAS Viya platform.
Use each of the following commands:

```yaml
kubectl apply -f sas-model-publish-scc.yaml
```

### Bind the SCC to a Service Account

After the SCC has been applied, you must link it to the appropriate service
accounts that will use it. Use the following commands:

```yaml
oc -n {{ NAME-OF-VIYA-NAMESPACE }} adm policy add-scc-to-user sas-model-publish -z
sas-model-publish

oc -n {{ NAME-OF-VALIDATION-NAMESPACE }} adm policy add-scc-to-user sas-model-publish -z
default

oc -n {{ NAME-OF-VIYA-NAMESPACE }} adm policy add-scc-to-user sas-model-publish -z
sas-model-publish-buildkit

oc -n {{ NAME-OF-VIYA-NAMESPACE }} adm policy add-scc-to-user sas-model-publish -z
sas-decisions-runtime-builder-buildkit
```

## Installation

Complete the deployment steps to apply the new settings. See
[Deploy the Software](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm)
in _SAS Viya Platform: Deployment Guide_.

**Note:** This overlay can be applied during the initial deployment of the
SAS Viya platform or after the deployment of the SAS Viya platform.

- If you are applying the overlay during the initial deployment of the SAS
  Viya platform, complete all the tasks in the README files that you want to
  use, then run `kustomize build` to create and apply the manifests.
- If the overlay is applied after the initial deployment of the SAS Viya
  platform, run `kustomize build` to create and apply the manifests.

## Post-Installation Tasks

1. Run the following command to verify whether the overlay has been applied:

   ```sh
   kubectl -n <name-of-namespace> get rolebindings -o wide | grep sas-model-publish
   ```

2. Verify that the sas-model-publish SCC is bound to sas-model-publish-buildkit
   and sas-decisions-runtime-builder-buildkit service accounts.
