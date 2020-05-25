# Minecraft Server on Kubernetes

This repo demonstrates how to run a Minecraft server in Kubernetes.

## Bedrock vs Java Edition

There are really two main flavors or editions of Minecraft. The original [Java Edition](https://minecraft.gamepedia.com/Java_Edition) and the [Bedrock Edition](https://minecraft.gamepedia.com/Bedrock_Edition). Please consult the [Minecraft Wiki](https://minecraft.gamepedia.com/Minecraft_Wiki) for more information on the editions and versions of Minecraft. The Java and Bedrock editions are **not** interoperable. Specifically, a player running the Java version cannot connect to a Bedrock server and vice versa.

If your players are connecting from consoles (more details on that later), windows 10, etc., they are likely using Bedrock edition and you should deploy the Bedrock server. If they are using the Minecraft launcher on Windows, Linux, or Mac, they are likely using the Java Edition.

There is an existing [helm chart for Minecraft Java Edition](https://github.com/helm/charts/tree/master/stable/minecraft) in the standard helm chart repository. And this repo contains a [helm chart for Minecraft Bedrock Edition](helm/minecraft-bedrock)

## Deploying a Kubernetes cluster

There are many ways to deploy a Kubernetes cluster. This repo uses [Azure AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) as an example. This repo contains a convenience script that will create a service principal, make sure SSH keys are available, store the details in a keyvault, and provision the cluster. It should be idempotent-ish allowing you to update the cluster with changes to your environment.

To deploy the cluster, log into your Azure account with the Azure CLI:

```bash
az login
```

and then run the cluster provisioning script:

```bash
./deploy-cluster.sh
```

Environment details are defined in [environment.json](environment.json) and you can also specify your own environment file:

```bash
./deploy-cluster.sh -e <environment file name>
```

## Deploy Bedrock Minecraft Server

To install the Bedrock minecraft server, use the helm chart in this repo:

```bash
helm install bedrock-server helm/minecraft-bedrock/ \
    --set minecraftServer.gameMode="survival" \
    --set minecraftServer.difficulty="normal" \
    --set minecraftServer.whitelist="Player1,Player2" \
    --set persistence.storageClass="azurefile"
```

here we have explicitly spelled out some default settings. See [values.yaml](helm/minecraft-bedrock/values.yaml) for details on values that can be set.

After launching the bedrock server, you can attach to the running process to issue commands (e.g. whitelist):

```bash
kubectl attach <pod name> -ti
```

then

```bash
whitelist add <player name>
whitelist reload
```

to detach, use `ctrl+p` and then `ctrl+q`. Do **not** do `ctrl+c`, which will end the running process.

## Deploy Java Minecraft Server

The Java Edition of the Minecraft server can be deployed with the helm chart in the standard helm repository:

```bash
helm upgrade --install minecraft-server \
    --set minecraftServer.version="1.15.2" \
    --set livenessProbe.initialDelaySeconds=150 \
    --set persistence.storageClass=azurefile \
    --set minecraftServer.eula=true stable/minecraft \
    --set minecraftServer.whitelist="Player1,Player2,Player3"
```

For details on using this chart, please [consult the documentation](https://github.com/helm/charts/tree/master/stable/minecraft).

## Persistence

For both server types, the helm start will provision a persistent volume claim using the storage class in `persistence.storageClass`. When using AKS, you will probably use `azurefile`. The `azurefile` storage class has a `reclaimPolicy` of `Delete`, which means that when you delete a specific helm release, the file share will be removed and you loose all the changes.

That might not be what you want to do, so you can create a new storage class with `reclaimPolicy` of `Retain`, and the storage will not get deleted. There is a [sample manifest](manifests/azurefile-retain-sc.yaml) for creating this storage class. Create the storage class with:

```bash
kubectl apply -f manifests/azurefile-retain-sc.yaml
```

And then when deploying the helm chart specify the new storage class:

```bash
helm install bedrock-server helm/minecraft-bedrock/ --set persistence.storageClass="azurefile-retain"
```

The Bedrock helm chart also adds a `"helm.sh/resource-policy": keep` annotation to the persistent volume claim, which means it will not get deleted regardless of which storage class you use. If you would like to automatically delete the persistent volume claim, overwrite the resource policy with something like:

```bash
helm install bedrock-server helm/minecraft-bedrock/ --set persistence.resourcePolicy="delete"
```

## Connecting to Bedrock servers from consoles

If your players are using a Windows 10 client, they will be able to add the minecraft server by hitting "Add server" in the servers menu and then filling in the details"

![adding a new server](https://cloud.addictivetips.com/wp-content/uploads/2018/08/add-server-minecraft.jpg)

However, consoles don't have that option, so we need a workaround. There are a couple of options:

### LAN Proxy (phantom)

There is a simple tool available on for setting up a local LAN proxy: [https://github.com/jhead/phantom]. It will make a remote server look like a LAN game and allow players to join from the friends menu. Run the tool with something like:

```shell
 ./phantom-<os> -server lax.mcbr.cubed.host:19132
```

And then find the game from the friends menu.

### Bedrock Connect DNS

There is a pretty neat DNS trick that can be used as described here: https://github.com/Pugmatt/BedrockConnect.

Set your DNS servers to manual on the XBox with:

1. Primary DNS: 104.238.130.180 
1. Secondary DNS: 8.8.8.8 (or similar)

Then connect to one of the featured servers and you will be "relayed" to another server that will allow you to enter the remote bedrock server you would like to connect to. Watch [this video](https://www.youtube.com/watch?v=Uz-XYXAxd8Q) for details.

