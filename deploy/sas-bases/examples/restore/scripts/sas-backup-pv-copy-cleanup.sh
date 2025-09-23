#!/bin/bash
MODE=""
LOG_FILE=""
TIMEOUT=600

function display_usage() {
  echo
  echo "********************************************************************************"
  echo
  echo "Execute sas-backup-pv-copy-cleanup for cleaning up the CAS PVs using the 'remove' operation."
  echo "The script also supports mounting the backup PVs, namely sas-common-backup-data and CAS backup PVs, using the 'copy' operation. "
  echo "The script should be executed for the same namespace where the restore operation has been performed."
  echo
  echo "Usage:"
  echo "  ./sas-backup-pv-copy-cleanup.sh [namespace] [operation] [CAS instances list]"
  echo
  echo "Arguments:"
  echo " namespace          : A Kubernetes namespace where the required operation should be performed."
  echo " operation          : The operation that user wants to perform."
  echo "                      It has only two possible values: remove and copy."
  echo "                      1. remove : Cleanup the CAS PVs."
  echo "                      2. copy   : Mount the backup PVs namely sas-common-backup-data and CAS backup PV."
  echo " CAS instances list : A comma separated list of CAS instances."
  echo
  echo
  echo 'Example for Remove operation : ./sas-backup-pv-copy-cleanup.sh viya04 remove "default"  '
  echo
  echo 'Example for Copy operation : ./sas-backup-pv-copy-cleanup.sh viya04 copy "default"  '
  echo
  echo "********************************************************************************"
  echo
}

function log_file_creation(){
  LOG_FILE_PATH="/tmp/"
  if [ ${MODE} = "remove" ] ; then
    LOG_FILE_NAME="sas-backup-pv-cleanup"
  else
    LOG_FILE_NAME="sas-backup-pv-copy"
  fi
  LOG_FILE="${LOG_FILE_PATH}${LOG_FILE_NAME}_$(date "+%Y%m%d-%H.%M.%S").log"
  touch "${LOG_FILE}"
}

function remove(){
    random_string=$(printf '%s' "$(echo "$RANDOM" | md5sum)" | cut -c 1-7)

    for tenant in "${tenants[@]}"
    do
      tenant="$(echo -e "${tenant}" | tr -d '[:space:]')"

      tenant_filter="${tenant}"
      if  [ "${tenant}" = "provider" ] || [ "${tenant}" = "default" ] ; then
        tenant_filter="shared"
      fi

      instance_list=$(kubectl -n "${namespace}" get casdeployment -l "sas.com/tenant=${tenant_filter}" -L casoperator.sas.com/instance | awk '{print $3}' | tail -n +2)

      for instance in $instance_list
      do
        pvc_list=$(kubectl -n "${namespace}" get pvc -l "casoperator.sas.com/instance=${instance},sas.com/tenant=${tenant_filter},sas.com/backup-role=provider" | awk '{print $1}' | tail -n +2)

        if [ -z "${pvc_list}" ] ; then
          echo "Error: there are no PVC, either CAS instance is not valid or PVC is not associated with ${tenant}" | tee -a "${LOG_FILE}"
          exit 1
        fi
        for pvc in $pvc_list
        do
          if [[ "$pvc" == *"backup"* || "$pvc" == *"transfer"* ]] ; then
            continue
          elif [[ "$pvc" == *"permstore"* ]]; then
            pvc_cas_permstore="${pvc}"
          else
            pvc_cas_data="${pvc}"
          fi
        done
        if [ -z "${pvc_cas_data}" ] || [  -z "${pvc_cas_permstore}" ] ; then
          echo "Error: ${tenant} is not a valid instance" | tee -a "${LOG_FILE}"
          exit 1
        fi
        # kubectl commands
        #kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n ${namespace} --type json -p '[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/securityContext/allowPrivilegeEscalation", "value": true}]' >> ${LOG_FILE} || :

        kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/1/persistentVolumeClaim/claimName", "value": "'"${pvc_cas_data}"'"},
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/2/persistentVolumeClaim/claimName", "value": "'"${pvc_cas_permstore}"'"}
        ]' >> "${LOG_FILE}"

        kubectl create job -n "${namespace}" --from=cronjob/sas-backup-pv-copy-cleanup-job sas-backup-pv-cleanup-"${tenant}"-"${instance}"-"${random_string}" --dry-run=client -o yaml | kubectl set env --dry-run=client --local=true -c "sas-backup-pv-copy-cleanup-job" SAS_BACKUP_AGENT_START_MODE="REMOVE" -o=yaml -f - | kubectl apply -f -  >> "${LOG_FILE}"

        instance_count=$(( instance_count + 1))
      done

    done

    REMOVE_FLAG=0
    running_pod_count=0
    while  (( SECONDS < TIMEOUT )) ;
    do
      if [ "${running_pod_count}" -ge "${instance_count}" ] ; then
         break
      fi
      for tenant in "${tenants[@]}"
      do
        for instance in $instance_list
        do
          tenant="$(echo -e "${tenant}" | tr -d '[:space:]')"
          job_name="sas-backup-pv-cleanup-${tenant}-${instance}-${random_string}"
          count_succeeded=$(kubectl get pods -n "${namespace}" --field-selector="status.phase=Succeeded" -l job-name="${job_name}" --output json  | jq -j '.items | length')
          count_running=$(kubectl get pods -n "${namespace}" --field-selector="status.phase=Running" -l job-name="${job_name}" --output json  | jq -j '.items | length')
          count_failed=$(kubectl get pods -n "${namespace}" --field-selector="status.phase=Failed" -l job-name="${job_name}" --output json  | jq -j '.items | length')

          running_pod_count=$((running_pod_count + count_succeeded + count_running + count_failed))
        done
      done
      echo Waiting for all pods to be ready. >> "${LOG_FILE}"
      echo Current succeeded pod count: "${count_succeeded}" >> "${LOG_FILE}"
      sleep 5
    done

    if (( SECONDS >= TIMEOUT )) ; then
      REMOVE_FLAG=1
      echo "One or more pods were not ready. Cleanup operation on some pods failed." | tee -a "${LOG_FILE}"
    fi


    # shellcheck disable=SC2129
    echo "Reset sas-backup-pv-copy-cleanup-job cronjob to original state." >> "${LOG_FILE}"

    kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/1/persistentVolumeClaim/claimName", "value": "cas-temp-data"}]' >> "${LOG_FILE}"

    kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/2/persistentVolumeClaim/claimName", "value": "cas-temp-permstore"}]' >> "${LOG_FILE}"

    #kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n ${namespace} --type json -p '[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/securityContext/allowPrivilegeEscalation", "value": false}]' >> ${LOG_FILE} || :

  echo "Executed Remove function" >> "${LOG_FILE}"
  if [ "${REMOVE_FLAG}" = 0 ] ; then
    echo "The cleanup pods are created, and they are in a running state." | tee -a "${LOG_FILE}"
    echo "Ensure that all pods are completed. To check the status of the cleanup pods, run the following command." | tee -a "${LOG_FILE}"
    echo "kubectl -n ${namespace} get pods -l sas.com/backup-job-type=sas-backup-pv-copy-cleanup | grep ${random_string} " | tee -a "${LOG_FILE}"
  else
    exit 1
  fi
}

