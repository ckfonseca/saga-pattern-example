# Load environment variables from .env file
set dotenv-load

# Colors
RED := '\033[0;31m'
GREEN := '\033[0;32m'
YELLOW := '\033[0;33m'
BLUE := '\033[0;34m'
CYAN := '\033[0;36m'
BOLD := '\033[1m'
RESET := '\033[0m'

# Default recipe (show help when running just without arguments)
_default:
    @just --list

# Helper functions for printing colored messages
_info message:
    @echo "{{BLUE}}[INFO]{{RESET}} {{message}}"

_success message:
    @echo "{{GREEN}}[SUCCESS]{{RESET}} {{message}}"

_warn message:
    @echo "{{YELLOW}}[WARN]{{RESET}} {{message}}"

_error message:
    @echo "{{RED}}[ERROR]{{RESET}} {{message}}"

# Start all development services
[group('general')]
up:
    @just _info "Starting development environment..."
    docker compose up -d --build
    @echo ""
    @just _info "Waiting for all services to become healthy..."
    docker compose up -d --wait
    @echo ""
    @just _success "Development environment ready!"
    @echo ""
    @just _info "Service endpoints:"
    @echo "  • Sale Service:      http://localhost:8081"
    @echo "  • Inventory Service: http://localhost:8082"
    @echo "  • Payment Service:   http://localhost:8083"
    @echo "  • Kafka UI:          http://localhost:8181"
    @echo ""
    @just _info "Tip: Run 'just logs' to see all logs"

# Stop all development services
[group('general')]
down:
    @just _info "Stopping development environment..."
    docker compose down

# Restart all services
[group('general')]
restart:
    @just down
    @just up

# Full rebuild: removes volumes, images, cache and rebuilds everything from scratch
[group('general')]
reset:
    @just _warn "Complete Development Environment Reset"
    @echo ""
    @just _info "Step 1/4: Stopping services..."
    @docker compose down -v --rmi local 2>/dev/null || true
    @echo ""
    @just _info "Step 2/4: Removing dangling images and build cache..."
    @docker image prune -f
    @docker builder prune -f
    @echo ""
    @just _info "Step 3/4: Building all images (no cache)..."
    docker compose build --no-cache
    @echo ""
    @just _success "All images built successfully!"
    @echo ""
    @just _info "Step 4/4: Starting services..."
    @just up
    @echo ""
    @just _success "Development Environment Reset Complete!"
    @just _success "Databases initialized with test data automatically!"

# Clean everything related to the application (dev, test, volumes, images, cache)
[group('cleanup')]
clean:
    @just _warn "Cleaning up ALL application resources..."
    @echo ""
    @just _info "Step 1/4: Stopping and removing development environment..."
    @docker compose down -v --rmi local 2>/dev/null || true
    @echo ""
    @just _info "Step 2/4: Stopping and removing test environment..."
    @docker compose -f compose.test.yml down -v --rmi local 2>/dev/null || true
    @echo ""
    @just _info "Step 3/4: Removing dangling images..."
    @docker image prune -f
    @echo ""
    @just _info "Step 4/4: Removing build cache..."
    @docker builder prune -f
    @echo ""
    @just _success "All application resources cleaned!"
    @just _info "Tip: Run 'just up' to start fresh"

# Show logs from all services
[group('monitoring')]
logs:
    docker compose logs -f

# Show logs from infrastructure services
[group('monitoring')]
logs-infra:
    docker compose logs -f kafka-service kafka-ui sale-db-service inventory-db-service payment-db-service

# Show logs from application services
[group('monitoring')]
logs-app:
    docker compose logs -f sale-service inventory-service payment-service

