#!/bin/bash

# ========================================
# Saga Pattern - Interactive Demo
# ========================================
# This script provides an interactive demonstration of the Saga Pattern
# showing success and failure scenarios with real-time database state

set -e

# Load environment variables from .env file (safe parsing)
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# ========================================
# CONFIGURATION & CONSTANTS
# ========================================

# Colors for output
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m'

# Service configuration
SALE_SERVICE_URL="${SALE_SERVICE_URL:-http://localhost:8081/api/v1/sales}"
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

# Container names (can be overridden via environment variables)
SALE_DB_CONTAINER="${SALE_DB_CONTAINER:-sale-db}"
INVENTORY_DB_CONTAINER="${INVENTORY_DB_CONTAINER:-inventory-db}"
PAYMENT_DB_CONTAINER="${PAYMENT_DB_CONTAINER:-payment-db}"

# Test data constants
USER_CRISTIANO=1
USER_RODRIGO=2
PRODUCT_6=6
PRODUCT_7=7
PRODUCT_8=8
PRODUCT_9=9
PRODUCT_10=10

# ========================================
# UTILITY FUNCTIONS
# ========================================

query_db() {
    local container=$1
    local database=$2
    local query=$3
    local root_pwd

    # Determine password based on container name
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

get_last_sale_id() {
    query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" "SELECT MAX(id) FROM sales;"
}

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
wait_for_all_sagas_completion() {
    local max_wait=${1:-20}

    echo -e "${YELLOW}⏳ Waiting for all concurrent sagas to complete (polling every ${POLL_INTERVAL_SECONDS}s, max ${max_wait}s)...${NC}"

    local elapsed=0
    while [ $elapsed -lt $max_wait ]; do
        local pending_count=$(query_db "$SALE_DB_CONTAINER" "$SALE_DB_NAME" "SELECT COUNT(*) FROM sales WHERE sale_status_id = $SALE_STATUS_PENDING;")
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
# DISPLAY FUNCTIONS
# ========================================
print_header() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${BOLD}$1${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}
print_subheader() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_command() {
    echo -e "${MAGENTA}$ $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_next_step() {
    echo -e "${CYAN}⏭  $1${NC}"
}
print_scenario_complete() {
    local scenario=$1
    shift
    echo ""
    echo -e "${BOLD}${GREEN}✓ Scenario $scenario Complete!${NC}"
    for item in "$@"; do
        echo "  • $item"
    done
}
print_next_scenario() {
    echo ""
    echo -e "${YELLOW}Next: $1${NC}"
}
print_concept_box() {
    local title=$1
    shift
    echo ""
    echo -e "${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${CYAN}│ 💡 $title${NC}"
    echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
    for line in "$@"; do
        echo -e "   $line"
    done
    echo ""
}
print_separator() {
    echo ""
    echo -e "${BLUE}────────────────────────────────────────────────────────────────${NC}"
    echo ""
}
wait_for_user() {
    echo ""
    echo -e "${BOLD}${YELLOW}Press ENTER to continue...${NC}"
    read -r
}

# ========================================
# DATABASE QUERY FUNCTIONS
# ========================================
show_sales() {
    local limit=${1:-5}
    echo -e "${CYAN}Current Sales (last $limit):${NC}"
    print_command "docker exec $SALE_DB_CONTAINER mysql -u root -p\$SALE_DB_ROOT_PWD $SALE_DB_NAME -e \"SELECT ...\""
    docker exec "$SALE_DB_CONTAINER" mysql -u root -p"$SALE_DB_ROOT_PWD" "$SALE_DB_NAME" --table -e "
        SELECT
            id AS 'ID',
            user_id AS 'User',
            product_id AS 'Product',
            quantity AS 'Qty',
            CONCAT('R\$ ', FORMAT(value, 2)) AS 'Value',
            CASE sale_status_id
                WHEN $SALE_STATUS_PENDING THEN '⏳ PENDING'
                WHEN $SALE_STATUS_FINALIZED THEN '✓ FINALIZED'
                WHEN $SALE_STATUS_CANCELED THEN '✗ CANCELED'
            END AS 'Status'
        FROM sales
        ORDER BY id DESC
        LIMIT $limit;
    " 2>/dev/null
    echo ""
}
show_user_balance() {
    local user_id=$1
    echo -e "${CYAN}User Balance (User ID: $user_id):${NC}"
    print_command "docker exec $PAYMENT_DB_CONTAINER mysql -u root -p\$PAYMENT_DB_ROOT_PWD $PAYMENT_DB_NAME -e \"SELECT ...\""
    docker exec "$PAYMENT_DB_CONTAINER" mysql -u root -p"$PAYMENT_DB_ROOT_PWD" "$PAYMENT_DB_NAME" --table -e "
        SELECT
            id AS 'ID',
            name AS 'Name',
            CONCAT('R\$ ', FORMAT(balance, 2)) AS 'Balance'
        FROM users
        WHERE id = $user_id;
    " 2>/dev/null
    echo ""
}
show_product_inventory() {
    local product_id=$1
    echo -e "${CYAN}Product Inventory (Product ID: $product_id):${NC}"
    print_command "docker exec $INVENTORY_DB_CONTAINER mysql -u root -p\$INVENTORY_DB_ROOT_PWD $INVENTORY_DB_NAME -e \"SELECT ...\""
    docker exec "$INVENTORY_DB_CONTAINER" mysql -u root -p"$INVENTORY_DB_ROOT_PWD" "$INVENTORY_DB_NAME" --table -e "
        SELECT
            product_id AS 'Product ID',
            CONCAT(quantity, ' units') AS 'Stock Available'
        FROM inventories
        WHERE product_id = $product_id;
    " 2>/dev/null
    echo ""
}

# ========================================
# SALE EXECUTION FUNCTION
# ========================================
execute_sale() {
    local user_id=$1
    local product_id=$2
    local quantity=$3
    local value=$4
    local description=$5
    local silent=${6:-false}
    local unit_price=$(awk "BEGIN {printf \"%.2f\", $value / $quantity}")

    if [ "$silent" != "true" ]; then
        echo -e "${BOLD}${YELLOW}Executing Sale: $description${NC}"
        echo -e "  ${CYAN}Total: R\$ ${value} (${quantity} × R\$ ${unit_price})${NC}"
        echo ""

        local curl_cmd="curl -X POST $SALE_SERVICE_URL \
  -H \"Content-Type: application/json\" \
  -d '{
    \"userId\": $user_id,
    \"productId\": $product_id,
    \"quantity\": $quantity,
    \"value\": $value
  }'"

        print_command "$curl_cmd"
        echo ""
    fi

    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST $SALE_SERVICE_URL \
      -H "Content-Type: application/json" \
      -d "{
        \"userId\": $user_id,
        \"productId\": $product_id,
        \"quantity\": $quantity,
        \"value\": $value
      }")

    if [ "$silent" != "true" ]; then
        if [ "$response" -eq 201 ]; then
            print_success "Request accepted (HTTP 201)"
            echo "  → User ID: $user_id"
            echo "  → Product ID: $product_id"
            echo "  → Quantity: $quantity"
            echo "  → Value: R\$ $value"
            return 0
        else
            print_error "Request failed (HTTP $response)"
            return 1
        fi
    fi

    return 0
}

