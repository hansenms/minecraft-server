#!/bin/bash

usage() {
    echo "deploy-and-run.sh   [--environment <environment file>]"
    echo "                    [--verbose]"
    echo "                    [--help]"
}

# Settings
verbose=0
environmentFile=$(dirname $0)/environment.json

# Parse command line arguments
while [ "$1" != "" ]; do
    case $1 in
        -e | --environment )                        shift
                                                    environmentFile=$1
                                                    ;;
        -v | --verbose )                            verbose=1
                                                    ;;
        -h | --help )                               usage
                                                    exit
                                                    ;;
        * )                                         usage
                                                    exit 1
    esac
    shift
done

# Ensure environment file name exists
if [ ! -f $environmentFile ]; then
    echo "Invalid environment filename ${environmentFile}";
    exit 1
fi

environmentName=`cat ${environmentFile} | jq -r .environmentName`
environmentLocation=`cat ${environmentFile} | jq -r .environmentLocation`
vmSize=`cat ${environmentFile} | jq -r .vmSize`
maxNodeCount=`cat ${environmentFile} | jq -r .maxNodeCount`
resourceGroupName="${environmentName}-rg"
clusterName="${environmentName}"
keyvaultName=$environmentName

if [ "$verbose" -gt 0 ]; then
    echo "environmentName:     ${environmentName}"
    echo "environmentLocation: ${environmentLocation}"
    echo "vmSize:              ${vmSize}"
    echo "maxNodeCount:        ${maxNodeCount}"
    echo "resourceGroupName:   ${resourceGroupName}"
    echo "clusterName:         ${clusterName}"
fi

# First create a resource group
az group create --name $resourceGroupName --location $environmentLocation

# Create a keyvault
az keyvault create -n $keyvaultName -g $resourceGroupName --enable-soft-delete true

sshKeyFile=~/.ssh/${environmentName}_rsa
setKeyVaultSshSecrets=false
sshPrivateKey=`az keyvault secret show --vault-name $keyvaultName --name ssh-private-key 2> /dev/null || true`

if [ -n "$sshPrivateKey" ]; then
    echo $sshPrivateKey | jq -r .value > $sshKeyFile
else
    setKeyVaultSshSecrets=true
fi

sshPublicKey=`az keyvault secret show --vault-name $keyvaultName --name ssh-public-key 2> /dev/null || true`
if [ -n "$sshPublicKey" ]; then
    echo $sshPublicKey | jq -r .value > ${sshKeyFile}.pub
else
    setKeyVaultSshSecrets=true
fi

if [ ! -f $sshKeyFile ]; then
    ssh-keygen -f $sshKeyFile -t rsa -N ''
    setKeyVaultSshSecrets=true
fi

if [ "$setKeyVaultSshSecrets" = true ]; then
    az keyvault secret set --name "ssh-private-key" --vault-name $keyvaultName --file $sshKeyFile > /dev/null
    az keyvault secret set --name "ssh-public-key" --vault-name $keyvaultName --file ${sshKeyFile}.pub > /dev/null
fi

#We need to know if the cluster is already there:
clusterFound=`az aks list --query "[?(name=='${clusterName}'&&resourceGroup=='${resourceGroupName}')]" | jq '. | length'`

if [ $clusterFound -eq 0 ]
then
    # There is a problem with the automatic SP creation in az aks create, so we will make the SP first
    # https://github.com/Azure/azure-cli/issues/9585

    # First let's see if we have it service principal already
    spId=""
    spPass=""

    clientIdKeyvaultSecret=`az keyvault secret show --vault-name $keyvaultName --name service-principal-client-id 2> /dev/null || true`
    clientSecretKeyvaultSecret=`az keyvault secret show --vault-name $keyvaultName --name service-principal-client-secret 2> /dev/null || true`

    if [ -n "$clientIdKeyvaultSecret" ] && [ -n "$clientSecretKeyvaultSecret" ]; then
        spId=`echo $clientIdKeyvaultSecret | jq -r .value`
        spPass=`echo $clientSecretKeyvaultSecret | jq -r .value`
    else
        subscription=$(az account show | jq -r .id)
        sp=$(az ad sp create-for-rbac --scope /subscriptions/${subscription}/resourceGroups/${resourceGroupName} --role Contributor --output json)
        spId=$(echo $sp | jq -r '.appId')
        spPass=$(echo $sp | jq -r '.password')

        az keyvault secret set --name "service-principal-client-id" --vault-name $keyvaultName --value $spId
        az keyvault secret set --name "service-principal-client-secret" --vault-name $keyvaultName --value $spPass

        sleep 30 # This is (unfortunately) necessary make sure the service principal is available for the AKS deployment.
    fi

    az aks create \
        --resource-group $resourceGroupName \
        --name $clusterName \
        --node-count 1 \
        --node-vm-size $vmSize \
        --vm-set-type VirtualMachineScaleSets \
        --load-balancer-sku standard \
        --enable-cluster-autoscaler \
        --min-count 1 \
        --max-count $maxNodeCount \
        --service-principal $spId \
        --client-secret $spPass \
        --ssh-key-value ${sshKeyFile}.pub \
        --kubernetes-version 1.16.7
else
    az aks update \
        --resource-group $resourceGroupName \
        --name $clusterName \
        --update-cluster-autoscaler \
        --min-count 1 \
        --max-count $maxNodeCount
fi

az aks get-credentials --name $clusterName --resource-group $resourceGroupName

helm repo add stable https://kubernetes-charts.storage.googleapis.com