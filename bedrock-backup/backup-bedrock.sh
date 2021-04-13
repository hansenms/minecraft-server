#!/bin/bash

folder=$(dirname "$0")
release="$1"
papyrusExe="$2"

namespace="$3"
if [ -n "${namespace}" ]; then
  kubectl config set-context --current --namespace="$namespace" 1>/dev/null
fi

podName=$("${folder}/get-bedrock-pod-name.sh" "${release}")
timestamp=$(date '+%Y%m%d-%H%M%S')
backupName="bedrock-backup-${timestamp}"

if [ -z "${podName}" ]; then
  echo "Can't find the running pod for '${release}'"
  exit 1
fi

# Make sure we have artifacts in pod
"${folder}/upload-scripts.sh" "${podName}"

kubectl exec "${podName}" -- /tmp/minecraft/pod-send-command.sh "save hold"

timeout=0
unset logText
until echo "${logText}" | grep -q "Data saved."; do
  if [ "${timeout}" = 60 ]; then
    kubectl exec "${podName}" -- /tmp/minecraft/pod-send-command.sh "save resume"
    echo >&2 "save query timeout"
    exit 1
  fi

  # Check if backup is ready
  kubectl exec "${podName}" -- /tmp/minecraft/pod-send-command.sh "save query"
  logText=$(kubectl logs --tail 2 "${podName}")
  timeout=$((++timeout))
done

mkdir -p "${backupName}/worlds"
kubectl cp "${podName}:/data/worlds" "./${backupName}/worlds" 1>/dev/null
kubectl cp "${podName}:/data/whitelist.json" "./${backupName}/whitelist.json" 1>/dev/null
kubectl cp "${podName}:/data/permissions.json" "./${backupName}/permissions.json" 1>/dev/null
kubectl cp "${podName}:/data/server.properties" "./${backupName}/server.properties" 1>/dev/null
kubectl exec "${podName}" -- /tmp/minecraft/pod-send-command.sh "save resume"

files=$(echo "${logText}" | grep -Eo "[^:/]+:[0-9]+")
for f in ${files}; do
  regex="^([^:]+):([0-9]+)"
  if [[ $f =~ ${regex} ]]; then
    fileName="${BASH_REMATCH[1]}"
    length="${BASH_REMATCH[2]}"
    backupFileName=$(find "${backupName}"/ -name "${fileName}")
    if [ -f "${backupFileName}" ]; then
      truncate -s "${length}" "${backupFileName}"
    fi
  fi
done

tar -czvf "${backupName}.tar.gz" -C "${backupName}" .

if [ -f "${papyrusExe}" ]; then
  cp -r ./map /tmp/
  world="${backupName}/worlds/Bedrock level/db"
  ${papyrusExe} --threads 4 --maxqueue 16 --dim 0 --playericons true --world "${world}" --output /tmp/map
  rm -rf ./map
  mv /tmp/map ./map
fi

rm -rf "${backupName}"
