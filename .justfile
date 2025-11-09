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
    @just _success "Development environment started!"
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

# Complete reset: clean everything and start fresh (development environment)
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

# Clean development environment (containers, volumes, images)
[group('cleanup')]
clean:
    @just _warn "Cleaning up development environment (containers, volumes, and images)..."
    @docker compose down -v --rmi local 2>/dev/null || true
    @just _info "Removing dangling images..."
    @docker image prune -f
    @just _success "Development environment cleanup completed!"

# Clean test environment (containers, volumes, images)
[group('cleanup')]
clean-test:
    @just _warn "Cleaning up test environment (containers, volumes, and images)..."
    @docker compose -f compose.test.yml down -v --rmi local 2>/dev/null || true
    @just _info "Removing dangling images..."
    @docker image prune -f
    @just _success "Test environment cleanup completed!"

# Clean both dev and test environments
[group('cleanup')]
clean-all:
    @just _warn "Cleaning up ALL environments (dev + test)..."
    @just clean
    @just clean-test
    @just _success "All environments cleaned!"

# Clean dangling images and build cache (safe, quick cleanup)
[group('cleanup')]
clean-cache:
    @just _info "Removing dangling images and build cache..."
    @docker image prune -f
    @docker builder prune -f
    @just _success "Cache cleaned!"

# Clean all unused Docker resources (frees up disk space)
[group('cleanup')]
[confirm("⚠️  This will remove all unused Docker resources. Continue?")]
prune:
    @just _info "Current disk usage BEFORE cleanup:"
    @docker system df
    @echo ""
    @just _warn "Cleaning up..."
    docker system prune -a --volumes -f
    @echo ""
    @just _info "Disk usage AFTER cleanup:"
    @docker system df
    @just _success "Cleanup complete!"

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

# Open Kafka UI in browser
[group('kafka')]
kafka-ui:
    @just _info "Opening Kafka UI at http://localhost:8181"
    @open http://localhost:8181 || xdg-open http://localhost:8181 || echo "Please open http://localhost:8181 in your browser"

# Consume messages from dev Kafka topic (from beginning)
[group('kafka')]
kafka-consume-dev:
    @just _info "Consuming messages from DEV tp-saga-sale topic (Ctrl+C to stop)..."
    docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic tp-saga-sale --from-beginning

# Consume messages from test Kafka topic (from beginning)
[group('kafka')]
kafka-consume-test:
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
    just _info "Consuming messages from TEST tp-saga-sale topic (Ctrl+C to stop)..."
    docker exec kafka-test /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:29092 --topic tp-saga-sale --from-beginning

# Run interactive saga demonstration with environment reset (using test containers)
[group('testing')]
[confirm("This will reset the TEST environment (rebuild services, restart containers, reset databases). Continue?")]
demo:
    #!/usr/bin/env bash
    set -euo pipefail
    just _info "Resetting demo environment (TEST containers)..."
    just _warn "This will rebuild services, restart all containers, and reset databases"
    echo ""
    just _info "Step 1/5: Stopping services and removing volumes..."
    docker compose -f compose.test.yml down -v
    echo ""
    just _info "Step 2/5: Rebuilding all services..."
    docker compose -f compose.test.yml build
    echo ""
    just _info "Step 3/5: Starting services with fresh databases..."
    docker compose -f compose.test.yml up -d
    echo ""
    just _info "Step 4/5: Waiting for services to be ready..."

    # Wait for all services to be healthy using docker compose
    max_wait=90
    elapsed=0

    echo "  ⏳ Waiting for all services to become healthy..."
    while [ $elapsed -lt $max_wait ]; do
        # Count healthy services
        healthy_count=$(docker compose -f compose.test.yml ps --format json | jq -r 'select(.Health == "healthy") | .Name' 2>/dev/null | wc -l | tr -d ' ')
        total_with_health=$(docker compose -f compose.test.yml ps --format json | jq -r 'select(.Health != null and .Health != "") | .Name' 2>/dev/null | wc -l | tr -d ' ')

        if [ "$healthy_count" -eq "$total_with_health" ] && [ "$total_with_health" -gt 0 ]; then
            echo "  ✓ All $healthy_count services are healthy!"
            break
        fi

        if [ $elapsed -ge $max_wait ]; then
            just _error "Timeout waiting for services to be healthy"
            echo ""
            echo "Service status:"
            docker compose -f compose.test.yml ps
            exit 1
        fi

        # Show progress every 5 seconds
        if [ $((elapsed % 5)) -eq 0 ] && [ $elapsed -gt 0 ]; then
            echo "  ... $healthy_count/$total_with_health services healthy (${elapsed}s elapsed)"
        fi

        sleep 1
        elapsed=$((elapsed + 1))
    done

    echo ""
    just _success "Demo environment reset complete!"
    just _info "All services rebuilt and databases reinitialized with test data"
    just _info "Using TEST containers on ports: 8091 (sale), 8092 (inventory), 8093 (payment)"
    echo ""
    just _info "Step 5/5: Starting interactive demo..."
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