# ========================================
# STARTUP & HEALTH CHECKS
# ========================================
check_container_health() {
    echo -e "${YELLOW}Checking container health...${NC}"

    local containers=("$SALE_DB_CONTAINER" "$INVENTORY_DB_CONTAINER" "$PAYMENT_DB_CONTAINER")
    for container in "${containers[@]}"; do
        if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo -e "${RED}✗ Container $container is not running${NC}"
            echo -e "${YELLOW}Please start the environment with: docker-compose up -d${NC}"
            exit 1
        fi
    done

    echo -e "${GREEN}✓ All database containers are running${NC}"
}

# ========================================
# MAIN DEMO EXECUTION
# ========================================

clear
echo ""
echo -e "${BOLD}${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║          SAGA PATTERN - INTERACTIVE DEMONSTRATION             ║
║                                                               ║
║     Choreography-based Saga with Kafka Event Streaming        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
print_info "This demo will guide you through different saga scenarios"
print_info "You'll see real-time database changes and event flows"
echo ""

check_container_health || exit 1

wait_for_user

# ========================================
# Initial State
# ========================================
print_header "INITIAL STATE - Database Setup"

print_subheader "Users and their balances:"
docker exec "$PAYMENT_DB_CONTAINER" mysql -u root -p"$PAYMENT_DB_ROOT_PWD" "$PAYMENT_DB_NAME" --table -e "
    SELECT
        id AS 'ID',
        name AS 'Name',
        CONCAT('R\$ ', FORMAT(balance, 2)) AS 'Balance'
    FROM users
    ORDER BY id;
