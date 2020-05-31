#!/bin/bash

folder=$(dirname $0)
podName=$1

kubectl cp $folder $podName:/tmp/
