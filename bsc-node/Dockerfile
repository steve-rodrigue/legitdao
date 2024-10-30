# Use an official Go Ethereum base image (latest version)
FROM ethereum/client-go:stable

# Create a directory for blockchain data and set permissions
RUN mkdir -p /bscdata && chown -R 1000:1000 /bscdata

# Set working directory to /bsc
WORKDIR /bsc

# Copy configuration file to the container
COPY config/config.toml /bsc/config.toml

# Expose the required ports for the BSC node
EXPOSE 8545  
EXPOSE 30303  
EXPOSE 8546  

# Start the BSC node with the updated configuration
ENTRYPOINT ["geth", "--config", "/bsc/config.toml", "--datadir", "/bscdata", "--http", "--http.addr", "0.0.0.0", "--http.port", "8545", "--http.api", "eth,net,web3", "--ws", "--ws.addr", "0.0.0.0", "--ws.port", "8546", "--ws.api", "eth,net,web3", "--syncmode", "snap"]