function copy(){
    random_string=$(printf '%s' "$(echo "$RANDOM" | md5sum)" | cut -c 1-7)

    if [ -n "${tenants}" ]; then
      for tenant in "${tenants[@]}"
      do
        tenant="$(echo -e "${tenant}" | tr -d '[:space:]')"

        tenant_filter="${tenant}"
        if  [ "${tenant}" = "provider" ] || [ "${tenant}" = "default" ] ; then
          tenant_filter="shared"
        fi

        instance_list=$(kubectl -n "${namespace}" get casdeployment -l "sas.com/tenant=${tenant_filter}" -L casoperator.sas.com/instance | awk '{print $3}' | tail -n +2)

        for instance in $instance_list
        do
          pvc_list=$(kubectl -n "${namespace}" get pvc -l "casoperator.sas.com/instance=${instance},sas.com/tenant=${tenant_filter},sas.com/backup-role=storage" | awk '{print $1}' | tail -n +2)

          if [ -z "${pvc_list}" ] ; then
            echo "Error: there are no PVC, either tenant is not valid or PVC is not associated with ${tenant}" | tee -a "${LOG_FILE}"
            exit 1
          fi
          for pvc in $pvc_list
          do
            if [[ "$pvc" == *"backup"* ]] ; then
              cas_data="${pvc}"
            else
              continue
            fi
          done
          if [ -z "${cas_data}" ] ; then
            echo "Error: ${tenant} is not a valid instance" | tee -a "${LOG_FILE}"
            exit 1
          fi
          # kubectl commands

          #kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/securityContext/allowPrivilegeEscalation", "value": true}]' >> ${LOG_FILE} || :

          kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[
          {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/0/mountPath", "value": "/sasviyabackup"},
          {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/0/name", "value": "backup"},
          {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/1/persistentVolumeClaim/claimName", "value": "sas-common-backup-data"},
          {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/1/name", "value": "backup"},
          {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/1/mountPath", "value": "/cas"},
          {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/1/name", "value": "cas"},
          {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/2/persistentVolumeClaim/claimName", "value": "'"${cas_data}"'"},
          {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/2/name", "value": "cas"}
          ]' >> "${LOG_FILE}"

          kubectl create job -n "${namespace}" --from=cronjob/sas-backup-pv-copy-cleanup-job sas-backup-pv-copy-"${tenant}"-"${instance}"-"${random_string}" >> "${LOG_FILE}"

          echo "The sas-backup-pv-copy-${tenant}-${instance}-${random_string} keeps on running until user terminates it." | tee -a "${LOG_FILE}"

          instance_count=$(( instance_count + 1))
        done

      done

    else
        #kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/securityContext/allowPrivilegeEscalation", "value": true}]' >> "${LOG_FILE}" || :

        kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/0/mountPath", "value": "/sasviyabackup"},
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/0/name", "value": "backup"},
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/1/persistentVolumeClaim/claimName", "value": "sas-common-backup-data"},
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/1/name", "value": "backup"},
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/1/mountPath", "value": "/cas"},
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/1/name", "value": "cas"},
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/2/persistentVolumeClaim/claimName", "value": "sas-cas-backup-data"},
        {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/2/name", "value": "cas"}
        ]' >> "${LOG_FILE}"

        kubectl create job -n "${namespace}" --from=cronjob/sas-backup-pv-copy-cleanup-job sas-backup-pv-copy-"${random_string}" >> "${LOG_FILE}"

    fi

    COPY_FLAG=0
    running_pod_count=0
    while  (( SECONDS < TIMEOUT )) ;
    do
      if [ "${running_pod_count}" -ge "${instance_count}" ] ; then
         break
      fi
      for tenant in "${tenants[@]}"
      do
        for instance in $instance_list
        do
          tenant="$(echo -e "${tenant}" | tr -d '[:space:]')"
          job_name="sas-backup-pv-copy-${tenant}-${instance}-${random_string}"
          count_succeeded=$(kubectl get pods -n "${namespace}" --field-selector="status.phase=Succeeded" -l job-name="${job_name}" --output json  | jq -j '.items | length')
          count_running=$(kubectl get pods -n "${namespace}" --field-selector="status.phase=Running" -l job-name="${job_name}" --output json  | jq -j '.items | length')
          count_failed=$(kubectl get pods -n "${namespace}" --field-selector="status.phase=Failed" -l job-name="${job_name}" --output json  | jq -j '.items | length')

          running_pod_count=$((running_pod_count + count_succeeded + count_running + count_failed))
        done
      done
      echo Waiting for all pods to be ready. >> "${LOG_FILE}"
      echo Current succeeded pod count: "${count_succeeded}" >> "${LOG_FILE}"
      sleep 5
    done

    if (( SECONDS >= TIMEOUT )) ; then
      COPY_FLAG=1
      echo "One or more pods were not ready. Copy operation on some pods failed." | tee -a "${LOG_FILE}"
    fi
    # shellcheck disable=SC2129
    echo "Reset sas-backup-pv-copy-cleanup-job cronjob to original state." >> "${LOG_FILE}"

    kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n "${namespace}" --type json -p '[
    {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/0/mountPath", "value": "/cas/data"},
    {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/0/name", "value": "cas-data"},
    {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/1/persistentVolumeClaim/claimName", "value": "cas-temp-data"},
    {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/1/name", "value": "cas-data"},
    {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/1/mountPath", "value": "/cas/permstore"},
    {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/volumeMounts/1/name", "value": "cas-permstore"},
    {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/2/persistentVolumeClaim/claimName", "value": "cas-temp-permstore"},
    {"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/volumes/2/name", "value": "cas-permstore"}
    ]' >> "${LOG_FILE}"

    #kubectl patch cronjob sas-backup-pv-copy-cleanup-job -n ${namespace} --type json -p '[{"op": "replace", "path": "/spec/jobTemplate/spec/template/spec/containers/0/securityContext/allowPrivilegeEscalation", "value": false}]' >> "${LOG_FILE}" || :

  echo "Executed Copy function" >> "${LOG_FILE}"
  if [ ${COPY_FLAG} = 0 ] ; then
    echo "The copy pods are created, and they are in a running state." | tee -a "${LOG_FILE}"
    echo "To check the status of copy pods, run the following command." | tee -a "${LOG_FILE}"
    echo "kubectl -n ${namespace} get pods -l sas.com/backup-job-type=sas-backup-pv-copy-cleanup | grep ${random_string} " | tee -a "${LOG_FILE}"
  else
    exit 1
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

  if [ -n "$3" ]; then
    TENANTS=$3
    IFS=',' read -ra tenants <<< "${TENANTS}"
  else
    echo "Instance list not provided, exiting." | tee -a "${LOG_FILE}"
    display_usage
    exit 1
  fi

  shopt -s nocasematch;
  if [  -n "$2" ] && [ "$2" = "remove" ]; then
    MODE="remove"
    log_file_creation
    echo "Setting mode to auto cleanup '$MODE'" >> "${LOG_FILE}"
    remove
  fi
  if [ -n "$2" ] && [ "$2" = "copy" ]; then
    MODE="copy"
    log_file_creation
    echo "Setting mode to '$MODE'" >> "${LOG_FILE}"
    copy
  fi
else
  display_usage
fi
}

main "$@"
