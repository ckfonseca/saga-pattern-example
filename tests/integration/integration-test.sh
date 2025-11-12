#!/bin/bash

# ========================================
# Saga Pattern - Integration Test Suite
# ========================================
# This script runs automated integration tests to verify the Saga Pattern implementation
# Tests run against isolated test containers (compose.test.yml)

set -e  # Exit on first error

# Load environment variables from .env file (safe parsing)
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

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

# Sale status constants
SALE_STATUS_PENDING=1
SALE_STATUS_FINALIZED=2
SALE_STATUS_CANCELED=3

# Database configuration (from .env with defaults)
SALE_DB_NAME="${SALE_DB_NAME:-sales_db}"
SALE_DB_ROOT_PWD="${SALE_DB_ROOT_PWD:-root}"
INVENTORY_DB_NAME="${INVENTORY_DB_NAME:-inventory_db}"
INVENTORY_DB_ROOT_PWD="${INVENTORY_DB_ROOT_PWD:-root}"
PAYMENT_DB_NAME="${PAYMENT_DB_NAME:-payment_db}"
PAYMENT_DB_ROOT_PWD="${PAYMENT_DB_ROOT_PWD:-root}"
KAFKA_TOPIC="${KAFKA_TOPIC:-tp-saga-market}"

# Test container names
SALE_DB_CONTAINER="sale-db-test"
INVENTORY_DB_CONTAINER="inventory-db-test"
PAYMENT_DB_CONTAINER="payment-db-test"

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

print_test_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  TEST: $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

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

assert_equals() {
    local description=$1
    local expected=$2
    local actual=$3

    print_test_result "$description" "$expected" "$actual"
}

query_db() {
    local container=$1
    local database=$2
    local query=$3
    local root_pwd

    case "$container" in
        *sale*) root_pwd="$SALE_DB_ROOT_PWD" ;;
        *inventory*) root_pwd="$INVENTORY_DB_ROOT_PWD" ;;
        *payment*) root_pwd="$PAYMENT_DB_ROOT_PWD" ;;
        *) root_pwd="root" ;;
    esac

    docker exec "$container" mysql -u root -p"$root_pwd" "$database" -se "$query" 2>/dev/null
}

get_sale_status() {
    local sale_id=$1
    query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" \
        "SELECT CASE sale_status_id
            WHEN $SALE_STATUS_PENDING THEN 'PENDING'
            WHEN $SALE_STATUS_FINALIZED THEN 'FINALIZED'
            WHEN $SALE_STATUS_CANCELED THEN 'CANCELED'
        END FROM sales WHERE id = $sale_id;"
}

get_user_balance() {
    local user_id=$1
    query_db "$PAYMENT_DB_CONTAINER" "$PAYMENT_DB_NAME" \
        "SELECT balance FROM users WHERE id = $user_id;"
}

get_product_inventory() {
    local product_id=$1
    query_db "$INVENTORY_DB_CONTAINER" "$INVENTORY_DB_NAME" \
        "SELECT quantity FROM inventories WHERE product_id = $product_id;"
}

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

get_last_sale_id() {
    query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" "SELECT MAX(id) FROM sales;"
}

wait_for_all_sagas_completion() {
    local max_wait=${1:-20}
    echo -e "${YELLOW}⏳ Waiting for all concurrent sagas to complete...${NC}"

    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        local pending_count=$(query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" \
            "SELECT COUNT(*) FROM sales WHERE sale_status_id = $SALE_STATUS_PENDING;")

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
# POLLING FUNCTIONS
# ========================================

wait_for_saga_completion() {
    local sale_id=$1
    local expected_status=$2
    local max_wait=${3:-$MAX_WAIT_SECONDS}

    echo -e "${YELLOW}⏳ Waiting for saga to reach status '$expected_status' (polling every ${POLL_INTERVAL_SECONDS}s, max ${max_wait}s)...${NC}"

    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        local current_status=$(get_sale_status "$sale_id")

        if [ "$current_status" == "$expected_status" ]; then
            echo -e "${GREEN}✓ Saga completed in ${elapsed}s (status: $current_status)${NC}"
            return 0
        fi

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

wait_for_kafka() {
    local container=$1
    local max_wait=${2:-30}

    echo -e "${YELLOW}⏳ Waiting for Kafka to be ready (polling every ${POLL_INTERVAL_SECONDS}s, max ${max_wait}s)...${NC}"

    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        if docker exec "$container" /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:29092 --list > /dev/null 2>&1; then
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
docker compose -f $COMPOSE_FILE down -v 2>/dev/null || true

echo -e "${BLUE}Starting test containers and waiting for all services to be healthy...${NC}"
docker compose -f $COMPOSE_FILE up -d --build --wait

# Wait for Kafka (topics are auto-created by services)
wait_for_kafka "kafka-test" 30

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
total_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" "SELECT COUNT(*) FROM sales;")
finalized_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" "SELECT COUNT(*) FROM sales WHERE sale_status_id = $SALE_STATUS_FINALIZED;")
canceled_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" "SELECT COUNT(*) FROM sales WHERE sale_status_id = $SALE_STATUS_CANCELED;")

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
pending_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" "SELECT COUNT(*) FROM sales WHERE sale_status_id = $SALE_STATUS_PENDING;")
assert_equals "No sales stuck in PENDING state" "0" "$pending_sales"

# Check data integrity (should be exactly 7 sales, not more, not less)
total_sales=$(query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" "SELECT COUNT(*) FROM sales;")
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
    docker compose -f $COMPOSE_FILE down -v

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