" 2>/dev/null

print_subheader "Products and inventory:"
docker exec "$INVENTORY_DB_CONTAINER" mysql -u root -p"$INVENTORY_DB_ROOT_PWD" "$INVENTORY_DB_NAME" --table -e "
    SELECT
        product_id AS 'Product ID',
        quantity AS 'Stock'
    FROM inventories
    ORDER BY product_id;
" 2>/dev/null

wait_for_user

# ========================================
# System Overview
# ========================================
print_header "SYSTEM OVERVIEW - E-Commerce Microservices"

echo -e "${BOLD}${BLUE}🏪 What are we building?${NC}"
echo ""
echo "This is a simplified e-commerce system with 3 microservices:"
echo ""
echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│ 📦 Sale Service${NC}"
echo -e "${CYAN}│${NC}    • Manages purchase orders"
echo -e "${CYAN}│${NC}    • Tracks sale status: PENDING → FINALIZED or CANCELED"
echo -e "${CYAN}│${NC}    • Database: sales_db"
echo -e "${CYAN}│${NC}"
echo -e "${CYAN}│ 📊 Inventory Service${NC}"
echo -e "${CYAN}│${NC}    • Manages product stock"
echo -e "${CYAN}│${NC}    • Debits/credits inventory"
echo -e "${CYAN}│${NC}    • Database: inventory_db"
echo -e "${CYAN}│${NC}"
echo -e "${CYAN}│ 💳 Payment Service${NC}"
echo -e "${CYAN}│${NC}    • Manages user balances"
echo -e "${CYAN}│${NC}    • Debits/credits money"
echo -e "${CYAN}│${NC}    • Database: payment_db"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${YELLOW}${BOLD}💡 The Challenge:${NC}"
echo ""
echo "When a user buys a product, we need to:"
echo -e "  ${CYAN}1.${NC} Create the sale"
echo -e "  ${CYAN}2.${NC} Debit the inventory"
echo -e "  ${CYAN}3.${NC} Charge the user"
echo ""
echo -e "${RED}${BOLD}But what if one step fails?${NC}"
echo "  • User has insufficient balance? → Need to rollback inventory"
echo "  • Not enough stock? → Don't charge the user"
echo ""
echo -e "${GREEN}${BOLD}That's where the Saga Pattern comes in!${NC}"

wait_for_user

# ========================================
# Scenario 1: Happy Path - Successful Purchase
# ========================================
print_header "SCENARIO 1: HAPPY PATH - Successful Purchase"

echo -e "${BOLD}${CYAN}🎯 SAGA PATTERN CHARACTERISTIC #1: Distributed Transactions${NC}"
echo ""

print_concept_box "What is ACID?" \
    "Traditional databases guarantee ACID properties in a single transaction:" \
    "" \
    "${BOLD}A${NC}tomicity: All-or-nothing" \
    "${BOLD}C${NC}onsistency: Data stays valid" \
    "${BOLD}I${NC}solation: No interference" \
    "${BOLD}D${NC}urability: Permanent once committed"

print_separator

echo -e "${RED}${BOLD}❌ The Problem${NC}"
echo "   ACID doesn't work across microservices!"
echo "   Can't span: Sale DB + Inventory DB + Payment DB"
echo ""

echo -e "${GREEN}${BOLD}✅ The Saga Solution${NC}"
echo "   Break into smaller local transactions:"
echo ""
echo -e "   ${CYAN}1️⃣${NC}  Sale Service creates PENDING sale"
echo -e "   ${CYAN}2️⃣${NC}  Inventory Service debits stock"
echo -e "   ${CYAN}3️⃣${NC}  Payment Service debits balance"
echo -e "   ${CYAN}4️⃣${NC}  Sale Service updates to FINALIZED"

print_separator

