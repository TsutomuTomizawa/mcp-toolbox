.PHONY: help init plan apply destroy deploy logs all local-build local-start local-stop local-test

TERRAFORM_DIR = terraform
SERVER_DIR = server

help:
	@echo "MCP Toolbox BigQuery - Available Commands"
	@echo "========================================="
	@echo ""
	@echo "Production Commands:"
	@echo "  make init     - Initialize Terraform"
	@echo "  make plan     - Show infrastructure changes"
	@echo "  make apply    - Apply infrastructure"
	@echo "  make destroy  - Destroy all resources"
	@echo "  make deploy   - Deploy application"
	@echo "  make logs     - View Cloud Run logs"
	@echo "  make all      - Complete setup (init + apply + deploy)"
	@echo ""
	@echo "Local Testing Commands:"
	@echo "  make local-test  - Run local Docker tests"
	@echo "  make local-build - Build Docker image locally"
	@echo "  make local-start - Start local containers"
	@echo "  make local-stop  - Stop local containers"

init:
	@echo "Initializing Terraform..."
	@cd $(TERRAFORM_DIR) && terraform init

plan:
	@echo "Planning infrastructure changes..."
	@cd $(TERRAFORM_DIR) && terraform plan

apply:
	@echo "Applying infrastructure..."
	@cd $(TERRAFORM_DIR) && terraform apply -auto-approve

destroy:
	@echo "Destroying infrastructure..."
	@cd $(TERRAFORM_DIR) && terraform destroy

deploy:
	@echo "Deploying application..."
	@cd $(SERVER_DIR) && \
	gcloud builds submit --config cloudbuild.yaml

logs:
	@echo "Fetching logs..."
	@gcloud run logs read mcp-toolbox \
		--region=asia-northeast1 \
		--limit=50

all: init apply deploy
	@echo "✅ Complete setup finished!"

# ローカルテストコマンド
local-build:
	@echo "Building Docker image..."
	@docker-compose build

local-start:
	@echo "Starting container..."
	@docker-compose up -d
	@echo "Service URL: http://localhost:8080"

local-stop:
	@echo "Stopping container..."
	@docker-compose down

local-test:
	@echo "Testing API endpoints..."
	@curl -s http://localhost:8080/health || echo "Health check failed"
	@curl -s -X POST http://localhost:8080/mcp \
		-H "Content-Type: application/json" \
		-d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' | jq '.result.tools[].name' 2>/dev/null || echo "MCP test failed"