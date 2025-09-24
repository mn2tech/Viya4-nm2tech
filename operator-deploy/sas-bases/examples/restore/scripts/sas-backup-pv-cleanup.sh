#!/bin/bash
LOG_FILE=""
TIMEOUT=600

function display_usage() {
  echo
  echo "********************************************************************************"
  echo
  echo "Execute sas-backup-pv-cleanup for cleaning up the PVCs"
  echo "The script should be executed for the same namespace where the restore operation has been performed."
  echo
  echo "Usage:"
  echo "./sas-backup-pv-cleanup.sh [namespace] [pvc_list]"
  echo
  echo "Arguments:"
  echo " namespace   : A Kubernetes namespace where the required operation should be performed."
  echo " pvc_list    : A comma separated string of pvcs."
  echo
  echo
  echo 'Example for Remove operation : ./sas-backup-pv-cleanup.sh viya04 "cas-default-data,cas-default-permstore"  '
  echo
  echo "********************************************************************************"
  echo
}

function log_file_creation(){
  LOG_FILE_PATH="/tmp/"
  LOG_FILE_NAME="sas-backup-pv-cleanup"
  LOG_FILE="${LOG_FILE_PATH}${LOG_FILE_NAME}_$(date "+%Y%m%d-%H.%M.%S").log"
  touch "${LOG_FILE}"
}

