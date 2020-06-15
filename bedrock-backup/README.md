# Minecraft Bedrock Server Backup

The Minecraft Bedrock dedicated server is still in somewhat early stages of development and doing a backup of a running server is a bit tricky. This folder contains some inital helper scripts and automation. It will will evolve as the server evolves.

## Bedrock backup sequence

In order to back up a bedrock server, you should use the following sequence:

1. Send command `save hold` to the server.
1. Continue to sende `save query` to the server until it responds that the data has been saves and lists the files.
1. Copy the files.
1. Send a `save resume` to the server to restart writing to the files. 
1. Truncate the saves files according to the file lengths that are given by the server (in the output of `save query`).

In this repo, these steps are done with a set of scripts. Some run on the machine (on container) performing the backup and some run on the pod with the bedrock server itself. Since the image for the bedrock server don't contain the scripts needed for backup, the backup script copies them into the running container. This is probably not the best solution in the long run, but given that the bedrock server is still in development, there are likely to be some more robust backup methods and we will make adjustments at that point.

## Backup and restore from a local machine

Backing up can be done with:

```bash
./scripts/backup-bedrock.sh <helm release name>
```

You can restore this to an Azure Files share with:

```bash
../scripts/restore-bedrock.sh <backup .tar.gz> <storage account name> <share name>
```

Make sure you don't have a running bedrock server on that share. You can create one, shut it down, restore, and then bring it back up.

## Running backup as a CronJob on AKS

Backup should be automated. The [manifests](manifests/) folder contains some example Kubernetes manifests for automated backup. You can use them as described here.

First create a persistent volume claim for holding the backups. There is an example manifest for doing that on AKS using azurefile storage class:

```bash
kubectl apply -f manifests/backup-pvc.yaml
```

Then create a service account for backing up:

```bash
kubectl apply -f backup-service-account.yaml
```

You may want to edit the role for this account first. It has more privileges than is needed for doing the backup, but it has doubled for other functions so for now it is not least privilege. 

Then start the cron job:

```bash
kubectl apply -f manifests/backup-cronjob.yaml
```

You will want to make some edits to this file too. Specifically, the name of the helm release to back up is an argument to the container and the job is currently set to run at 07:00 UTC (in the middle of the night when little kids are asleep on the West Coast). Adjust as needed, it is just an example of one possible way to do it.