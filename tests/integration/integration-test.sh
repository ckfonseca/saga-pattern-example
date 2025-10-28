#!/bin/bash

# ========================================
# Saga Pattern - Integration Test Suite
# ========================================
# This script runs automated integration tests to verify the Saga Pattern implementation
# Tests run against isolated test containers (compose.test.yml)

set -e  # Exit on first error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test environment configuration
SALE_SERVICE_URL="http://localhost:8091/api/v1/sales"
COMPOSE_FILE="compose.test.yml"
MAX_WAIT_SECONDS=30
POLL_INTERVAL_SECONDS=1

# Sale status constants (matching database enum)
SALE_STATUS_PENDING=1
SALE_STATUS_FINALIZED=2
SALE_STATUS_CANCELED=3

# Database containers and databases
SALE_DB_CONTAINER="sale-db-test"
SALE_DATABASE="sales_db"
INVENTORY_DB_CONTAINER="inventory-db-test"
INVENTORY_DATABASE="inventory_db"
PAYMENT_DB_CONTAINER="payment-db-test"
PAYMENT_DATABASE="payment_db"

# Test data constants
USER_CRISTIANO=1
USER_RODRIGO=2
PRODUCT_6=6
PRODUCT_7=7
PRODUCT_8=8
PRODUCT_9=9
PRODUCT_10=10

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ========================================
# UTILITY FUNCTIONS
# ========================================

# Function to print test header
print_test_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  TEST: $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# Function to print test result
print_test_result() {
    local test_name=$1
    local expected=$2
    local actual=$3

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$expected" == "$actual" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}✓ PASS${NC} - $test_name"
        echo -e "  Expected: $expected, Got: $actual"
        return 0
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}✗ FAIL${NC} - $test_name"
        echo -e "  Expected: $expected, Got: $actual"
        return 1
    fi
}

# Function to assert value equals
assert_equals() {
    local description=$1
    local expected=$2
    local actual=$3

    print_test_result "$description" "$expected" "$actual"
}