# Open Kafbat UI in browser
[group('kafka')]
kafka-ui:
    #!/usr/bin/env bash
    set -euo pipefail
    just _info "Opening Kafbat UI at http://localhost:8181"

    if [[ "{{os()}}" == "macos" ]]; then
        open http://localhost:8181 2>/dev/null || true
    elif [[ "{{os()}}" == "linux" ]]; then
        (xdg-open http://localhost:8181 || google-chrome http://localhost:8181 || chromium http://localhost:8181) 2>/dev/null || echo "⚠️  Could not open browser automatically"
    else
        echo "⚠️  Could not open browser automatically"
    fi

    echo ""
    just _info "Kafbat UI: http://localhost:8181"

# Show Kafka messages from development environment
[group('kafka')]
kafka-show-messages:
    @just _info "Consuming messages from DEV ${KAFKA_TOPIC} topic (Ctrl+C to stop)..."
    docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic ${KAFKA_TOPIC} --from-beginning

# Show Kafka messages from test environment (used by demo)
[group('kafka')]
kafka-show-messages-test:
    #!/usr/bin/env bash
    set -euo pipefail
    just _info "Waiting for test environment to start..."
    timeout=120
    elapsed=0
    # Using printf to avoid issues with template syntax
    name_format='{{ '{{' }}.Names{{ '}}' }}'
    while ! docker ps --format "$name_format" | grep -q '^kafka-test$'; do
        if [ $elapsed -ge $timeout ]; then
            just _error "Timeout waiting for kafka-test container to start"
            echo ""
            just _info "The test environment starts automatically when running: just test"
            exit 1
        fi
        if [ $elapsed -eq 0 ]; then
            echo "  Waiting for kafka-test container"
        fi
        printf "."
        sleep 2
        elapsed=$((elapsed + 2))
    done
    echo ""
    just _success "kafka-test container found!"
    just _info "Waiting for kafka-test to be healthy..."
    timeout=120
    elapsed=0
    health_format='{{ '{{' }}.State.Health.Status{{ '}}' }}'
    while [ "$(docker inspect --format="$health_format" kafka-test 2>/dev/null)" != "healthy" ]; do
        if [ $elapsed -ge $timeout ]; then
            just _error "Timeout waiting for kafka-test to become healthy"
            exit 1
        fi
        printf "."
        sleep 2
        elapsed=$((elapsed + 2))
    done
    echo ""
    just _success "kafka-test is healthy!"
    just _info "Consuming messages from TEST ${KAFKA_TOPIC} topic (Ctrl+C to stop)..."
    docker exec kafka-test /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic ${KAFKA_TOPIC} --from-beginning

# Run interactive saga demonstration with environment reset (using test containers)
[group('testing')]
[confirm("This will reset the TEST environment (rebuild services, restart containers, reset databases). Continue?")]
demo:
    #!/usr/bin/env bash
    set -euo pipefail
    just _info "Resetting demo environment (TEST containers)..."
    just _warn "This will rebuild services, restart all containers, and reset databases"
    echo ""
    just _info "Step 1/4: Stopping services and removing volumes..."
    docker compose -f compose.test.yml down -v
    echo ""
    just _info "Step 2/4: Rebuilding all services..."
    docker compose -f compose.test.yml build
    echo ""
    just _info "Step 3/4: Starting services and waiting for healthy status..."
    docker compose -f compose.test.yml up -d --wait
    echo ""
    just _success "Demo environment reset complete!"
    just _info "All services rebuilt and databases reinitialized with test data"
    just _info "Using TEST containers on ports: 8091 (sale), 8092 (inventory), 8093 (payment)"
    echo ""
    just _info "Step 4/4: Starting interactive demo..."
    chmod +x scripts/demo-saga.sh
    SALE_SERVICE_URL="http://localhost:8091/api/v1/sales" \
    SALE_DB_CONTAINER="sale-db-test" \
    INVENTORY_DB_CONTAINER="inventory-db-test" \
    PAYMENT_DB_CONTAINER="payment-db-test" \
    ./scripts/demo-saga.sh

    echo ""
    just _info "Cleaning up test environment..."
    docker compose -f compose.test.yml down -v
    just _success "Test environment cleaned up!"

# Run automated integration test suite (CI/CD ready)
[group('testing')]
test:
    @just _info "Running automated integration tests..."
    @chmod +x tests/integration/integration-test.sh
    @./tests/integration/integration-test.sh

# Show service endpoints and usage examples
[group('documentation')]
api-doc:
    @echo ""
    @echo "{{BOLD}}{{CYAN}}════════════════════════════════════════════════════════════════════════════════{{RESET}}"
    @echo "{{BOLD}}{{CYAN}}                          SERVICE ENDPOINTS                                     {{RESET}}"
    @echo "{{BOLD}}{{CYAN}}════════════════════════════════════════════════════════════════════════════════{{RESET}}"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}📦 Sale Service{{RESET}}"
    @echo "   {{GREEN}}http://localhost:8081{{RESET}}"
    @echo ""
    @echo "   POST /api/v1/sales - Create new sale"
    @echo ""
    @echo "   {{BOLD}}Example:{{RESET}}"
    @printf "   curl -i -X POST http://localhost:8081/api/v1/sales \\\\\n"
    @printf "     -H \"Content-Type: application/json\" \\\\\n"
    @printf "     -d '{\"userId\":1,\"productId\":6,\"quantity\":2,\"value\":200.00}'\n"
    @echo ""
    @echo "   Available users: 1 (Cristiano Fonseca), 2 (Rodrigo Brayner)"
    @echo "   Available products: 6, 7, 8, 9, 10"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}📊 Inventory Service{{RESET}}"
    @echo "   {{GREEN}}http://localhost:8082{{RESET}}"
    @echo "   (Event-driven - listens to Kafka topics)"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}💳 Payment Service{{RESET}}"
    @echo "   {{GREEN}}http://localhost:8083{{RESET}}"
    @echo "   (Event-driven - listens to Kafka topics)"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}🔍 Kafbat UI (Kafka Management){{RESET}}"
    @echo "   {{GREEN}}http://localhost:8181{{RESET}}"
    @echo "   Command: {{CYAN}}just kafka-ui{{RESET}}"
    @echo ""
    @echo "{{BOLD}}{{CYAN}}════════════════════════════════════════════════════════════════════════════════{{RESET}}"
    @echo ""

