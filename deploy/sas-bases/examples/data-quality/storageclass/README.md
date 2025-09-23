---
category: SAS Data Quality
tocprty: 3
---

# Quality Knowledge Base for the SAS Viya platform

## Overview

This directory contains an example transformer that illustrates how to change the StorageClass and size of the PVC used to store the Quality Knowledge Base (QKB) in the SAS Viya platform.

## Installation
1.  Copy the file `sas-bases/examples/data-quality/storageclass/storage-class-transformer.yaml` and place it in your site-config directory.

2.  Replace the {{ QKB-STORAGE-CLASS }} value with your desired StorageClass. Note that the QKB requires that your storage class support the RWX accessMode.

3.  Also replace the {{ QKB-STORAGE-SIZE }} value with the size you wish to allocate to the QKB volume.  The recommended size is 8Gi.  Note that using a lower value may restrict your ability to add new QKBs to the SAS Viya platform; 1Gi is the absolute minimum required.

4.  After you edit the file, add a reference to it in the transformer block of the base kustomization.yaml file.

## Additional Resources

For more information about using example files, see the [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).

For more information about Kubernetes StorageClasses, please see the [Kubernetes Storage Class Documentation](https://kubernetes.io/docs/concepts/storage/storage-classes).


