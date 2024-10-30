---
title: "Setting Up a Binance Smart Chain (BSC) Node for LegitDAO Using Docker"
meta_title: "BSC Node Setup for LegitDAO Using Docker"
description: "A step-by-step guide on how to set up a Binance Smart Chain (BSC) node using Docker and Docker Compose for the LegitDAO project."
date: 2024-10-29T05:00:00Z
image: "/images/blogs/docker-bsc.jpg"
categories: ["DAO", "Dev Ops"]
author: "Pascal Germain"
tags: ["dev-ops", "docker"]
draft: false
---
In this guide, we'll show you how to configure and run a **Binance Smart Chain (BSC) node** using Docker and Docker Compose. This setup is specifically tailored for the LegitDAO project to ensure efficient blockchain interaction with persistence, automatic restarts, and WebSocket support.

For more general information on how to contribute and clone LegitDAO, refer to our [Contributing to LegitDAO Guide](/4-contributetolegitdao). This post focuses on the specific task of adding the **Binance Smart Chain Node** to the LegitDAO project using Docker.

## Project Structure
Here’s a look at the project folder structure for the BSC node setup:

```plaintext
projects/infrastructure/blockchains/bsc/
├── bscdata/                  # Directory to store blockchain data (persisted outside the container)
├── config/
│   └── config.toml           # BSC node configuration file
├── Dockerfile                # Dockerfile to build the BSC node
├── docker-compose.yml        # Docker Compose configuration
└── README.md                 # Project documentation (this file)
```

## Configuration Breakdown

### Dockerfile
The `Dockerfile` is the script that builds the Docker image for the BSC node. Here’s an overview of its functionality:

```Dockerfile
# Use an official Go Ethereum base image (latest version)
FROM ethereum/client-go:stable

# Create a directory for blockchain data and set permissions
RUN mkdir -p /bscdata && chown -R 1000:1000 /bscdata

# Set working directory to /bsc
WORKDIR /bsc

# Copy configuration file to the container
COPY config/config.toml /bsc/config.toml

# Expose the required ports for the BSC node
EXPOSE 8545  # HTTP RPC port
EXPOSE 30303  # P2P port for peer discovery
EXPOSE 8546  # WebSocket port

# Start the BSC node with the updated configuration
ENTRYPOINT ["geth", "--config", "/bsc/config.toml", "--datadir", "/bscdata", "--http", "--http.addr", "0.0.0.0", "--http.port", "8545", "--http.api", "eth,net,web3", "--ws", "--ws.addr", "0.0.0.0", "--ws.port", "8546", "--ws.api", "eth,net,web3", "--syncmode", "snap"]
```

**Explanation**:
- **Base Image**: It uses the official Go Ethereum client (`ethereum/client-go:stable`) to run the BSC node.
- **Blockchain Data Persistence**: The `/bscdata` folder inside the container stores blockchain data.
- **Ports Exposed**: Ports for HTTP RPC, P2P, and WebSocket are exposed to interact with the node.
- **Node Start Command**: It starts the BSC node with the necessary configuration, exposing HTTP and WebSocket endpoints for client connections.

### Docker Compose Configuration
The `docker-compose.yml` defines the BSC node as a service. It maps ports, persists data, and ensures the container restarts automatically if it stops.

```yaml
version: '3.8'
services:
  bsc-node:
    build: .
    container_name: bsc-node
    ports:
      - "8545:8545"  # HTTP RPC port
      - "30303:30303"  # P2P port
      - "8546:8546"  # WebSocket port
    volumes:
      - ./bscdata:/bscdata  # External volume to persist blockchain data
      - ./config:/bsc  # Config folder with config.toml
    restart: always  # Automatically restart the container if it stops
```

**Key Points**:
- **Volumes**:
  - `./bscdata:/bscdata`: Stores blockchain data outside the container for persistence.
  - `./config:/bsc`: Maps the local `config.toml` file into the container so configuration changes are reflected.
- **Restart Policy**: The `restart: always` ensures the node is automatically restarted in case of a failure.

## Setup and Usage

### Step 1: Clone the Repository
If you haven't already, clone the repository where this setup is hosted:

```bash
git clone https://your-repository-url/bsc-node.git
cd bsc-node
```

### Step 2: Update `config.toml` (Optional)
You can modify the `config.toml` file located in the `config/` directory to suit your needs. By default, the setup syncs with the Binance Smart Chain Mainnet and uses the `snap` sync mode for faster synchronization.

Example `config.toml`:

```toml
[Eth]
NetworkId = 56  # BSC Mainnet
SyncMode = "snap"  # Use "snap" sync mode for faster synchronization
```

### Step 3: Build and Run the BSC Node
Use Docker Compose to build and start the BSC node. This command will create the image and start the container:

```bash
docker-compose up --build
```

Docker Compose will:
- Build the Docker image.
- Start the BSC node.
- Persist blockchain data in the `bscdata/` folder.

### Step 4: Monitor Sync Progress
You can monitor the sync progress by checking the logs. Run the following command to view the logs:

```bash
docker logs -f bsc-node
```

The logs will show the node searching for peers and syncing with the Binance Smart Chain.

### Step 5: Interact with the Node
Once the node is running, you can interact with it using the following commands:

- **Get the Current Block Number**:
  ```bash
  curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" http://localhost:8545
  ```

- **Connect via WebSocket**:
  ```bash
  ws://localhost:8546
  ```

### Step 6: Stop the Node
To stop the node, press `Ctrl + C` in the terminal or use:

```bash
docker-compose down
```

## Troubleshooting

### No Peers Found
If the node cannot find peers, ensure that port `30303` is open and accessible. Also, ensure that Docker Desktop has enough resources allocated (e.g., CPU, memory).

### Slow Syncing
If the node syncs slowly, you can increase the cache size in the `config.toml` file:

```toml
[Eth]
NetworkId = 56
SyncMode = "snap"
Cache = 4096  # Increase the cache size for faster synchronization
```

## Additional Resources
- [Binance Smart Chain Documentation](https://docs.bnbchain.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

This setup provides an easy way to run a Binance Smart Chain node using Docker. Follow the steps, and you'll have a fully functional node up and running with persistent blockchain data. If you need help, feel free to ask questions or refer to the resources linked above.
