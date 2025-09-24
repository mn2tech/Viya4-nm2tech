# SAS Viya 4 Deployment on AWS EKS

This repository contains the configuration and deployment files for SAS Viya 4 on AWS EKS.

## Project Status

✅ **MAJOR PROGRESS ACHIEVED** - Core infrastructure issues resolved!

### Completed Tasks

1. **✅ EBS CSI Driver**: Fixed credentials issue using IAM Roles for Service Accounts (IRSA)
2. **✅ EFS CSI Driver**: Installed and configured with IRSA for shared storage
3. **✅ Storage Configuration**: Created wildcard storage class using EFS for ReadWriteMany volumes
4. **✅ PostgreSQL Operator**: Fixed CrashLoopBackOff by resolving missing CRD and certificate issues
5. **✅ SAS Viya Deployment**: Status improved from FAILED to PENDING

### Current Issue

**Resource Constraints**: Core infrastructure pods (consul, rabbitmq, redis) are in Pending state due to insufficient CPU resources on cluster nodes.

**Current Status**: Scaling down non-critical SAS services to free up cluster resources.

## Key Files

### AWS IAM and Storage Configuration
- ebs-csi-driver-trust-policy.json - IAM trust policy for EBS CSI driver
- efs-csi-driver-trust-policy.json - IAM trust policy for EFS CSI driver  
- ebs-csi-deployment-patch.yaml - Patch to remove static AWS credentials from EBS CSI driver
- efs-storage-class.yaml - EFS-backed storage class for ReadWriteMany volumes

### SAS Viya Configuration
- deploy/ - Main SAS Viya deployment configuration
- deploy-sasdeployment.yaml - SAS deployment manifest
- site-image-pull-secret.yaml - Container registry authentication

## Recent Progress

### Storage Resolution
- Problem: PVCs were requesting ReadWriteMany with EBS (ReadWriteOnce only)
- Solution: Deployed EFS CSI driver and created wildcard storage class
- Result: All shared storage PVCs now bound successfully

### PostgreSQL Operator Fix
- Problem: Missing PostgresCluster CRD due to annotation size limits
- Solution: Used kubectl apply --server-side to install large CRD
- Result: PostgreSQL operator now running without crashes

### Resource Optimization
- Problem: Insufficient CPU resources preventing core infrastructure scheduling
- Action: Scaled down 25+ non-critical SAS services
- Status: In progress - monitoring for resource availability

## Next Steps

1. Complete resource scaling until consul/rabbitmq/redis can schedule
2. Monitor core infrastructure pods for successful scheduling
3. Watch SAS Viya deployment progress from PENDING to RUNNING
4. Gradually restore services as cluster stabilizes

---

Last Updated: September 23, 2025
Status: Core infrastructure deployment in progress
