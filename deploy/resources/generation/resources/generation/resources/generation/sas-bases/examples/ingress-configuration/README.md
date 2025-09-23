---
category: Ingress Configuration
tocprty: 1
---

# Configuring General Ingress Options

## Overview

You can use the examples found within `$deploy/sas-bases/examples/ingress-configuration/` to set general configuration values for Ingress resources.

The INGRESS_CLASS_NAME specifies the name of the IngressClass which SAS Viya Platform Ingress resources should use for this deployment. By default, SAS Viya Platform Ingress resources will use the `nginx` IngressClass. For more information about IngressClass resources, see [Ingress class](https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class) and [Using IngressClasses](https://kubernetes.github.io/ingress-nginx/user-guide/multiple-ingress/#using-ingressclasses).

The corresponding transformer file to override the ingressClassName field in Ingress resources is found at `sas-bases/overlays/ingress-configuration/update-ingress-classname.yaml`.

## Installation

Use these steps to apply the desired properties to your SAS Viya platform deployment.

1. Copy the `$deploy/sas-bases/examples/ingress-configuration/ingress-configuration-inputs.yaml` file to the location of your working container security overlay,
   such as `site-config/ingress-configuration/`.

2. Define the properties in the ingress-configuration-inputs.yaml file which match the desired configuration. To define a property, uncomment it and update its token value as described in the comments in the file.

3. Add the relative path of ingress-configuration-inputs.yaml to the resources block of the base kustomization.yaml file (`$deploy/kustomization.yaml`). Here is an example:

   ```yaml
   ...
   resources:
   ...
   - site-config/ingress-configuration/ingress-configuration-inputs.yaml
   ...
   ```

4. Add the relative path(s) of the corresponding transformer file(s) to the transformers block of the base kustomization.yaml file. There should be one transformer file added per option defined within the ConfigMap. Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/ingress-configuration/update-ingress-classname.yaml
   ...
   ```
