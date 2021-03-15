#!/bin/bash

release=$1
kubectl get pod -l "app.kubernetes.io/instance=${release}" -o json | jq -r '.items[0].metadata.name // empty'
