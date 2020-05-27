# Bedrock Connect Docker Image

This Dockerfile builds the [BedrockConnect](https://github.com/Pugmatt/BedrockConnect) serverlist-server.

Build it with:

```bash
docker build -t bedrock-connect .
```

Run it with:

```bash
docker run --name "brc" -d --restart always -p 19132:19132/udp bedrock-connect
```

Or use the provided helm chart

```bash
helm install brc helm/bedrock-connect/ --set service.ipAddress="XXX.XXX.XXX.XXX" --set service.ipAddressResourceGroup="my-ip-address-rg"
```

The specific IP address specification and resource group will work when running in AKS. The service principal should have contributor rights on thet resource group.