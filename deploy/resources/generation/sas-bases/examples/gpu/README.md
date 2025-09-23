---
category: cas
tocprty: 15
---

# SAS GPU Reservation Service

## Overview

The SAS GPU Reservation Service aids SAS processes in resource sharing and
utilization of the Graphic Processing Units (GPUs) that are available in a
Kubernetes Pod. It is available by default in every SAS Cloud Analytic Services
(CAS) Pod, but it must be enabled in order to take advantage of the GPUs in
your cluster.

In MPP CAS server configurations, GPU resources are only used on the 
CAS worker nodes. Additional CAS server placement configuration can be
used to configure distinct node pools for CAS controller pods and CAS
worker pods.
This allows CAS controller pods to be scheduled on more economical nodes
while CAS worker pods are scheduled on nodes that provide GPU resources.

For instructions to set up distinct node pools for CAS Controllers and CAS
Workers, including configuration steps, 
see the README file located at 
`$deploy/sas-bases/overlays/cas-server/auto-resources/README.md`
(for Markdown format) or at 
`$deploy/sas-bases/docs/auto_resources_for_cas_server_for_sas_viya.htm`
(for HTML format).

The SAS GPU Reservation Service is supported on all of the supported cloud platforms.
If you are deploying on Microsoft Azure, refer to [Azure Configuration](#azure-configuration),
[Using Azure CLI or Azure Portal](#using-azure-cli-or-azure-portal),
[Using SAS Viya Infrastructure as Code for Microsoft Azure](#using-sas-viya-infrastructure-as-code-for-microsoft-azure),
and [Using the NVIDIA Device Plug-In](#using-the-nvidia-device-plug-in).
If you are deploying on a provider other than Microsoft Azure, refer to
[Installing the NVIDIA GPU Operator](#installing-the-nvidia-gpu-operator).

***Note:*** If you are using Kubernetes 1.20 and later and you choose to use Docker
as your container runtime, the NVIDIA GPU Operator is not needed.

## Azure Configuration

If you are deploying the SAS Viya platform on Microsoft Azure, before you enable CAS to
use GPUs, the Azure Kubernetes Service (AKS) cluster must be properly configured.

The `cas` node pool must be configured with a properly sized N-Series Virtual Machine (VM).
The N-Series VMs in Azure have GPU capabilities.

### Using Azure CLI or Azure Portal

If the `cas` node pool already exists, the VM node size cannot be changed.  The `cas` node
pool must first be deleted and then re-created to the proper VM size and node count.

**WARNING**: Deleting a node pool on an actively running SAS Viya platform deployment will cause any CAS sessions
to be prematurely terminated.  These steps should only be performed on an idle deployment.
The node pool can be deleted and re-created using the Azure portal or the Azure CLI.

```bash
az aks nodepool delete --cluster-name <replace-with-aks-cluster-name> --name cas --resource-group <replace-with-resource-group>

az aks nodepool add --cluster-name <replace-with-aks-cluster-name> --name cas --resource-group <replace-with-resource-group> --node-count <replace with node count> --node-vm-size "<replace with N-Series VM>" [--zones <replace-with-availability-zone-number>]
```

### Using SAS Viya Infrastructure as Code for Microsoft Azure

SAS Viya 4 Infrastructure as Code (IaC) for Microsoft Azure [(viya4-iac-azure)](https://github.com/sassoftware/viya4-iac-azure) contains Terraform scripts to provision Microsoft Azure Cloud infrastructure
resources required to deploy SAS Viya platform products.  Edit the terraform.tfvars file and change the
`machine_type` for the `cas` node pool to an N-Series VM.

```yaml
node_pools = {
  cas = {
    "machine_type" = "<Change to N-Series VM>"
  ...
  }
},
...
```

Verify the `cas` node pool was created and properly sized.

```bash
az aks nodepool list -g <resource-group> --cluster-name <cluster-name> --query '[].{Name:name, vmSize:vmSize}'
```

### Using the NVIDIA Device Plug-In

An additional requirement in a Microsoft Azure environment is that the
[NVIDIA device plug-in](https://docs.microsoft.com/en-us/azure/aks/gpu-cluster) must be
installed and configured. The example `nvidia-device-plugin-ds.yaml` manifest requires
the following addition to the `tolerations` block so that the plug-in will be scheduled on
to the CAS node pool.

```yaml
tolerations:
...
- key: workload.sas.com/class
  operator: Equal
  value: "cas"
  effect: NoSchedule
...
```

Create the `gpu-resources` namespace and apply the updated manifest to create the NVIDIA device plug-in DaemonSet.

```bash
kubectl create namespace gpu-resources
kubectl apply -f nvidia-device-plugin-ds.yaml
```

## Installing the NVIDIA GPU Operator

Beginning with Kubernetes version 1.20, Docker was deprecated as the default container runtime in favor
of the [ICO](https://opencontainers.org/)-compliant [containerd](https://kubernetes.io/blog/2017/11/containerd-container-runtime-options-kubernetes/#containerd).
In order to leverage GPUs using this new container runtime, install the
[NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/getting-started.html)
into the same cluster as the SAS Viya platform. After the NVIDIA GPU Operator is deployed into your
cluster, proceed with enabling the SAS GPU Reservation Service.

## Enable the SAS GPU Reservation Service

CAS GPU patch files are located at `$deploy/sas-bases/examples/gpu`.

1. Copy the appropriate patch files for your CAS Server configuration:

   * For SMP CAS servers and MPP CAS servers without distinct `cascontroller` and `casworker`
     node pool configurations, 
     copy `$deploy/sas-bases/examples/gpu/cas-gpu-patch.yaml`
     and `$deploy/sas-bases/examples/gpu/kustomizeconfig.yaml`
     to `$deploy/site-config/gpu/`.

   * For MPP CAS servers with distinct `cascontroller` and `casworker`
     node pool configurations, 
     copy `$deploy/sas-bases/examples/gpu/cas-gpu-patch-worker-only.yaml`
     and `$deploy/sas-bases/examples/gpu/kustomizeconfig.yaml`
     to `$deploy/site-config/gpu/`.

2. In the copied `cas-gpu-patch.yaml` or `cas-gpu-patch-worker-only.yaml` file, make the following changes:

   * Revise the values for the resource requests and resource
     limits so that they are the same and do not exceed the maximum number of GPU devices
     on a single node.

   * In the cas-vars section, consider whether you require
     a different level of information from the GPU process. The value for
     SASGPUD_LOG_TYPE can be info, json, debug, or trace.

     After you have made your changes, save and close the revised file.

3. After you edit the file, add the following references to the base
kustomization.yaml file (`$deploy/kustomization.yaml`):

   * Add the path to the selected `cas-gpu-patch` file used as the first entry in the transformers block.

   * Add the path to the `kustomizeconfig.yaml` file to the configurations block. If the configurations block does not exist yet, create it.

   Here are examples of these changes:

   ```yaml
   ...
   transformers:
   - site-config/gpu/cas-gpu-patch.yaml

   ...
   configurations:
   - site-config/gpu/kustomizeconfig.yaml
   ```

## Additional Resources

* For more information about using example files, see the
[SAS Viya Platform: Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

* For more information on CAS Workload Placement, see [Plan the Workload Placement
](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=p0om33z572ycnan1c1ecfwqntf24.htm)
