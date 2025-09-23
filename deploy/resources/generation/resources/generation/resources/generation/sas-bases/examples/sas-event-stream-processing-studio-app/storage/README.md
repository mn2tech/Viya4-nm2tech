---
category: SAS Event Stream Processing
tocprty: 5
---

# Change the Storage Size for the SAS Event Stream Processing PersistentVolumeClaim

## Overview 

SAS Event Stream Processing creates a PersistentVolumeClaim (PVC) with a default 
storage capacity of 5 GB. Follow these instructions to change that value.

## Instructions 

1. Copy the file `$deploy/sas-bases/examples/sas-event-stream-processing-studio-app/storage/esp-storage-size-transformer.yaml`
to a location of your choice under `$deploy/site-config`, such as `$deploy/site-config/sas-event-stream-processing-studio-app/storage`.

2. Follow the instructions in the copied esp-storage-size-transformer.yaml
file to change the values in that file as necessary.

3. Add the full path of the copied file to the transformers block of the base
kustomization.yaml file (`$deploy/kustomization.yaml`). For example, if you
moved the file to `$deploy/site-config/backup`, you would modify the
base kustomization.yaml file like this:

```yaml
...
transformers:
...
- site-config/backup/esp-storage-size-transformer.yaml
...
```

After the base kustomization.yaml file is modified, deploy the software using
the commands described in [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).