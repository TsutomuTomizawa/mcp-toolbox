#!/bin/bash
set -e

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}==================================${NC}"
echo -e "${BLUE}MCP Toolbox Local Testing${NC}"
echo -e "${BLUE}==================================${NC}"

ACTION=${1:-help}

show_help() {
    echo "Usage: ./scripts/local-test.sh [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build     - Build Docker image"
    echo "  start     - Start container"
    echo "  stop      - Stop container"
    echo "  restart   - Restart container"
    echo "  logs      - Show logs"
    echo "  test      - Run API tests"
    echo "  clean     - Clean up everything"
    echo ""
}

build() {
    echo -e "${BLUE}Building Docker image...${NC}"
    docker-compose build
    echo -e "${GREEN}✓ Build complete${NC}"
}

start() {
    echo -e "${BLUE}Starting container...${NC}"
    docker-compose up -d
    echo -e "${GREEN}✓ Container started${NC}"
    echo ""
    echo "Service URL: http://localhost:8080"
    echo "Health check: http://localhost:8080/health"
}

stop() {
    echo -e "${BLUE}Stopping container...${NC}"
    docker-compose down
    echo -e "${GREEN}✓ Container stopped${NC}"
}

restart() {
    stop
    start
}

logs() {
    echo -e "${BLUE}Showing logs...${NC}"
    docker-compose logs -f mcp-toolbox
}

test_api() {
    echo -e "${BLUE}Testing API endpoints...${NC}"
    
    echo -n "Health check: "
    if curl -s http://localhost:8080/health > /dev/null; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
        exit 1
    fi
    
    echo -n "MCP endpoint: "
    response=$(curl -s -X POST http://localhost:8080/mcp \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' || echo "")
    
    if echo "$response" | grep -q "jsonrpc"; then
        echo -e "${GREEN}✓ OK${NC}"
        echo -e "${BLUE}Available tools:${NC}"
        echo "$response" | jq -r '.result.tools[].name' 2>/dev/null || echo "$response"
    else
        echo -e "${RED}✗ Failed${NC}"
        echo "Response: $response"
    fi
}

clean() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    docker-compose down -v
    docker rmi mcp-toolbox-mcp-toolbox 2>/dev/null || true
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        exit 1
    fi
}

check_docker

case "$ACTION" in
    build)
        build
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs
        ;;
    test)
        test_api
        ;;
    clean)
        clean
        ;;
    help|*)
        show_help
        ;;
esac