---
category: SAS Event Stream Processing
tocprty: 8
---

# Configure the SAS Event Stream Processing Operator for ESP Server Connectors

## Overview

The `$deploy/sas-bases/examples/sas-esp-operator/esp-server-connectors-config` directory contains files to configure the SAS Event Stream Processing Kubernetes Operator to include SAS Event Stream Processing connectors configuration.
For information, see [Overview to Connectors](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espca&docsetTarget=p1nhdjrc9n0nnmn1fxqnyc0nihzz.htm).

## Examples

The example files provided assume the following:

* `$deploy` refers to the directory that contains the deployment assets.
* The deployment assets for the order have been downloaded to the `$deploy` directory.
* The `$deploy` directory is the current directory.

## Installation

1. Create the `$deploy/sas-config/esp-server-connectors-config` directory. Copy the content from the `$deploy/sas-bases/examples/sas-esp-operator/esp-server-connectors-config` directory to the `$deploy/site-config/esp-server-connectors-config` directory.

2. The `$deploy/site-config/esp-server-connectors-config/secret.yaml` file contains a Kubernetes secret resource. The secret contains a value for the ESP Server `connectors.config` file content. The `connectors.config` value should be updated with SAS Event Stream Processing Server connector configuration parameters. For information, see [Setting Configuration Parameters in a Kubernetes Environment](https://documentation.sas.com/?docsetId=espca&docsetVersion=latest&docsetTarget=p1nhdjrc9n0nnmn1fxqnyc0nihzz.htm#n0v6ulkamlaxgan1ov1frvu4dxsf).

3. Make the following changes to the base kustomization.yaml file (`$deploy/kustomization.yaml`).

   * Add `$deploy/site-config/esp-server-connectors-config/secret.yaml` to the resources block.
   * Add `$deploy/site-config/esp-server-connectors-config/patchtransformer.yaml` to the transformers block.

   The references should look like this:

   ```yaml
   ...
   resources:
   ...
   - site-config/esp-server-connectors-config/secret.yaml
   ...
   transformers:
   ...
   - site-config/esp-server-connectors-config/patchtransformer.yaml
   ...
   ```

4. After you modify the `$deploy/kustomization.yaml` file, deploy the software using the commands described in [Deploy the Software](https://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p127f6y30iimr6n17x2xe9vlt54q.htm).

## Additional Resources

* After your deployment is complete, see [SAS Event Stream Processing: Using SAS Event Stream Processing Studio](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espstudio&docsetTarget=titlepage.htm) for information.
* To see an example SAS Event Stream Processing project, go to `$deploy/site-config/esp-server-connectors-config/project.xml`.
* For information about importing the project XML file into SAS Event Stream Processing Studio, see [Import a Project](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espstudio&docsetTarget=n0qhr0p800gs68n18wbp96pu7txq.htm).
* For information on running the imported project, see [Testing Models in SAS Event Stream Processing Studio](https://documentation.sas.com/?cdcId=espcdc&cdcVersion=default&docsetId=espstudio&docsetTarget=p0dki3jqunilnmn16e4eutvcq0dy.htm).
