---
category: SAS Event Stream Processing
tocprty: 3
---

# Adding Global Configuration Settings for SAS Event Stream Processing Projects

## Overview

Use the `$deploy/sas-bases/examples/sas-esp-operator/espconfig/espconfig-properties.yaml` and `$deploy/sas-bases/examples/sas-esp-operator/espconfig/espconfig-env-variables.yaml` files to set default settings and environment variables for the SAS Event Stream Processing Kubernetes Operator and all SAS Event Stream Processing servers that start within a Kubernetes environment.

Each default setting and environment variable that is described in these example files represents optional settings that enable you to change the default settings and environment variables.
If no configuration changes are required, do not add these example files to your `kustomization.yaml` file.

## Prerequisites

By default, each default setting or environment variable in the example files is commented out.
Start by determining which of the commented settings or environment variables you intend to set.
The following list describes the settings and environment variables that can be added and provides information about how to set them.

* `espconfig-properties.yaml`:

  * Determine the `server.disableTrace` value.
    * Use `"true"` to avoid log injection.
    * For more information, refer to the SAS Event Stream Processing documentation for [ESP Server Configuration Properties](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espxmllayer&docsetTarget=p1r993p8bj4upxn1otx3e9ay5fcr.htm#p01zy1yfqm1w9qn167rxh2i2kegf)

  * Determine the `server.mas-threads` value.
    * This is the number of SAS Micro Analytic Service threads that should be used across all CPUs.
    * Use `"0"` for one thread per CPU.
    * For more information, refer to the SAS Event Stream Processing documentation for [ESP Server Configuration Properties](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espxmllayer&docsetTarget=p1r993p8bj4upxn1otx3e9ay5fcr.htm#p01zy1yfqm1w9qn167rxh2i2kegf)

  * Determine the `server.store-location` value.
    * This is the absolute path to the directory of SAS Micro Analytic Service stores.
    * This location must be available through a persistent volume.
    * For more information, refer to the SAS Event Stream Processing documentation for [ESP Server Configuration Properties](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espxmllayer&docsetTarget=p1r993p8bj4upxn1otx3e9ay5fcr.htm#p01zy1yfqm1w9qn167rxh2i2kegf)

  * Determine the `server.loglevel` value.
    * This is a comma-separated list of key-value pairs to specify the logging levels.
    * You can set the logging level for individual SAS Event Stream Processing server contexts.
      For example, `"DF.ESP=trace,DF.ESP.AUTH=info"`.
    * For more information, refer to the SAS Event Stream Processing documentation for [Logging](https://go.documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espts&docsetTarget=n07870q147jx1gn1coobju0073gd.htm&locale=en).

  * Determine the `server.trace` value.
    * This is the trace format and may be one of the following: `XML`, `JSON`, or `CSV`.
    * For more information, refer to the SAS Event Stream Processing documentation for [ESP Server Configuration Properties](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espxmllayer&docsetTarget=p1r993p8bj4upxn1otx3e9ay5fcr.htm#p01zy1yfqm1w9qn167rxh2i2kegf)

  * Determine the `server.badevents` value.
    * A bad event is one that cannot be processed because of a computational failure.
    * This is the absolute path to the file to which bad events are written.
    * This location must be available through a persistent volume.
    * For more information, refer to the SAS Event Stream Processing documentation for [ESP Server Configuration Properties](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espxmllayer&docsetTarget=p1r993p8bj4upxn1otx3e9ay5fcr.htm#p01zy1yfqm1w9qn167rxh2i2kegf)

  * Determine the `server.plugins` value.
    * This is a comma-separated list of user-defined and dynamically loaded plug-ins (functions) to use.
    * For more information, refer to the SAS Event Stream Processing documentation for [ESP Server Configuration Properties](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espxmllayer&docsetTarget=p1r993p8bj4upxn1otx3e9ay5fcr.htm#p01zy1yfqm1w9qn167rxh2i2kegf)

  * Determine the `server.pluginsdir` value.
    * This is the absolute path to the directory to search for user-defined and dynamically loaded plug-ins.
    * This location must be available in a persistent volume.
    * For more information, refer to the SAS Event Stream Processing documentation for [ESP Server Configuration Properties](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espxmllayer&docsetTarget=p1r993p8bj4upxn1otx3e9ay5fcr.htm#p01zy1yfqm1w9qn167rxh2i2kegf)

  * Determine the maximum Kubernetes resource limits that may be allocated to all SAS Event Stream Processing server Kubernetes pod and horizontal pod autoscaling resources.
    * Determine the `maxReplicas` value.
      * This is the maximum number of Kubernetes pods that may be allocated to a SAS Event Stream Processing server.
      * For more information, refer to the Kubernetes documentation for [Deployment Replicas](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#replicas) and [ReplicaSet Replicas](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/#replicas).
    * Determine the `maxMemory` value.
      * This is the maximum amount of memory resources that may be allocated to a SAS Event Stream Processing server.
      * For more information, refer to the Kubernetes documentation for [Memory resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-memory).
    * Determine the `maxCpu` value.
      * This is the maximum amount of CPU resources that may be allocated to a SAS Event Stream Processing server.
      * For more information, refer to the Kubernetes documentation for [CPU resource units](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#meaning-of-cpu).
    * For more information, refer to the Kubernetes documentation for [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) and [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).

* `espconfig-env-variables.yaml`:

  * The following environment variables are specified in the example:

    * `DFESP_QKB` - Determine the absolute path to the share directory under the SAS Data Quality installation.
    * `DFESP_QKB_LIC` - Determine the absolute path to the file of the SAS Data Quality license.
    * `LD_LIBRARY_PATH` - Determine paths to append to `LD_LIBRARY_PATH`.

  * This example transformer enables you to leverage additional content that is located in a mounted path, such as `/mnt/path/to/file`.

  * You can add any other environment variable that is not included in this file.

## Installation

1. Copy the example files from the `$deploy/sas-bases/examples/sas-esp-operator/espconfig` directory to the `$deploy/site-config/sas-esp-operator/espconfig` directory.
   Create the destination directory if it does not exist.

2. Use the `$deploy/site-config/sas-esp-operator/espconfig/espconfig-properties.yaml` file to specify custom SAS Event Stream Processing default settings.

   For each SAS Event Stream Processing default setting that you intend to use, uncomment the `op`, `path`, and `value` lines that are associated with the setting.
   Then replace the `{{ VARIABLE-NAME }}` variable with the desired value.

   Here are some examples:

   ```yaml
   ...
     - op: add
       path: /spec/espProperties/server.disableTrace
       value: "true"
   ...
     - op: add
       path: /spec/espProperties/server.loglevel
       value: esp=trace
   ...
     - op: replace
       path: /spec/limits/maxReplicas
       value: "2"
   ...
   ```

3. Use the `$deploy/site-config/sas-esp-operator/espconfig/espconfig-env-variables.yaml` file to specify custom SAS Event Stream Processing default environment variables.

   For each SAS Event Stream Processing default environment variable that you intend to use, uncomment the `op`, `path`, `value`, `name`, and `value` lines that are associated with the environment variable.
   Then replace the `{{ VARIABLE-NAME }}` variable with the desired value.

   If you would like to include additional environment variables that are not in the example file, add new sections for them after the provided examples.

   Here are some examples:

   ```yaml
   ...
     - op: add
       path: /spec/projectTemplate/deployment/spec/template/spec/containers/0/env/-
       value:
         name: DFESP_QKB_LIC
         value: /mnt/data/sas/data/quality/license
   ...
     - op: add
       path: /spec/projectTemplate/deployment/spec/template/spec/containers/0/env/-
       value:
         name: CUSTOM_ENV_VAR_NUMBER
         value: "1234"
     - op: add
       path: /spec/projectTemplate/deployment/spec/template/spec/containers/0/env/-
       value:
         name: CUSTOM_ENV_VAR_FLAG
         value: "true"
   ...
   ```

4. Add `site-config/sas-esp-operator/espconfig/espconfig-properties.yaml` and/or `site-config/sas-esp-operator/espconfig/espconfig-env-variables.yaml` to the transformers block of the base `kustomization.yaml` file.

   Here is an example:

   ```yaml
   ...
   transformers:
   ...
   - site-config/sas-esp-operator/espconfig/espconfig-properties.yaml
   - site-config/sas-esp-operator/espconfig/espconfig-env-variables.yaml
   ...
   ```

After the base `kustomization.yaml` file is modified, deploy the software using
the commands that are described in [SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).