echo -e "${BOLD}📋 Test Scenario:${NC}"
echo -e "   User: Cristiano (ID: $USER_CRISTIANO) - Balance: ${GREEN}R\$ 1,000.00${NC}"
echo -e "   Product: ID $PRODUCT_6 - Stock: ${GREEN}10 units${NC}"
echo -e "   Purchase: ${YELLOW}2 units × R\$ 100.00 = R\$ 200.00${NC}"
echo ""
echo -e "   ${GREEN}${BOLD}✓ Expected:${NC} Sale FINALIZED"

wait_for_user

print_subheader "BEFORE - User Balance and Product Inventory"
show_user_balance $USER_CRISTIANO
show_product_inventory $PRODUCT_6
print_next_step "Press ENTER to execute the purchase and watch the Saga flow..."

wait_for_user

print_subheader "Executing Purchase..."
execute_sale $USER_CRISTIANO $PRODUCT_6 2 200.00 "Cristiano buys 2 units of product 6"

sale_id=$(get_last_sale_id)

print_separator
echo -e "${BOLD}${CYAN}📨 SAGA PATTERN CHARACTERISTIC #2: Event-Driven Choreography${NC}"
echo ""

print_concept_box "Choreography vs Orchestration" \
    "${BOLD}Orchestration${NC} (like a conductor):" \
    "  → Central service controls the flow" \
    "  → Tells each service what to do" \
    "" \
    "${BOLD}Choreography${NC} (like a dance):" \
    "  → No central controller" \
    "  → Services listen and react to events" \
    "  → Each knows its role autonomously"

echo -e "${YELLOW}${BOLD}⚡ Event Flow (who listens to what):${NC}"
echo ""
echo -e "   ${CYAN}1️⃣${NC}  Sale Service      ${BLUE}→${NC} publishes ${YELLOW}CREATED_SALE${NC}"
echo -e "       ${MAGENTA}↓${NC} Inventory listens to this event"
echo ""
echo -e "   ${CYAN}2️⃣${NC}  Inventory Service ${BLUE}→${NC} debits stock ${BLUE}→${NC} publishes ${YELLOW}UPDATED_INVENTORY${NC}"
echo -e "       ${MAGENTA}↓${NC} Payment listens to this event"
echo ""
echo -e "   ${CYAN}3️⃣${NC}  Payment Service   ${BLUE}→${NC} debits balance ${BLUE}→${NC} publishes ${YELLOW}VALIDATED_PAYMENT${NC}"
echo -e "       ${MAGENTA}↓${NC} Sale listens to this event"
echo ""
echo -e "   ${CYAN}4️⃣${NC}  Sale Service      ${BLUE}→${NC} updates to ${GREEN}FINALIZED${NC}"
echo ""
echo -e "   ${MAGENTA}💡 All via Kafka events - no direct service calls!${NC}"

print_separator

wait_for_saga_completion "$sale_id" "FINALIZED" 30

echo ""
echo -e "${BOLD}${GREEN}✓ Saga workflow completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Let's verify the final state in all databases:${NC}"
echo "  • Sale status in sales_db"
echo "  • Inventory quantity in inventory_db"
echo "  • User balance in payment_db"

wait_for_user

print_subheader "AFTER - User Balance and Product Inventory"
show_user_balance $USER_CRISTIANO
show_product_inventory $PRODUCT_6
show_sales 3

print_info "Want to check Kafka events? Run:"
print_command "docker exec kafka kafka-console-consumer --bootstrap-server localhost:29092 --topic ${KAFKA_TOPIC:-tp-saga-market} --from-beginning"
echo ""
print_scenario_complete "1" \
    "Sale status: FINALIZED" \
    "User balance: debited R\$ 200.00" \
    "Product inventory: debited 2 units"
print_next_scenario "Scenario 2 - Testing insufficient stock (fail-fast)"

wait_for_user

# ========================================
# Scenario 2: Insufficient Stock - Immediate Failure
# ========================================
print_header "SCENARIO 2: INSUFFICIENT STOCK - Immediate Failure"

