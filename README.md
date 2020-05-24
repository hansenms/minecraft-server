# Minecraft Bedrock Server (Kubernetes)

This repo demonstrates how to run a Minecraft Bedrock server in Kubernetes.

## Bedrock vs Java Edition

There are really two main flavors or editions of Minecraft. The [Java Edition]() is the original edition Minecraft and it 

```bash
helm upgrade --install minecraft-server \
    --set minecraftServer.version="1.15.2" \
    --set livenessProbe.initialDelaySeconds=150 \
    --set persistence.storageClass=azurefile \
    --set minecraftServer.eula=true stable/minecraft \
    --set minecraftServer.whitelist="CloudyNerd"
```