function remove(){
    random_string=$(printf '%s' "$(echo "$RANDOM" | md5sum)" | cut -c 1-7)

   # Fetch all valid PVCs in the namespace with label sas.com/backup-role=provider
   existing_pvcs=$(kubectl get pvc -n "$namespace" -l 'sas.com/backup-role=provider' -o jsonpath='{.items[*].metadata.name}')

   # Validate that each PVC in the pvc_list exists in the namespace
    for pvc in "${pvcs[@]}"; do
      # shellcheck disable=SC2076
      if [[ ! " ${existing_pvcs} " =~ " ${pvc} " ]]; then
       echo Error: PVC "$pvc" is not valid for cleaning, namespace "$namespace". Exiting.
       echo Error: PVC "$pvc" is not valid for cleaning, namespace "$namespace". Exiting. >> "${LOG_FILE}"
       exit 1
      fi
    done
    # Filter PVCs
    purge_index=1
    pvc_mounts=()
    for pvc in "${pvcs[@]}"
    do
      if [[ "$pvc" == *"backup"* || "$pvc" == *"transfer"* ]]; then
        echo Error: You are using trying to clean backup or transfer PVC aborting the operation
        echo Error: You are using trying to clean backup or transfer PVC aborting the operation >> "${LOG_FILE}"
        exit 1
      else
        pvc_mounts+=("$pvc:purge${purge_index}")
        ((purge_index++))
      fi
    done

    if [ "${#pvc_mounts[@]}" -eq 0 ]; then
      echo "Error: No valid PVCs found for mounting." | tee -a "${LOG_FILE}"
      exit 1
    fi

    # remove cas volume & mounts from copy-pv cronjob as they are the placeholder and having dummy pvc names
    # List of volumes to remove
    volumes=("cas-data" "cas-permstore")

    for volumename in "${volumes[@]}"; do
      removeVolume "$volumename"
    done

    # Dynamically add PVCs as volumes and mount them
    for mount in "${pvc_mounts[@]}"
    do
      pvc_name=${mount%%:*}
      volume_name=${mount##*:}
      kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[
        {"op": "add", "path": "/spec/jobTemplate/spec/template/spec/volumes/-", "value": {"name": "'"${volume_name}"'", "persistentVolumeClaim": {"claimName": "'"${pvc_name}"'"}}},
        {"op": "add", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/-", "value": {"name": "'"${volume_name}"'", "mountPath": "/'"${volume_name}"'"}}
      ]' >> "${LOG_FILE}"
    done

    # Create cleanup job
    kubectl create job -n "${namespace}" --from=cronjob/sas-backup-pv-copy-cleanup-job sas-backup-pv-cleanup-"${random_string}" --dry-run=client -o yaml | \
    kubectl set env --dry-run=client --local=true -c "sas-backup-pv-copy-cleanup-job" SAS_BACKUP_AGENT_START_MODE="REMOVE" -o=yaml -f - | \
    kubectl apply -f -  >> "${LOG_FILE}"

    REMOVE_FLAG=0
    running_pod_count=0
    while (( SECONDS < TIMEOUT ));
    do
      if [ "${running_pod_count}" -ge 1 ]; then
         break
      fi
      job_name="sas-backup-pv-cleanup-${random_string}"
      count_succeeded=$(kubectl get pods -n "${namespace}" --field-selector="status.phase=Succeeded" -l job-name="${job_name}" --output json  | jq -j '.items | length')
      count_running=$(kubectl get pods -n "${namespace}" --field-selector="status.phase=Running" -l job-name="${job_name}" --output json  | jq -j '.items | length')
      count_failed=$(kubectl get pods -n "${namespace}" --field-selector="status.phase=Failed" -l job-name="${job_name}" --output json  | jq -j '.items | length')

      running_pod_count=$((running_pod_count + count_succeeded + count_running + count_failed))
      echo Waiting for all pods to be ready. >> "${LOG_FILE}"
      echo Current succeeded pod count: "${count_succeeded}" >> "${LOG_FILE}"
      sleep 5
    done

    if (( SECONDS >= TIMEOUT )); then
      REMOVE_FLAG=1
      echo "One or more pods were not ready. Cleanup operation on some pods failed." | tee -a "${LOG_FILE}"
    fi

    # Revert the cronjob to its original state
    # 1) Remove the volumes which we added dynamically
    # 2) Add the placehodler cas pvcs mounts back

    #remove the volume which we have added dynamically
    for mount in "${pvc_mounts[@]}"
    do
      volume=${mount##*:}
      removeVolume "${volume}"
    done

kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[
    {"op": "add", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/0", "value": {"mountPath": "/cas/data", "name": "cas-data"}},
    {"op": "add", "path": "/spec/jobTemplate/spec/template/spec/volumes/1", "value": {"persistentVolumeClaim": {"claimName": "cas-temp-data"}, "name": "cas-data"}},
    {"op": "add", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/1", "value": {"mountPath": "/cas/permstore", "name": "cas-permstore"}},
    {"op": "add", "path": "/spec/jobTemplate/spec/template/spec/volumes/2", "value": {"persistentVolumeClaim": {"claimName": "cas-temp-permstore"}, "name": "cas-permstore"}}
]' >> "${LOG_FILE}"


    echo "Executed Remove function" >> "${LOG_FILE}"
    if [ "${REMOVE_FLAG}" = 0 ]; then
      echo "The cleanup pods are created, and they are in a running state." | tee -a "${LOG_FILE}"
      echo "Ensure that all pods are completed. To check the status of the cleanup pods, run the following command:" | tee -a "${LOG_FILE}"
      echo "kubectl -n ${namespace} get pods -l sas.com/backup-job-type=sas-backup-pv-copy-cleanup | grep ${random_string}" | tee -a "${LOG_FILE}"
    else
      exit 1
    fi
}

function removeVolume() {
    local resource_name="sas-backup-pv-copy-cleanup-job"  # Update to accept as an argument if needed

    local volume_name=$1
    echo removing volume and volume mount for volume name : "${volume_name}" >>  "${LOG_FILE}"

    # Find the index of the volumeMount
    volume_mount_index=$(kubectl get cronjob "$resource_name" -n "$namespace" -o json | jq -r --arg VOLUME_NAME "$volume_name" '.spec.jobTemplate.spec.template.spec.containers[0].volumeMounts | to_entries[] | select(.value.name == $VOLUME_NAME).key')

    # Remove the corresponding volumeMount if it exists
    if [ -n "$volume_mount_index" ] && [ "$volume_mount_index" != "null" ]; then
        kubectl patch cronjob "$resource_name" -n "$namespace" --type json -p "[{\"op\": \"remove\", \"path\": \"/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/$volume_mount_index\"}]" >> "${LOG_FILE}"
    else
        echo Volume mount with name "$volume_name" not found. >> "${LOG_FILE}"
    fi

    # Find the index of the volume
    volume_index=$(kubectl get cronjob "$resource_name" -n "$namespace" -o json | jq -r --arg VOLUME_NAME "$volume_name" '.spec.jobTemplate.spec.template.spec.volumes | to_entries[] | select(.value.name == $VOLUME_NAME).key')

    # Remove the volume if it exists
    if [ -n "$volume_index" ] && [ "$volume_index" != "null" ]; then

        kubectl patch cronjob "$resource_name" -n "$namespace" --type json -p "[{\"op\": \"remove\", \"path\": \"/spec/jobTemplate/spec/template/spec/volumes/$volume_index\"}]" >> "${LOG_FILE}"
    else
        echo Volume with name "$volume_name" not found. >> "${LOG_FILE}"
    fi
}

function main() {
if (("$#")); then

  if [ "$1" = "help" ] || [ "$1" = "--help" ] ; then
    display_usage
    exit 0
  fi

  if [ -z "$1" ]; then
    if [ -z "${KUBECONFIG}" ]; then
      echo "Error: namespace is not provided as an argument and KUBECONFIG is not set" | tee -a "${LOG_FILE}"
      display_usage
      exit 1
    fi
    namespace=$(grep -i "namespace" "${KUBECONFIG}"| awk '{print $2}')
  else
    namespace="$1"
  fi
  log_file_creation
  if [ -n "$2" ]; then
    PVCS=$2
    IFS=',' read -ra pvcs <<< "${PVCS}"
  else
    echo "PVCS list not provided, exiting." | tee -a "${LOG_FILE}"
    display_usage
    exit 1
  fi
  remove
else
  display_usage
  exit 1
fi
}


main "$@"