echo -e "${BOLD}${CYAN}🎯 SAGA PATTERN CHARACTERISTIC #3: Semantic Lock & Early Validation${NC}"
echo ""
echo -e "💡 ${BOLD}What are Semantic Locks?${NC}"
echo ""
echo -e "   ${BOLD}Traditional Locks (2PC - Two-Phase Commit):${NC}"
echo "   • Lock ALL resources BEFORE doing any work"
echo "   • Example: Lock inventory row + payment row + sale row"
echo "   • Problem: If one service is slow, everything waits (bad for performance!)"
echo ""
echo -e "   ${BOLD}Semantic Locks (Saga Pattern):${NC}"
echo "   • Don't lock database rows"
echo "   • Instead, use business logic to validate BEFORE proceeding"
echo "   • Example: Check if stock > 0 BEFORE debiting"
echo "   • If validation fails → abort immediately (fail-fast!)"
echo ""
echo -e "✅ ${BOLD}In this scenario:${NC}"
echo ""
echo -e "  ${CYAN}1️⃣${NC}  User tries to buy 10 units, but only 5 are available"
echo -e "  ${CYAN}2️⃣${NC}  Inventory Service checks: 'quantity (10) > stock (5)?' ${BLUE}→${NC} ${RED}NO!${NC}"
echo -e "  ${CYAN}3️⃣${NC}  Inventory ${RED}rejects immediately${NC} ${BLUE}→${NC} publishes ${YELLOW}FAILED_INVENTORY${NC}"
echo -e "       ${MAGENTA}↓${NC} Sale listens to this event"
echo -e "  ${CYAN}4️⃣${NC}  Sale Service updates to ${RED}CANCELED${NC}"
echo -e "  ${CYAN}5️⃣${NC}  Payment Service ${GREEN}never even runs${NC} (fail-fast!)"
echo ""

print_info "User: Rodrigo (ID: $USER_RODRIGO) - Balance: R\$ 500.00"
print_info "Product: ID $PRODUCT_7 - Available: 5 units"
print_info "Purchase: Trying to buy 10 units for R\$ 300.00"
echo ""
print_error "Expected: Sale should be CANCELED (not enough inventory)"

wait_for_user

print_subheader "BEFORE - User Balance and Product Inventory"
show_user_balance $USER_RODRIGO
show_product_inventory $PRODUCT_7
print_next_step "Press ENTER to attempt purchase (will fail immediately - insufficient stock)..."

wait_for_user

print_subheader "Executing Purchase..."
execute_sale $USER_RODRIGO $PRODUCT_7 10 300.00 "Rodrigo tries to buy 10 units (only 5 available)"

sale_id=$(get_last_sale_id)
echo ""

wait_for_saga_completion "$sale_id" "CANCELED" 30

print_subheader "AFTER - Verification"
print_success "Notice: User balance unchanged (payment never attempted)"
show_user_balance $USER_RODRIGO
print_success "Notice: Inventory unchanged (debit never happened)"
show_product_inventory $PRODUCT_7
show_sales 3
print_scenario_complete "2" \
    "Sale status: CANCELED (fail-fast - insufficient stock)" \
    "User balance: unchanged (payment never attempted)" \
    "Product inventory: unchanged (never debited)"
print_next_scenario "Scenario 3 - Testing saga compensation (rollback)"

wait_for_user

# ========================================
# Scenario 3: Insufficient Balance - Compensation Flow
# ========================================
print_header "SCENARIO 3: INSUFFICIENT BALANCE - Saga Compensation"

echo -e "${BOLD}${CYAN}🎯 SAGA PATTERN CHARACTERISTIC #4: Compensating Transactions${NC}"
echo ""
echo -e "${YELLOW}Key Difference:${NC}"
echo "  ACID: Database auto-rollback (undo)"
echo "  Saga: Forward compensation (new transaction to reverse)"
echo ""

echo -e "${YELLOW}${BOLD}🔄 Compensation Flow:${NC}"
echo -e "   ${CYAN}1${NC} Sale ${BLUE}→${NC} ${YELLOW}CREATED_SALE${NC} ${BLUE}→${NC} Inventory"
echo -e "   ${CYAN}2${NC} Inventory ${GREEN}debits${NC} ${BLUE}→${NC} ${YELLOW}UPDATED_INVENTORY${NC} ${BLUE}→${NC} Payment"
echo -e "   ${CYAN}3${NC} Payment ${RED}rejects${NC} ${BLUE}→${NC} ${YELLOW}FAILED_PAYMENT${NC} ${BLUE}→${NC} Inventory"
echo -e "   ${CYAN}4${NC} Inventory ${MAGENTA}credits back${NC} ${BLUE}→${NC} ${YELLOW}ROLLBACK_INVENTORY${NC} ${BLUE}→${NC} Sale"
echo -e "   ${CYAN}5${NC} Sale ${BLUE}→${NC} ${RED}CANCELED${NC}"
echo ""

