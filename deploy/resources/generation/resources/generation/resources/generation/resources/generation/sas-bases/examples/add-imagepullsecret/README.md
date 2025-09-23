---
category: mirrorRegistry
tocprty: 5
---

# Deploying with an Additional ImagePullSecret

## Overview

This overlay is used to apply an additional imagePullSecret. This overlay is
required for SAS Viya platform deployments on Red Hat OpenShift version 4.16
and later that use the OpenShift Container Registry as a mirror for their
deployment assets.

## Installation

Use these steps to apply the desired property to your SAS Viya platform deployment.

1. Create the `$deploy/site-config/add-imagepullsecret` directory and copy
   `$deploy/sas-bases/examples/add-imagepullsecret/configuration.env` into it.

2. Define the property in the configuration.env file. To define the property, update
   its token value as described in the comments in the file.

3. Add the following path to the resources block of the base kustomization.yaml file (`$deploy/kustomization.yaml`):

   ```yaml
   ...
   resources:
   ...
   - sas-bases/overlays/add-imagepullsecret/resources
   ...
   ```

4. Add the following entry to the configMapGenerator block of the base kustomization.yaml file:

   ```yaml
   ...
   configMapGenerator:
   ...
   - behavior: merge
     name: add-imagepullsecret-configuration
     envs:
       - site-config/add-imagepullsecret/configuration.env
   ...
   ```

5. Add the following entry to the transformers block of the base kustomization.yaml file:

   ```yaml
   ...
   transformers:
   ...
   - sas-bases/overlays/add-imagepullsecret/transformers.yaml
   ...
   ```
