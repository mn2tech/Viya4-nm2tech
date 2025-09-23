---
category: SAS Event Stream Processing
tocprty: 9
---

# Configuring an Analytic Store for SAS Event Stream Manager

## Overview

To configure SAS Event Stream Manager to use analytic store (ASTORE) 
files inside the application's container, a volume mount with a PersistentVolumeClaim (PVC)
of sas-microanalytic-score-astores is required in the deployment.

## Prerequisites

Before proceeding, ensure that a PVC is defined by the SAS Micro Analytic Service Analytic Store 
Configuration for the sas-microanalytic-score service.

Consult the $deploy/sas-bases/examples/sas-microanalytic-score/astores/README.md file.

## Installation

In the base kustomization.yaml file in the $deploy directory, add 
sas-bases/overlays/sas-event-stream-manager-app/astores/astores-transformer.yaml to the 
transformers block. The reference should look like this:

```
...
transformers:
...
- sas-bases/overlays/sas-event-stream-manager-app/astores/astores-transformer.yaml
...
```

After the base kustomization.yaml file is modified, deploy the software using  
the commands described in [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm).