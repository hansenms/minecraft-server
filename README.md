# Minecraft Server on Kubernetes

Minecraft is a great game for kids (of all ages) to learn, explore, and be creative. At some point, it may be interesting to play with others online and you may want to do that in a controlled environment. So you are thinking, you need a private server.

However, before you go down the rabbit hole (the instructions here), if you just want the easiest way to get a private server experience with Minecraft, check out the [Minecraft Realms](https://www.minecraft.net/realms) where you can get a private server for a few friends for about $8/month. If you are less technically inclined and don't care about how all of this works, then that is what you are looking for.

If, on the other hand, you wonder how Minecraft servers actually work and you want to **run a Minecraft server like a boss**, read on. This repo demonstrates how to run a Minecraft server in Kubernetes. There are also some details on how to connect consoles (e.g. Xbox One) to your private server. 

## Bedrock vs Java Edition

There are really two main flavors or editions of Minecraft. The original [Java Edition](https://minecraft.gamepedia.com/Java_Edition) and the [Bedrock Edition](https://minecraft.gamepedia.com/Bedrock_Edition). Both are alive and well and being used and developed. Please consult the [Minecraft Wiki](https://minecraft.gamepedia.com/Minecraft_Wiki) for more information on the editions and versions of Minecraft. The Java and Bedrock editions are **not** compatible or interoperable. Specifically, a player running the Java version cannot connect to a Bedrock server and vice versa.

If your players are connecting from consoles (more details on that later), Windows 10, etc., they are likely using Bedrock edition and you should deploy the Bedrock server. If they are using the Minecraft launcher on Windows, Linux, or Mac, they are likely using the Java Edition. The instructions here are mostly focused on the Bedrock server, but there is some help on the Java Edition as well.

There is an existing [helm chart for Minecraft Java Edition](https://github.com/helm/charts/tree/master/stable/minecraft) in the standard helm chart repository. And this repo contains a [helm chart for Minecraft Bedrock Edition](helm/minecraft-bedrock). We use these helm charts to provision and manage the Minecraft server.

## Deploying a Kubernetes cluster

There are many ways to deploy a Kubernetes cluster. This repo demonstrates [Azure AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/) as an example. The install steps are captured in a a [convenience script](deploy-cluster.sh) that will create a service principal, make sure SSH keys are available, store the details in a keyvault, and provision the cluster. It should be idempotent-ish allowing you to update the cluster with changes to your environment.

You don't have to use the script. You may, in fact, want to walk through the steps slowly to decide which model settings are the right ones for you. But to deploy the cluster with the script, log into your Azure account with the Azure CLI:

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
    --set minecraftServer.whitelist=true \
    --set persistence.storageClass="azurefile" \
    --set service.dnsPrefix="my-minecraft-server"
```

here we have explicitly spelled out some default settings. See [values.yaml](helm/minecraft-bedrock/values.yaml) for details on values that can be set.

The `service.dnsPrefix` is only relevant if you deploy on Azure AKS. It will be used to set the DNS name for the public IP address. So if you cluster is deployed in say `westus2`, the DNS name of your minecraft server will be `my-minecraft-server.westus2.cloudapp.azure.com`. You can use that address to connect to your Minecraft server.

Another way to get the connection details is with a command like:

```
kubectl get --namespace default svc <helm-release-name>-minecraft-bedrock
```

After launching the bedrock server, you can attach to the running process to issue commands (e.g. whitelist):

```bash
kubectl attach <pod name> -ti
```

You can find the pod name for your Minecraft server wth `kubectl get pods`. Then to issue a command:

```bash
whitelist add <player name>
whitelist reload
```

to detach, use `ctrl+p` and then `ctrl+q`. Do **not** do `ctrl+c`, which will end the running process.

## Deploy Java Minecraft Server

The Java Edition of the Minecraft server can be deployed with the helm chart in the [standard helm repository](https://github.com/helm/charts/):

```bash
helm install minecraft-server \
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

## Connecting to Bedrock servers from consoles (Xbox One)

If your players are using a Windows 10 client, they will be able to add the minecraft server by hitting "Add server" in the servers menu and then filling in the details

![adding a new server](https://cloud.addictivetips.com/wp-content/uploads/2018/08/add-server-minecraft.jpg)

However, consoles don't have that option, so we need a workaround. There are a couple of options:

### LAN Proxy (phantom)

There is a simple tool available on for setting up a local LAN proxy: [https://github.com/jhead/phantom](https://github.com/jhead/phantom). It will make a remote server look like a LAN game and allow players to join from the friends menu. Run the tool with something like:

```shell
 ./phantom-<os> -server lax.mcbr.cubed.host:19132
```

And then find the game from the friends menu.

### Bedrock Connect DNS

There is a pretty neat DNS trick that can be used as described here: [https://github.com/Pugmatt/BedrockConnect](https://github.com/Pugmatt/BedrockConnect).

Set your DNS servers to manual on the XBox with:

1. Primary DNS: 104.238.130.180
1. Secondary DNS: 8.8.8.8 (or similar)

Then connect to one of the "featured servers" and you will be "relayed" to another server that will allow you to enter the remote bedrock server you would like to connect to. Watch [this video](https://www.youtube.com/watch?v=g8mHvasVHMs) for details.

This repo also contains a helm chart for running your own BedrockConnect service. Install itwith:

```bash
helm install brc helm/bedrock-connect/ --set service.ipAddress="XXX.XXX.XXX.XXX" --set service.ipAddressResourceGroup="my-ip-address-rg"
```

The specific IP address specification and resource group will work when running in AKS. The service principal should have contributor rights on thet resource group. If no IP address is specified it will get a dynamic IP address, which may be tricky to manage if it changes.

### Custom DNS masking

This repo also contains a helm chart that will deploy [dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) in the Kubernetes cluster and mask any of "Featured Servers" in Minecraft (or really any server) The dnsmasq application can be used to point to a BedrockConnect server or simply point directly to your private Minecraft server, in which case selecting any of the Featured Servers would take you straight to the private server.

To deploy the DNS masking server:

```bash
helm install dnsmasq helm/dnsmasq/ --set dnsmasq.entry1.host='hivebedrock.network',dnsmasq.entry1.ip='XXX.XXX.XXX.XXX'
```

where `XXX.XXX.XXX.XXX` is either the IP address of a BedrockConnect server or simply the address of your private Minecraft server. This will only overwrite the Hive server, but you can overwrite an arbitrary number of servers:

```bash
helm install dnsmasq helm/dnsmasq/ \
    --set service.ipAddress="XXX.XXX.XXX.XXX" \
    --set service.ipAddressResourceGroup="my-ip-address-rg" \
    --set dnsmasq.entry1.host='geo.hivebedrock.network',dnsmasq.entry1.ip='YYY.YYY.YYY.YYY' \
    --set dnsmasq.entry2.host='hivebedrock.network',dnsmasq.entry2.ip='YYY.YYY.YYY.YYY' \
    --set dnsmasq.entry3.host='play.inpvp.net',dnsmasq.entry3.ip='YYY.YYY.YYY.YYY' \
    --set dnsmasq.entry4.host='mco.mineplex.com',dnsmasq.entry4.ip='YYY.YYY.YYY.YYY' \
    --set dnsmasq.entry5.host='mco.lbsg.net',dnsmasq.entry5.ip='YYY.YYY.YYY.YYY' \
    --set dnsmasq.entry6.host='mco.cubecraft.net',dnsmasq.entry6.ip='YYY.YYY.YYY.YYY'
```

After deployment, find the public IP address of the dnsmasq service with:

```bash
kubectl get svc
```

and set that public IP address as the primary DNS server address for your Xbox One console.

## To Do

There is still some work to do. If you want to pitch in here are some things to start with:

1. Pass on relevant all values from helm chart to Bedrock server. Only some settings are configurable at the moment.
1. Helm chart to deploying Bedrock Connect server.

Also check out the [issues](https://github.com/hansenms/minecraft-server/issues) for this repo.

## Acknowledgements

Most of the information in this repo was compiled from other sources. In no particular order:

1. [Geoff Bourne aka itzg](https://github.com/itzg/) for making the Docker images for both the Java Edition and Bedrock Editions of the Minecraft server.
1. [Justin Head aka jhead](https://github.com/jhead) for the phantom LAN proxy.
1. [Pugmatt](https://github.com/Pugmatt) for the neat DNS trick to get consoles connected.
1. [Kevint at theAutomators](https://theautomaters.com/) for a [blog on running Bedrock on Kubernetes](https://theautomaters.com/minecraft-on-kubernetes/).
1. [The Java Edition Minecraft helm chart](https://github.com/helm/charts/tree/master/stable/minecraft).
1. [Jaime Pillora](https://github.com/jpillora) for the [Docker image for dnsmasq](https://github.com/jpillora/docker-dnsmasq).