# Show service endpoints
[group('testing')]
endpoints:
    @echo "{{BOLD}}=== Service Endpoints ==={{RESET}}"
    @just _warn "Note: These are REST APIs without web UI. Use curl, Postman, or similar tools."
    @just _info "Sale Service: http://localhost:8081"
    @echo "  POST   http://localhost:8081/api/v1/sales           - Create new sale"
    @echo "  Example:"
    @echo "    curl -X POST http://localhost:8081/api/v1/sales \\"
    @echo "      -H \"Content-Type: application/json\" \\"
    @echo "      -d '{\"userId\":1,\"productId\":6,\"quantity\":2,\"value\":200.00}'"
    @echo "  Available users: 1 (Cristiano Fonseca), 2 (Rodrigo Brayner)"
    @echo "  Available products: 6, 7, 8, 9, 10"
    @just _info "Inventory Service: http://localhost:8082"
    @echo "  (Event-driven service - listens to Kafka topics)"
    @just _info "Payment Service: http://localhost:8083"
    @echo "  (Event-driven service - listens to Kafka topics)"
    @just _info "Kafka UI: http://localhost:8181"
    @echo "  Web interface for Kafka monitoring"
    @echo "  Command: just kafka-ui (opens in browser)"

# Show sales table data (development)
[group('database')]
db-sales:
    @just _info "Recent Sales (Development)"
    @echo ""
    @docker exec sales-db-container mysql -uroot -proot sales_db --table -e "SELECT id, user_id, product_id, quantity, value, sale_status_id, CASE sale_status_id WHEN 1 THEN 'PENDING' WHEN 2 THEN 'FINALIZED' WHEN 3 THEN 'CANCELED' END as status FROM sales ORDER BY id DESC LIMIT 10;" 2>/dev/null || echo "Container not running. Start with: just up"

# Show inventory table data (development)
[group('database')]
db-inventory:
    @just _info "Current Inventory (Development)"
    @echo ""
    @docker exec inventory-db-container mysql -uroot -proot inventory_db --table -e "SELECT * FROM inventories ORDER BY product_id;" 2>/dev/null || echo "Container not running. Start with: just up"

# Show payment/user table data (development)
[group('database')]
db-payment:
    @just _info "User Balances (Development)"
    @echo ""
    @docker exec payment-db-container mysql -uroot -proot payment_db --table -e "SELECT id, name, balance FROM users ORDER BY id;" 2>/dev/null || echo "Container not running. Start with: just up"

# Show all database data (development)
[group('database')]
db-all:
    @just db-sales
    @echo ""
    @just db-inventory
    @echo ""
    @just db-payment

# Show sales table data (test environment)
[group('database')]
db-sales-test:
    @just _info "Recent Sales (Test)"
    @echo ""
    @docker exec sale-db-test mysql -uroot -proot sales_db --table -e "SELECT id, user_id, product_id, quantity, value, sale_status_id, CASE sale_status_id WHEN 1 THEN 'PENDING' WHEN 2 THEN 'FINALIZED' WHEN 3 THEN 'CANCELED' END as status FROM sales ORDER BY id DESC LIMIT 10;" 2>/dev/null || echo "Test container not running. Start with: docker compose -f compose.test.yml up -d"

# Show inventory table data (test environment)
[group('database')]
db-inventory-test:
    @just _info "Current Inventory (Test)"
    @echo ""
    @docker exec inventory-db-test mysql -uroot -proot inventory_db --table -e "SELECT * FROM inventories ORDER BY product_id;" 2>/dev/null || echo "Test container not running. Start with: docker compose -f compose.test.yml up -d"

# Show payment/user table data (test environment)
[group('database')]
db-payment-test:
    @just _info "User Balances (Test)"
    @echo ""
    @docker exec payment-db-test mysql -uroot -proot payment_db --table -e "SELECT id, name, balance FROM users ORDER BY id;" 2>/dev/null || echo "Test container not running. Start with: docker compose -f compose.test.yml up -d"

# Show all database data (test environment)
[group('database')]
db-all-test:
    @just db-sales-test
    @echo ""
    @just db-inventory-test
    @echo ""
    @just db-payment-test
