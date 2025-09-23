---
category: security
tocprty: 12
---

# Configuring Ingress for Rate Limiting

## Overview

You can use the examples found within `$deploy/sas-bases/examples/security/web/rate-limiting` to enforce rate-limiting at the ingress-nginx controller for SAS Viya platform endpoints. The properties are applied to all Ingress resources deployed with the SAS Viya platform. If you are using any external load balancers or API gateways, enforcing rate-limiting with ingress-nginx is not optimal. Instead, enforce rate limiting through external technology. To read more about the available options in ingress-nginx, see https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#rate-limiting.

If you are deploying on Red Hat OpenShift, you must enforce rate-limiting at the OpenShift router instead. The properties are applied to all Route resources deployed with the SAS Viya platform. To read more about the available options in OpenShift, see https://docs.openshift.com/container-platform/4.15/networking/routes/route-configuration.html#nw-route-specific-annotations_route-configuration.

## Installation

### ingress-nginx

Use these steps to apply the desired properties to your SAS Viya platform deployment.

1. Copy the `$deploy/sas-bases/examples/security/web/rate-limiting/ingress-nginx-configmap-inputs.yaml` file to the location of your working container security overlay,
   such as `site-config/security/web/`.

2. Define the properties in the ingress-nginx-configmap-inputs.yaml file which match the desired configuration. To define a property, uncomment it and update its token value as described in the example file.

3. Add the relative path of ingress-nginx-configmap-inputs.yaml to the resources block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

   ```yaml
   ...
   resources:
   ...
   - site-config/security/web/rate-limiting/ingress-nginx-configmap-inputs.yaml
   ...
   ```

4. Add the relative path(s) of the corresponding transformer file(s) to the transformers block of the base kustomization.yaml file. There should be one transformer file added per property defined within the ConfigMap. Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/security/web/rate-limiting/update-ingress-nginx-limit-rps.yaml
   - sas-bases/overlays/security/web/rate-limiting/update-ingress-nginx-limit-burst-multiplier.yaml
   ...
   ```

### OpenShift

When deploying to Red Hat OpenShift, use these steps to apply the desired properties to your SAS Viya platform deployment. Do not use the steps for the ingress-nginx controller.

1. Copy the `$deploy/sas-bases/examples/security/web/rate-limiting/route-configmap-inputs.yaml` file to the location of your working container security overlay,
   such as `site-config/security/web/rate-limiting`.

2. Define the properties in the route-configmap-inputs.yaml file which match the desired configuration. To define a property, uncomment it and update its token value as described in the example file.

3. Add the relative path of route-configmap-inputs.yaml to the resources block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

   ```yaml
   ...
   resources:
   ...
   - site-config/security/web/rate-limiting/route-configmap-inputs.yaml
   ...
   ```

4. Add the relative path(s) of the corresponding transformer file(s) to the transformers block of the base kustomization.yaml file. There should be one transformer file added per property defined within the ConfigMap. Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/security/web/rate-limiting/update-route-rate-limit-connections.yaml
   - sas-bases/overlays/security/web/rate-limiting/update-route-rate-limit-connections-rate-http.yaml
   - sas-bases/overlays/security/web/rate-limiting/update-route-rate-limit-connections-rate-tcp.yaml
   ...
   ```
