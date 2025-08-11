# MCP Toolbox Docker Image
FROM us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:0.11.0

# Copy custom config file with BigQuery tools only
COPY tools.yaml /app/tools.yaml

# Port for Cloud Run
EXPOSE 8080

# Start MCP Toolbox with custom config
# Note: The base image already has ENTRYPOINT ["/toolbox"]
# We only need to provide the arguments
CMD ["--tools-file", "/app/tools.yaml", "--port", "8080", "--address", "0.0.0.0", "--log-level", "INFO"]