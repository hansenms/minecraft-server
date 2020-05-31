#!/bin/bash

folder=$(dirname $0)
release=$1
podName=$($folder/get-bedrock-pod-name.sh $release)

# Make sure we have artifacts in pod
$folder/upload-scripts.sh $podName

kubectl exec $podName -- /tmp/scripts/pod-send-command.sh "save hold"

timeout=0
unset logText
until echo "$logText" | grep "Data saved."; do
    if [ "$timeout" = 60 ]; then
        kubectl exec $podName -- /tmp/scripts/pod-send-command.sh "save resume"
		>&2 echo save query timeout
		exit 1
	fi

	# Check if backup is ready
    kubectl exec $podName -- /tmp/scripts/pod-send-command.sh "save query"
    logText=$(kubectl logs --tail 2 $podName)
	timeout=$(( ++timeout ))
done

kubectl cp $podName:/data/worlds ./
kubectl exec $podName -- /tmp/scripts/pod-send-command.sh "save resume"
