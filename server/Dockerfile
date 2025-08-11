# MCP Toolbox Docker Image
FROM us-central1-docker.pkg.dev/database-toolbox/toolbox/toolbox:0.11.0

# Copy custom config file with BigQuery tools only
COPY tools.yaml /config/tools.yaml

# Port for Cloud Run
EXPOSE 8080

# Start MCP Toolbox with custom config
CMD ["--tools-file", "/config/tools.yaml"]