echo -e "${BOLD}📋 Test:${NC} Rodrigo (R\$ 500) tries to buy R\$ 600 ${BLUE}→${NC} ${RED}Compensation!${NC}"

wait_for_user

print_subheader "BEFORE - User Balance and Product Inventory"
show_user_balance $USER_RODRIGO
show_product_inventory $PRODUCT_6
print_next_step "Press ENTER to execute purchase and observe compensation (rollback)..."

wait_for_user

print_subheader "Executing Purchase..."
execute_sale $USER_RODRIGO $PRODUCT_6 3 600.00 "Rodrigo tries to buy 3 units for R\$ 600 (only has R\$ 500)"

sale_id=$(get_last_sale_id)

echo ""
echo -e "${BOLD}${YELLOW}🔍 WATCH THE COMPENSATION IN ACTION!${NC}"
echo ""
echo "Right now, the following is happening asynchronously:"
echo ""
echo "  [T1] Sale created with status=PENDING"
echo "  [T2] Inventory debits 3 units (8 → 5)"
echo "  [T3] Payment service checks balance: R\$ 500 < R\$ 600 → FAIL"
echo "  [T4] PaymentRejectedEvent triggers compensation"
echo "  [T5] Inventory credits back 3 units (5 → 8) ← COMPENSATION!"
echo "  [T6] Sale updated to status=CANCELED"
echo ""

wait_for_saga_completion "$sale_id" "CANCELED" 30

print_subheader "AFTER - Verification"
print_success "Notice: Inventory was compensated (returned to original value)"
show_product_inventory $PRODUCT_6
print_success "Notice: User balance unchanged (payment failed)"
show_user_balance $USER_RODRIGO
show_sales 3

print_info "To see the compensation events in Kafka:"
print_command "docker exec kafka kafka-console-consumer --bootstrap-server localhost:29092 --topic ${KAFKA_TOPIC:-tp-saga-market} --from-beginning | grep -A5 -B5 ROLLBACK"
echo ""
print_scenario_complete "3" \
    "Sale status: CANCELED (payment failed)" \
    "User balance: unchanged (insufficient funds)" \
    "Product inventory: COMPENSATED (credited back after debit)" \
    "Events: CREATED_SALE → UPDATED_INVENTORY → FAILED_PAYMENT → ROLLBACK_INVENTORY"
print_next_scenario "Scenario 4 - Another successful purchase"

wait_for_user

# ========================================
# Scenario 4: Another Successful Purchase
# ========================================
print_header "SCENARIO 4: ANOTHER HAPPY PATH"

print_info "User: Cristiano (ID: $USER_CRISTIANO) - Balance: R\$ 800.00 (after first purchase)"
print_info "Product: ID $PRODUCT_8 - Available: 50 units"
print_info "Purchase: 5 units for R\$ 400.00"
echo ""
print_success "Expected: Sale should be FINALIZED"

wait_for_user

print_subheader "BEFORE State"
show_user_balance $USER_CRISTIANO
show_product_inventory $PRODUCT_8
print_next_step "Press ENTER to execute another successful purchase..."

wait_for_user

print_subheader "Executing Purchase..."
execute_sale $USER_CRISTIANO $PRODUCT_8 5 400.00 "Cristiano buys 5 units of product 8"

sale_id=$(get_last_sale_id)
echo ""

wait_for_saga_completion "$sale_id" "FINALIZED" 30

print_subheader "AFTER State"
show_user_balance $USER_CRISTIANO
show_product_inventory $PRODUCT_8
show_sales 5
print_scenario_complete "4" \
    "Sale status: FINALIZED" \
    "User balance: debited R\$ 400.00" \
    "Product inventory: debited 5 units"
print_next_scenario "Scenario 5 - Testing concurrent transactions (rapid fire)"

wait_for_user

# ========================================
# Scenario 5: Rapid Fire - Concurrent Transactions
# ========================================
print_header "SCENARIO 5: CONCURRENT TRANSACTIONS"

