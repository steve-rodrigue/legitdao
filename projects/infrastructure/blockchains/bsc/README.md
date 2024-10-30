### `README.md`

```markdown
# Binance Smart Chain Node Setup

This project sets up a Binance Smart Chain (BSC) node using Docker and Docker Compose. The setup includes configuration for running the BSC node with a persistent data directory, automatic restarts, and support for HTTP and WebSocket connections.

## Requirements

Before you begin, ensure you have the following installed:

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Project Structure

```plaintext
bsc-node/
├── bscdata/                  # Directory to store blockchain data (persisted outside the container)
├── config/
│   └── config.toml           # BSC node configuration file
├── Dockerfile                # Dockerfile to build the BSC node
├── docker-compose.yml        # Docker Compose configuration
└── README.md                 # Project documentation (this file)
```

## Setup and Usage

### Step 1: Clone the Repository

If you haven’t already, clone the repository containing this setup:

```bash
git clone https://your-repository-url/bsc-node.git
cd bsc-node
```

### Step 2: Update `config.toml` (Optional)

The configuration file for the BSC node is located in the `config/` directory. You can modify it based on your needs. By default, the setup uses the BSC Mainnet (network ID `56`) and syncs in `snap` mode.

Example of `config/config.toml`:

```toml
[Eth]
NetworkId = 56  # BSC Mainnet
SyncMode = "snap"  # Use "snap" sync mode for fast synchronization
```

### Step 3: Build and Run the BSC Node

To build and start the BSC node, use Docker Compose. This command will build the Docker image and start the container:

```bash
docker-compose up --build
```

Docker Compose will:
- Build the Docker image based on the provided `Dockerfile`.
- Start the BSC node, exposing ports `8545` (HTTP RPC), `8546` (WebSocket), and `30303` (P2P).
- Persist blockchain data in the `bscdata/` folder on the host machine.

### Step 4: Check Logs and Monitor Sync Progress

You can view the logs to track the node's progress and see the synchronization status:

```bash
docker logs -f bsc-node
```

The BSC node will initially search for peers and start syncing the blockchain from the BSC network. This process can take some time, depending on your network connection.

### Step 5: Interact with the BSC Node

Once the node is up and running, you can interact with it using the HTTP RPC or WebSocket endpoints.

- **Get the current block number**:
  
  ```bash
  curl -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" http://localhost:8545
  ```

  The response will include the current block number that the node has synced to.

- **Test the WebSocket connection**:

  You can use a WebSocket client (e.g., `websocat`) to connect to the node at `ws://localhost:8546`.

### Step 6: Stopping the Node

To stop the node, press `Ctrl + C` in the terminal running the node, or run:

```bash
docker-compose down
```

This will stop the container, but the blockchain data will remain persisted in the `bscdata/` directory.

## Configuration Details

### Dockerfile

The Dockerfile is used to build the BSC node from the official Go Ethereum image. It exposes necessary ports and sets up the configuration for running the node.

### docker-compose.yml

The `docker-compose.yml` file orchestrates the setup of the BSC node service. It ensures the node starts automatically, handles port mapping, and persists blockchain data outside the Docker container.

### Ports

- `8545`: HTTP RPC port for JSON-RPC API requests.
- `8546`: WebSocket port for real-time interactions with the node.
- `30303`: P2P port for syncing with the BSC network.

## Troubleshooting

### No Peers Found

If the node is unable to find peers, ensure the following:
- Your network allows traffic on port `30303` (P2P).
- Docker Desktop has sufficient resource allocation (e.g., CPU and memory).
- Check the logs for any additional error messages.

### Syncing is Slow

If syncing is taking longer than expected, consider increasing the cache size in `config.toml` to improve performance. For example:

```toml
[Eth]
NetworkId = 56
SyncMode = "snap"
Cache = 4096  # Increase cache to 4GB
```

## Additional Resources

- [Binance Smart Chain Documentation](https://docs.bnbchain.org/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
```

### Key Points:
- **Structure**: Describes the project folder and file structure.
- **Setup Steps**: Clear steps to clone, build, and run the BSC node.
- **Interaction**: Shows how to interact with the node using `curl` or other tools.
- **Configuration**: Details on configuration files and ports used by the node.
- **Troubleshooting**: Suggestions for common issues such as slow syncing or no peers found.