# Function to assert value is greater than or equal
assert_gte() {
    local description=$1
    local actual=$2
    local minimum=$3

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [ "$actual" -ge "$minimum" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        echo -e "${GREEN}✓ PASS${NC} - $description"
        echo -e "  Expected: >= $minimum, Got: $actual"
        return 0
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo -e "${RED}✗ FAIL${NC} - $description"
        echo -e "  Expected: >= $minimum, Got: $actual"
        return 1
    fi
}

# Function to query database
query_db() {
    local container=$1
    local database=$2
    local query=$3

    docker exec "$container" mysql -uroot -proot "$database" -se "$query" 2>/dev/null
}

# Function to get sale status
get_sale_status() {
    local sale_id=$1
    local status=$(query_db "$SALE_DB_CONTAINER" "$SALE_DATABASE" "SELECT CASE sale_status_id WHEN $SALE_STATUS_PENDING THEN 'PENDING' WHEN $SALE_STATUS_FINALIZED THEN 'FINALIZED' WHEN $SALE_STATUS_CANCELED THEN 'CANCELED' END FROM sales WHERE id = $sale_id;")
    echo "$status"
}

# Function to get user balance
get_user_balance() {
    local user_id=$1
    local balance=$(query_db "$PAYMENT_DB_CONTAINER" "$PAYMENT_DATABASE" "SELECT balance FROM users WHERE id = $user_id;")
    echo "$balance"
}

# Function to get product inventory
get_product_inventory() {
    local product_id=$1
    local inventory=$(query_db "$INVENTORY_DB_CONTAINER" "$INVENTORY_DATABASE" "SELECT quantity FROM inventories WHERE product_id = $product_id;")
    echo "$inventory"
}

# Function to execute a sale and return the HTTP status code
execute_sale() {
    local user_id=$1
    local product_id=$2
    local quantity=$3
    local value=$4

    local http_status=$(curl -s -o /dev/null -w "%{http_code}" \
      --max-time 10 \
      -X POST "$SALE_SERVICE_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"userId\": $user_id,
        \"productId\": $product_id,
        \"quantity\": $quantity,
        \"value\": $value
      }")

    echo "$http_status"
}

# Function to get last sale ID
get_last_sale_id() {
    local sale_id=$(query_db "$SALE_DB_CONTAINER" "$SALE_DATABASE" "SELECT MAX(id) FROM sales;")
    echo "$sale_id"
}

# Function to wait for all sagas to complete (no pending sales)
wait_for_all_sagas_completion() {
    local max_wait=${1:-20}

    echo -e "${YELLOW}⏳ Waiting for all concurrent sagas to complete...${NC}"

    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        local pending_count=$(query_db "$SALE_DB_CONTAINER" "$SALE_DATABASE" "SELECT COUNT(*) FROM sales WHERE sale_status_id = $SALE_STATUS_PENDING;")
        if [ "$pending_count" == "0" ]; then
            echo -e "${GREEN}✓ All concurrent sagas completed (took ${elapsed}s)${NC}"
            return 0
        fi
        sleep $POLL_INTERVAL_SECONDS
        elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
    done

    echo -e "${RED}✗ Timeout: Some sagas still pending after ${max_wait}s${NC}"
    return 1
}

# ========================================
# IMPROVED FUNCTIONS (NO MORE SLEEPS!)
# ========================================

# Wait for service to be healthy with polling (replaces hardcoded sleep)
wait_for_service_health() {
    local service_name=$1
    local health_url=$2
    local max_wait=${3:-$MAX_WAIT_SECONDS}

    echo -e "${YELLOW}⏳ Waiting for $service_name to be healthy (polling every ${POLL_INTERVAL_SECONDS}s, max ${max_wait}s)...${NC}"

    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        if curl -s --max-time 2 "$health_url" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ $service_name is healthy (took ${elapsed}s)${NC}"
            return 0
        fi
        sleep $POLL_INTERVAL_SECONDS
        elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
    done

    echo -e "${RED}✗ Timeout waiting for $service_name to be healthy${NC}"
    return 1
}

# Wait for saga completion with polling (replaces hardcoded sleeps)
wait_for_saga_completion() {
    local sale_id=$1
    local expected_status=$2
    local max_wait=${3:-$MAX_WAIT_SECONDS}

    echo -e "${YELLOW}⏳ Waiting for saga to reach status '$expected_status' (polling every ${POLL_INTERVAL_SECONDS}s, max ${max_wait}s)...${NC}"

    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        local current_status=$(get_sale_status "$sale_id")

        # If reached expected status, return immediately
        if [ "$current_status" == "$expected_status" ]; then
            echo -e "${GREEN}✓ Saga completed in ${elapsed}s (status: $current_status)${NC}"
            return 0
        fi

        # If status is not PENDING, saga finished but with different status
        if [ "$current_status" != "PENDING" ] && [ "$current_status" != "" ]; then
            echo -e "${YELLOW}⚠ Saga finished with status: $current_status (after ${elapsed}s)${NC}"
            return 0
        fi

        sleep $POLL_INTERVAL_SECONDS
        elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
    done

    echo -e "${RED}✗ Timeout waiting for saga (current status: $(get_sale_status "$sale_id"))${NC}"
    return 1
}

# Wait for Kafka to be ready
wait_for_kafka() {
    local container=$1
    local max_wait=${2:-30}

    echo -e "${YELLOW}⏳ Waiting for Kafka to be ready (polling every ${POLL_INTERVAL_SECONDS}s, max ${max_wait}s)...${NC}"

    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        if docker exec "$container" kafka-topics --bootstrap-server localhost:29092 --list > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Kafka is ready (took ${elapsed}s)${NC}"
            return 0
        fi
        sleep $POLL_INTERVAL_SECONDS
        elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
    done

    echo -e "${RED}✗ Timeout waiting for Kafka${NC}"
    return 1
}

# ========================================
# MAIN TEST EXECUTION
# ========================================

echo ""
echo -e "${BOLD}${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        SAGA PATTERN - AUTOMATED TEST SUITE                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${YELLOW}Starting test environment...${NC}"
echo ""

# Ensure test environment is clean
echo -e "${BLUE}Cleaning up previous test environment...${NC}"
docker compose -f $COMPOSE_FILE down -v --remove-orphans 2>/dev/null || true

echo -e "${BLUE}Starting test containers...${NC}"
docker compose -f $COMPOSE_FILE up -d --build

# Wait for services to be healthy (NO MORE HARDCODED SLEEP!)
wait_for_service_health "Sale Service" "http://localhost:8091/actuator/health" 60
wait_for_service_health "Inventory Service" "http://localhost:8092/actuator/health" 60
wait_for_service_health "Payment Service" "http://localhost:8093/actuator/health" 60

# Wait for Kafka and create topics
wait_for_kafka "kafka-test" 30
echo -e "${BLUE}Creating Kafka topics...${NC}"
docker exec kafka-test kafka-topics --bootstrap-server localhost:29092 --create --if-not-exists --topic tp-saga-sale --partitions 3 --replication-factor 1 2>/dev/null || true

echo -e "${GREEN}Test environment ready!${NC}"
echo ""

# ========================================
# TEST 1: Successful Purchase (Happy Path)
# ========================================
print_test_header "Scenario 1: Successful Purchase"

echo "Setup: User 1 has R\$ 1000.00, Product 6 has 10 units"
echo "Action: User 1 buys 2 units of Product 6 for R\$ 200.00"
echo ""

initial_balance=$(get_user_balance $USER_CRISTIANO)
initial_inventory=$(get_product_inventory $PRODUCT_6)

http_status=$(execute_sale $USER_CRISTIANO $PRODUCT_6 2 200.00)
assert_equals "HTTP Status should be 201 Created" "201" "$http_status"

sale_id=$(get_last_sale_id)
wait_for_saga_completion "$sale_id" "FINALIZED" 15

sale_status=$(get_sale_status "$sale_id")
final_balance=$(get_user_balance $USER_CRISTIANO)
final_inventory=$(get_product_inventory $PRODUCT_6)

assert_equals "Sale status should be FINALIZED" "FINALIZED" "$sale_status"
assert_equals "User balance decreased by 200" "800.00" "$final_balance"
assert_equals "Inventory decreased by 2 units" "8" "$final_inventory"

# ========================================
# TEST 2: Insufficient Stock
# ========================================
print_test_header "Scenario 2: Insufficient Stock - Immediate Rejection"

echo "Setup: Product 7 has 5 units"
echo "Action: User 2 tries to buy 10 units (more than available)"
echo ""

initial_balance=$(get_user_balance $USER_RODRIGO)
initial_inventory=$(get_product_inventory $PRODUCT_7)

http_status=$(execute_sale $USER_RODRIGO $PRODUCT_7 10 300.00)
assert_equals "HTTP Status should be 201 Created" "201" "$http_status"

sale_id=$(get_last_sale_id)
wait_for_saga_completion "$sale_id" "CANCELED" 15

sale_status=$(get_sale_status "$sale_id")
final_balance=$(get_user_balance $USER_RODRIGO)
final_inventory=$(get_product_inventory $PRODUCT_7)

assert_equals "Sale status should be CANCELED" "CANCELED" "$sale_status"
assert_equals "User balance unchanged" "$initial_balance" "$final_balance"
assert_equals "Inventory unchanged" "$initial_inventory" "$final_inventory"

# ========================================
# TEST 3: Insufficient Balance with Compensation
# ========================================
print_test_header "Scenario 3: Insufficient Balance - Saga Compensation"

echo "Setup: User 2 has R\$ 500.00, Product 6 has 8 units (after test 1)"
echo "Action: User 2 tries to buy 3 units for R\$ 600.00 (insufficient balance)"
echo "Expected: Inventory debited then compensated (credited back)"
echo ""

initial_balance=$(get_user_balance $USER_RODRIGO)
initial_inventory=$(get_product_inventory $PRODUCT_6)

http_status=$(execute_sale $USER_RODRIGO $PRODUCT_6 3 600.00)
assert_equals "HTTP Status should be 201 Created" "201" "$http_status"

sale_id=$(get_last_sale_id)
wait_for_saga_completion "$sale_id" "CANCELED" 20

sale_status=$(get_sale_status "$sale_id")
final_balance=$(get_user_balance $USER_RODRIGO)
final_inventory=$(get_product_inventory $PRODUCT_6)

assert_equals "Sale status should be CANCELED" "CANCELED" "$sale_status"
assert_equals "User balance unchanged (payment failed)" "$initial_balance" "$final_balance"
assert_equals "Inventory compensated (returned to original)" "$initial_inventory" "$final_inventory"

# ========================================
# TEST 4: Another Successful Purchase
# ========================================
print_test_header "Scenario 4: Another Successful Purchase"

echo "Setup: User 1 has R\$ 800.00 (after test 1), Product 8 has 50 units"
echo "Action: User 1 buys 5 units of Product 8 for R\$ 400.00"
echo ""

initial_balance=$(get_user_balance $USER_CRISTIANO)
initial_inventory=$(get_product_inventory $PRODUCT_8)

http_status=$(execute_sale $USER_CRISTIANO $PRODUCT_8 5 400.00)
assert_equals "HTTP Status should be 201 Created" "201" "$http_status"

sale_id=$(get_last_sale_id)
wait_for_saga_completion "$sale_id" "FINALIZED" 15

sale_status=$(get_sale_status "$sale_id")
final_balance=$(get_user_balance $USER_CRISTIANO)
final_inventory=$(get_product_inventory $PRODUCT_8)

assert_equals "Sale status should be FINALIZED" "FINALIZED" "$sale_status"
assert_equals "User balance decreased by 400" "400.00" "$final_balance"
assert_equals "Inventory decreased by 5 units" "45" "$final_inventory"

# ========================================
# TEST 5: Concurrent Transactions
# ========================================
print_test_header "Scenario 5: Concurrent Transactions"

echo "Setup: Testing concurrent saga execution"
echo "Action: Fire 3 purchases simultaneously (7 total sales after this test)"
echo ""

# Execute three sales concurrently
execute_sale $USER_CRISTIANO $PRODUCT_9 2 100.00 >/dev/null &
pid1=$!
execute_sale $USER_RODRIGO $PRODUCT_10 3 150.00 >/dev/null &
pid2=$!
execute_sale $USER_CRISTIANO $PRODUCT_10 1 50.00 >/dev/null &
pid3=$!

# Wait for all requests to complete
wait $pid1 $pid2 $pid3

# Wait for all sagas to complete (using dedicated function)
wait_for_all_sagas_completion 20

# Verify all sales were created and processed
total_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DATABASE" "SELECT COUNT(*) FROM sales;")
finalized_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DATABASE" "SELECT COUNT(*) FROM sales WHERE sale_status_id = $SALE_STATUS_FINALIZED;")
canceled_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DATABASE" "SELECT COUNT(*) FROM sales WHERE sale_status_id = $SALE_STATUS_CANCELED;")

assert_equals "Total sales created (4 from previous tests + 3 concurrent)" "7" "$total_sales"
assert_equals "Sales finalized (tests 1,4 + 3 concurrent)" "5" "$finalized_sales"
assert_equals "Sales canceled (tests 2,3)" "2" "$canceled_sales"

# ========================================
# TEST 6: Idempotency Check (Edge Case)
# ========================================
print_test_header "Scenario 6: Verify Final System State"

echo "Verifying system consistency after all tests..."
echo ""

# Check that all sales have a final state (no PENDING)
pending_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DATABASE" "SELECT COUNT(*) FROM sales WHERE sale_status_id = $SALE_STATUS_PENDING;")
assert_equals "No sales stuck in PENDING state" "0" "$pending_sales"

# Check data integrity (should be exactly 7 sales, not more, not less)
total_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DATABASE" "SELECT COUNT(*) FROM sales;")
assert_equals "Total sales created throughout all tests" "7" "$total_sales"

# ========================================
# TEST SUMMARY
# ========================================
echo ""
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${BLUE}  TEST SUMMARY${NC}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Total Tests:  ${BOLD}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}${BOLD}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}${BOLD}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ ALL TESTS PASSED!${NC}"
    echo ""

    # Cleanup
    echo -e "${YELLOW}Cleaning up test environment...${NC}"
    docker compose -f $COMPOSE_FILE down -v --remove-orphans

    echo -e "${GREEN}Test environment cleaned up successfully!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}${BOLD}✗ SOME TESTS FAILED!${NC}"
    echo ""
    echo -e "${YELLOW}Logs available for debugging:${NC}"
    echo -e "  docker compose -f $COMPOSE_FILE logs sale-service-test"
    echo -e "  docker compose -f $COMPOSE_FILE logs inventory-service-test"
    echo -e "  docker compose -f $COMPOSE_FILE logs payment-service-test"
    echo ""
    echo -e "${YELLOW}Test environment is still running for debugging.${NC}"
    echo -e "To clean up manually: ${CYAN}docker compose -f $COMPOSE_FILE down -v${NC}"
    echo ""
    exit 1
fi