echo -e "${BOLD}${CYAN}🎯 SAGA PATTERN CHARACTERISTIC #5: Eventual Consistency${NC}"
echo ""

print_concept_box "Eventual Consistency vs Immediate Consistency" \
    "${BOLD}Immediate (ACID):${NC}" \
    "  → Transaction finishes = data instantly consistent" \
    "  → Always see final, correct state" \
    "" \
    "${BOLD}Eventual (BASE):${NC}" \
    "  → ${BOLD}B${NC}asically ${BOLD}A${NC}vailable: keeps working during updates" \
    "  → ${BOLD}S${NC}oft state: temporary intermediate states" \
    "  → ${BOLD}E${NC}ventually consistent: clean at the end"

print_separator

echo -e "${YELLOW}${BOLD}⚡ In Practice:${NC}"
echo ""
echo -e "   • Multiple sagas run ${CYAN}concurrently${NC}"
echo -e "   • Might see ${YELLOW}PENDING${NC} for a few seconds"
echo -e "   • Eventually becomes ${GREEN}FINALIZED${NC} or ${RED}CANCELED${NC}"
echo -e "   • ${MAGENTA}'Messy during processing, clean at the end'${NC}"

print_separator

echo -e "${BOLD}📋 Test: 3 Rapid Concurrent Purchases${NC}"
echo "   Testing event-driven choreography under load"
echo ""
echo -e "${YELLOW}${BOLD}What to expect:${NC}"
echo -e "   • 3 HTTP requests fire ${CYAN}simultaneously${NC}"
echo -e "   • Each triggers independent saga workflows"
echo -e "   • All events flow through ${MAGENTA}Kafka${NC} in parallel"
echo -e "   • Services process events ${GREEN}asynchronously${NC}"
echo -e "   • Final consistency achieved ${BLUE}without coordination${NC}"

wait_for_user

print_subheader "Firing 3 concurrent HTTP requests..."
echo ""

echo -e "${CYAN}Request 1:${NC} Cristiano buys 2 units from Product 9 (R\$ 100.00)"
echo -e "${CYAN}Request 2:${NC} Rodrigo buys 3 units from Product 10 (R\$ 150.00)"
echo -e "${CYAN}Request 3:${NC} Cristiano buys 1 unit from Product 10 (R\$ 50.00)"
echo ""
echo -e "${YELLOW}Firing all 3 requests simultaneously...${NC}"

execute_sale $USER_CRISTIANO $PRODUCT_9 2 100.00 "Cristiano buys from product 9" true &
pid1=$!

execute_sale $USER_RODRIGO $PRODUCT_10 3 150.00 "Rodrigo buys from product 10" true &
pid2=$!

execute_sale $USER_CRISTIANO $PRODUCT_10 1 50.00 "Cristiano also buys from product 10" true &
pid3=$!

wait $pid1 $pid2 $pid3

echo -e "${GREEN}✓ All 3 requests sent successfully (HTTP 201)${NC}"
echo ""

wait_for_all_sagas_completion 20

print_subheader "Results - All Recent Sales"
show_sales 8
print_scenario_complete "5" \
    "3 concurrent transactions processed successfully" \
    "Each saga executed independently through Kafka events" \
    "No race conditions or data inconsistencies"
print_next_scenario "Demo complete! All 5 Saga Pattern characteristics demonstrated."

wait_for_user

# ========================================
# Summary and Exploration
# ========================================
print_header "DEMO COMPLETED - Exploration Commands"

echo -e "${BOLD}You can now explore the system using these commands:${NC}"
echo ""

echo -e "${CYAN}1. View Application Logs:${NC}"
print_command "docker-compose logs -f sale-service"
print_command "docker-compose logs -f inventory-service"
print_command "docker-compose logs -f payment-service"
echo ""

echo -e "${CYAN}2. Monitor Kafka Topics:${NC}"
print_command "docker exec kafka kafka-console-consumer --bootstrap-server localhost:29092 --topic ${KAFKA_TOPIC:-tp-saga-market} --from-beginning"
echo ""

echo -e "${CYAN}3. Access Kafka UI (if configured):${NC}"
print_command "open http://localhost:8181"
echo ""