# Show all database tables (development)
[group('database')]
db-show:
    @echo ""
    @echo "{{BOLD}}{{CYAN}}════════════════════════════════════════════════════════════════════════════════{{RESET}}"
    @echo "{{BOLD}}{{CYAN}}                    DATABASE STATUS - DEVELOPMENT                              {{RESET}}"
    @echo "{{BOLD}}{{CYAN}}════════════════════════════════════════════════════════════════════════════════{{RESET}}"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}📊 Recent Sales{{RESET}}"
    @echo ""
    @docker exec sale-db mysql -u root -p${SALE_DB_ROOT_PWD} ${SALE_DB_NAME} --table -e "SELECT id, user_id, product_id, quantity, value, sale_status_id, CASE sale_status_id WHEN 1 THEN 'PENDING' WHEN 2 THEN 'FINALIZED' WHEN 3 THEN 'CANCELED' END as status FROM sales ORDER BY id DESC LIMIT 10;" 2>/dev/null || echo "  ❌ Container not running. Start with: just up"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}📦 Current Inventory{{RESET}}"
    @echo ""
    @docker exec inventory-db mysql -u root -p${INVENTORY_DB_ROOT_PWD} ${INVENTORY_DB_NAME} --table -e "SELECT * FROM inventories ORDER BY product_id;" 2>/dev/null || echo "  ❌ Container not running. Start with: just up"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}💰 User Balances{{RESET}}"
    @echo ""
    @docker exec payment-db mysql -u root -p${PAYMENT_DB_ROOT_PWD} ${PAYMENT_DB_NAME} --table -e "SELECT id, name, balance FROM users ORDER BY id;" 2>/dev/null || echo "  ❌ Container not running. Start with: just up"
    @echo ""
    @echo "{{BOLD}}{{CYAN}}════════════════════════════════════════════════════════════════════════════════{{RESET}}"
    @echo ""

# Show all database tables (test environment - used by demo)
[group('database')]
db-show-test:
    @echo ""
    @echo "{{BOLD}}{{CYAN}}════════════════════════════════════════════════════════════════════════════════{{RESET}}"
    @echo "{{BOLD}}{{CYAN}}                      DATABASE STATUS - TEST                                    {{RESET}}"
    @echo "{{BOLD}}{{CYAN}}════════════════════════════════════════════════════════════════════════════════{{RESET}}"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}📊 Recent Sales{{RESET}}"
    @echo ""
    @docker exec sale-db-test mysql -u root -p${SALE_DB_ROOT_PWD} ${SALE_DB_NAME} --table -e "SELECT id, user_id, product_id, quantity, value, sale_status_id, CASE sale_status_id WHEN 1 THEN 'PENDING' WHEN 2 THEN 'FINALIZED' WHEN 3 THEN 'CANCELED' END as status FROM sales ORDER BY id DESC LIMIT 10;" 2>/dev/null || echo "  ❌ Test container not running. Start with: docker compose -f compose.test.yml up -d"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}📦 Current Inventory{{RESET}}"
    @echo ""
    @docker exec inventory-db-test mysql -u root -p${INVENTORY_DB_ROOT_PWD} ${INVENTORY_DB_NAME} --table -e "SELECT * FROM inventories ORDER BY product_id;" 2>/dev/null || echo "  ❌ Test container not running. Start with: docker compose -f compose.test.yml up -d"
    @echo ""
    @echo "{{BOLD}}{{YELLOW}}💰 User Balances{{RESET}}"
    @echo ""
    @docker exec payment-db-test mysql -u root -p${PAYMENT_DB_ROOT_PWD} ${PAYMENT_DB_NAME} --table -e "SELECT id, name, balance FROM users ORDER BY id;" 2>/dev/null || echo "  ❌ Test container not running. Start with: docker compose -f compose.test.yml up -d"
    @echo ""
    @echo "{{BOLD}}{{CYAN}}════════════════════════════════════════════════════════════════════════════════{{RESET}}"
    @echo ""
