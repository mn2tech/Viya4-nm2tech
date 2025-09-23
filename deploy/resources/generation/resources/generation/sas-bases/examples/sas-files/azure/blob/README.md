---
category: SAS Viya File Service
tocprty: 20
---

# Change Alternate Data Storage for SAS Viya Platform Files Service

## Overview

The SAS Viya platform files service uses PostgreSQL to store file metadata and content. However, In PostgreSQL upload time is slower for large objects. To overcome this limitation you can choose to store the file content in other data storage, such as Azure Blob Storage.
If you choose Azure Blob Storage as the storage database, then the file content is stored in Azure Blob Storage and file metadata remains in PostgreSQL.

## Configure SAS Viya File Service for Azure Blob Storage

The steps necessary to configure the SAS Viya platform files service to use Azure Blob Storage
as the back end for file content are listed below.

### Prerequisites

Before you start, create or obtain a storage account and record the name of the storage account and its access key.

### Installation

1. Copy the files in the `$deploy/sas-bases/examples/sas-files/azure/blob` directory to the
`$deploy/site-config/sas-files/azure/blob` directory. Create the target directory if it does
not already exist.

2. Create a file named `account_key` in the `$deploy/site-config/sas-files/azure/blob`
directory, and paste the storage account key into the file. The file should
only contain the storage account key.

3. In the `$deploy/site-config/sas-files/azure/blob/configmaps.yaml` file, replace
`{{ STORAGE-ACCOUNT-NAME }}` with the name of the storage account to be used by
the files service.

4. Make the following changes to the base kustomization.yaml file in the `$deploy`
directory.

   4.1. Add `sas-bases/overlays/sas-files` and `site-config/azure/blob` to the resources block.
   Here is an example:

   ```yaml
   resources:
   ...
   - sas-bases/overlays/sas-files
   - site-config/sas-files/azure/blob
   ...
   ```

   4.2. Add `site-config/azure/blob/transformers.yaml` and `sas-bases/overlays/sas-files/file-custom-db-transformer.yaml` to the transformers block.
   Here is an example:

   ```yaml
   transformers:
   ...
   - sas-bases/overlays/sas-files/file-custom-db-transformer.yaml
   - site-config/sas-files/azure/blob/transformers.yaml
   ...
   ```

5. Use the deployment commands described in [SAS Viya Platform Deployment Guide](http://documentation.sas.com/?cdcId=itopscdc&cdcVersion=default&docsetId=dplyml0phy0dkr&docsetTarget=titlepage.htm) to apply the new settings.