echo -e "${CYAN}4. Query Databases Directly:${NC}"
print_command "docker exec -it $SALE_DB_CONTAINER mysql -u root -p\$SALE_DB_ROOT_PWD $SALE_DB_NAME"
print_command "docker exec -it $INVENTORY_DB_CONTAINER mysql -u root -p\$INVENTORY_DB_ROOT_PWD $INVENTORY_DB_NAME"
print_command "docker exec -it $PAYMENT_DB_CONTAINER mysql -u root -p\$PAYMENT_DB_ROOT_PWD $PAYMENT_DB_NAME"
echo ""

echo -e "${CYAN}5. Check All Sales Status:${NC}"
show_sales 20

echo ""
print_header "FINAL USER BALANCES"
echo ""
echo -e "${BOLD}After all transactions, here are the final user balances:${NC}"
echo ""

docker exec "$PAYMENT_DB_CONTAINER" mysql -u root -p"$PAYMENT_DB_ROOT_PWD" "$PAYMENT_DB_NAME" -e "
SELECT
    id,
    name,
    CONCAT('R\$ ', FORMAT(balance, 2)) as final_balance
FROM users
ORDER BY id;" 2>/dev/null | tail -n +2 | while IFS=$'\t' read -r id name balance; do
    echo -e "  ${CYAN}User ${id}${NC} - ${BOLD}${name}${NC}: ${GREEN}${balance}${NC}"
done

echo ""
print_success "Thank you for watching the Saga Pattern demonstration!"
echo ""

print_header "SAGA PATTERN - KEY PRINCIPLES SUMMARY"

echo -e "${BOLD}${GREEN}What Makes This a SAGA PATTERN?${NC}"
echo ""

echo -e "${BOLD}1. Long-Running Transactions Across Services${NC}"
echo "   • A single business transaction spans multiple microservices"
echo "   • Each service has its own database (no shared database)"
echo "   • Traditional ACID transactions cannot span services"
echo ""

echo -e "${BOLD}2. Sequence of Local Transactions${NC}"
echo "   • Each service performs its own local ACID transaction"
echo "   • These transactions are chained together"
echo "   • Sale → Inventory → Payment → Sale (completion)"
echo ""

echo -e "${BOLD}3. Compensating Transactions (The Core!)${NC}"
echo "   • For every action, there's a compensation action"
echo "   • Forward: DebitInventory ↔ Compensation: CreditInventory"
echo "   • Forward: DebitPayment ↔ Compensation: CreditPayment"
echo "   • Compensations execute in reverse order (backward recovery)"
echo ""

echo -e "${BOLD}4. Event-Driven Choreography${NC}"
echo "   • No central orchestrator (this is choreography, not orchestration)"
echo "   • Services communicate via domain events (Kafka)"
echo "   • Each service knows how to react to events autonomously"
echo "   • Loose coupling between services"
echo ""

echo -e "${BOLD}5. Eventual Consistency${NC}"
echo "   • System moves through intermediate states (PENDING)"
echo "   • Eventually reaches consistent final state (FINALIZED/CANCELED)"
echo "   • Trade-off: Gives up ACID isolation for scalability"
echo ""

echo -e "${BOLD}${YELLOW}Choreography vs Orchestration:${NC}"
echo "  This implementation uses CHOREOGRAPHY:"
echo "    ✓ Decentralized decision-making"
echo "    ✓ Services react to events independently"
echo "    ✓ No single point of failure"
echo "    ✗ Harder to understand the full flow"
echo "    ✗ Circular dependencies possible"
echo ""
echo "  Alternative: ORCHESTRATION would use:"
echo "    ✓ Central saga orchestrator service"
echo "    ✓ Easier to visualize and debug"
echo "    ✗ Single point of failure"
echo "    ✗ Orchestrator knows too much about all services"
echo ""

echo -e "${BOLD}${CYAN}When to Use Saga Pattern?${NC}"
echo "  ✓ Distributed transactions across microservices"
echo "  ✓ Need high availability and scalability"
echo "  ✓ Can tolerate eventual consistency"
echo "  ✓ Have well-defined compensation logic"
echo ""
echo "  ✗ Need immediate consistency"
echo "  ✗ Cannot define compensation (e.g., sending email)"
echo "  ✗ Simple monolithic application"
echo ""
