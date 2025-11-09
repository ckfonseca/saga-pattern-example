# Saga Pattern Example - Choreography

[![Test Saga Pattern](https://github.com/naive/saga-pattern-example/actions/workflows/test.yml/badge.svg)](https://github.com/naive/saga-pattern-example/actions/workflows/test.yml)

Microservices implementation using the Saga Pattern with choreography approach. This project demonstrates event-driven architecture using Apache Kafka for communication between services.

## Architecture

```
┌─────────────────┐       ┌──────────────────┐       ┌─────────────────────┐
│  Sale Service   │       │ Inventory Service│       │  Payment Service    │
│   (Port 8081)   │       │   (Port 8082)    │       │   (Port 8083)       │
└────────┬────────┘       └────────┬─────────┘       └──────────┬──────────┘
         │                         │                             │
         │                         │                             │
         └─────────────────────────┼─────────────────────────────┘
                                   │
                           ┌───────▼────────┐
                           │  Apache Kafka  │
                           │  (Port 9092)   │
                           └────────────────┘
```

### Services

- **Sale Service**: Manages order creation and orchestrates the saga
- **Inventory Service**: Handles inventory reservation and rollback
- **Payment Service**: Processes payments and refunds
- **Kafka**: Event streaming platform for inter-service communication
- **MySQL Databases**: Separate database for each service

## Quick Start

### Prerequisites

- Docker and Docker Compose v2.20+ (for compose file v3 with `include` support)
- **Just** command runner - [Installation](https://github.com/casey/just#installation)
- Java 17+ (if running locally without Docker)

### Docker Compose Architecture

**Files:**
- `compose.yml` - Development (ports 8081-8083, persistent DBs)
- `compose.test.yml` - Testing (ports 8091-8093, ephemeral DBs)

**Both environments can run simultaneously without conflicts**

### 1. Configure Environment Variables

Copy the example environment file and adjust if needed:

```bash
cp .env.example .env
```

The `.env` file contains database configuration for all three services (sale, inventory, payment).

**Environment Variables:**

```bash
# Sale Service Database
SALE_DB_NAME=sales_db                    # Database name
SALE_DB_ROOT_PWD=root                    # MySQL root password
SALE_DB_APP_USERNAME=sales_app_user      # Application user
SALE_DB_APP_USER_PWD=123456             # Application password

# Inventory Service Database
INVENTORY_DB_NAME=inventory_db
INVENTORY_DB_ROOT_PWD=root
INVENTORY_DB_APP_USERNAME=inventory_app_user
INVENTORY_DB_APP_USER_PWD=123456

# Payment Service Database
PAYMENT_DB_NAME=payment_db
PAYMENT_DB_ROOT_PWD=root
PAYMENT_DB_APP_USERNAME=payment_app_user
PAYMENT_DB_APP_USER_PWD=123456
```

**Note:** The `.env` file is gitignored. Always use `.env.example` as a template and never commit `.env` to version control.

### 2. Build and Start the Application

#### Using Just (Recommended)

```bash
# Start all services (infrastructure + applications)
just up

# Or use Docker Compose directly
docker compose up -d
```

#### Using Docker Compose Manually

```bash
# Build all images
docker compose build

# Start all services
docker compose up -d

# Or step by step
docker compose build                    # Build all images
docker compose up -d zookeeper kafka-service kafka-ui  # Start Kafka infrastructure
docker compose up -d sale-db-service inventory-db-service payment-db-service  # Start databases
docker compose up -d sale-service inventory-service payment-service  # Start applications
```

### 3. Verify Services are Running

```bash
# Check service status
docker compose ps
```

**Note:** Kafka topics are automatically created when the services start publishing/consuming messages. They are persisted in the `kafka-data` volume.

### 4. Access the Services

#### Service Endpoints

**Important:** These are REST APIs without web interfaces. Access them using curl, Postman, or similar HTTP clients.

```bash
# Display all endpoints and example API calls
just endpoints
```

**Available Services:**

| Service | Port | Type | Description |
|---------|------|------|-------------|
| Sale Service | 8081 | REST API | Sales creation endpoint (POST /api/v1/sales) |
| Inventory Service | 8082 | Event-Driven | Listens to Kafka topics for inventory operations |
| Payment Service | 8083 | Event-Driven | Listens to Kafka topics for payment operations |
| Kafka UI | 8181 | Web UI | Web interface for Kafka monitoring |
| Kafka Broker | 9092 | TCP | Kafka broker for client connections |

#### Example API Calls

```bash
# Create a new sale (triggers the saga)
curl -X POST http://localhost:8081/api/v1/sales \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "productId": 1,
    "quantity": 2,
    "value": 99.90
  }'

# Monitor Kafka messages in real-time
just kafka-ui
# Then navigate to http://localhost:8181 in your browser

# View sale service logs to see saga execution
docker compose logs -f sale-service

# View all services logs
just logs-app
```

**Important Notes:**
- **Sale Service** is the only service with REST endpoints (POST only)
- **Inventory and Payment Services** are event-driven - they listen to Kafka topics and respond via events
- If you access http://localhost:8081 directly in a browser, you'll see a "Whitelabel Error Page" (404) because there's no root endpoint or HTML interface - this is expected behavior for REST APIs

## Just Commands

Run `just` (or `just --list`) to see all available commands:

### General Commands
- `just up` - Start all services (infrastructure + applications)
- `just down` - Stop all services
- `just restart` - Restart all services
- `just reset` - Complete reset: clean, rebuild, and start fresh

### Cleanup Commands
- `just clean` - Clean development environment (containers, volumes, images)
- `just clean-test` - Clean test environment only
- `just clean-all` - Clean both dev and test environments
- `just clean-cache` - Remove dangling images and build cache (safe, quick)
- `just prune` - Remove all unused Docker resources (requires confirmation)

### Monitoring & Logs
- `just logs` - Show logs from all services
- `just logs-infra` - Show logs from infrastructure services only
- `just logs-app` - Show logs from application services only

### Kafka Commands
- `just kafka-ui` - Open Kafka UI in browser
- `just kafka-consume-dev` - Consume messages from dev environment
- `just kafka-consume-test` - Consume messages from test environment

### Testing & Demo
- `just demo` - Run interactive demo (resets environment with confirmation)
- `just test` - Run automated integration test suite (CI/CD ready)

### Database Commands
- `just db-sales` - Show recent sales data (development)
- `just db-inventory` - Show inventory data (development)
- `just db-payment` - Show user balances (development)
- `just db-all` - Show all database data (development)
- `just db-sales-test` - Show recent sales data (test)
- `just db-inventory-test` - Show inventory data (test)
- `just db-payment-test` - Show user balances (test)
- `just db-all-test` - Show all database data (test)

### Service Access
- `just endpoints` - Display all service endpoints and example API calls

## Project Structure

```
saga-pattern-example/
├── saga-choreography/
│   ├── sale-service/           # Sale microservice
│   │   ├── src/
│   │   ├── pom.xml
│   │   └── Dockerfile
│   ├── inventory-service/      # Inventory microservice
│   │   ├── src/
│   │   ├── pom.xml
│   │   └── Dockerfile
│   └── payment-service/        # Payment microservice
│       ├── src/
│       ├── pom.xml
│       └── Dockerfile
├── docker/database/            # Database Dockerfile and scripts
├── docs/                       # Documentation
│   └── kafka-conceitos-basicos.md
├── scripts/                    # Automation scripts
│   └── demo-saga.sh           # Interactive demo script
├── tests/                      # Test suites
│   └── integration/           # Integration tests
│       └── integration-test.sh # Automated integration test suite
├── .env                        # Environment variables (gitignored)
├── .env.example                # Environment variables template
├── compose.yml                 # Docker Compose (dev environment)
├── compose.test.yml            # Docker Compose (test environment)
├── .justfile                   # Just command runner recipes
└── README.md
```

## Data Persistence

The application uses Docker volumes to persist data across container restarts:

### Volumes (Development Environment)

| Volume Name | Purpose | Data Stored |
|-------------|---------|-------------|
| `kafka-data` | Kafka data | Kafka topics, messages, and metadata (KRaft mode) |
| `sales-db-volume` | Sale service database | Sales data and transactions |
| `inventory-db-volume` | Inventory service database | Inventory data |
| `payment-db-volume` | Payment service database | Payment data |

**Important:**
- Volumes persist data even when containers are stopped or removed
- Kafka uses KRaft mode (no Zookeeper required) with metadata stored in `kafka-data` volume
- Test environment uses ephemeral storage (no volumes - fresh state every run)
- To completely reset the system, use `just clean` which removes all volumes

## Technology Stack

- **Java 17** - Programming language
- **Spring Boot 3.3.0** - Application framework
- **Spring Kafka** - Kafka integration
- **Spring Data JPA** - Database access
- **Spring State Machine** - Saga orchestration
- **Apache Kafka 4.1.0** (KRaft mode - no Zookeeper) - Event streaming
- **MySQL 8.0** - Database
- **Docker & Docker Compose** - Containerization
- **Maven 3.9** - Build tool
- **Lombok** - Code generation
- **MapStruct** - Object mapping

## Configuration

### Environment Variables

The application uses environment variables to configure database and Kafka connections. These variables are defined in the `.env` file and used by Docker Compose.

#### Database Configuration Variables

Each service has its own database with the following configurable parameters:

| Variable | Description | Default Value | Used By |
|----------|-------------|---------------|---------|
| `SALE_DB_NAME` | Sale service database name | `sales_db` | Sale DB |
| `SALE_DB_ROOT_PWD` | Sale DB root password | `root` | Sale DB |
| `SALE_DB_APP_USERNAME` | Sale DB application user | `sales_app_user` | Sale DB |
| `SALE_DB_APP_USER_PWD` | Sale DB application password | `123456` | Sale DB |
| `INVENTORY_DB_NAME` | Inventory service database name | `inventory_db` | Inventory DB |
| `INVENTORY_DB_ROOT_PWD` | Inventory DB root password | `root` | Inventory DB |
| `INVENTORY_DB_APP_USERNAME` | Inventory DB application user | `inventory_app_user` | Inventory DB |
| `INVENTORY_DB_APP_USER_PWD` | Inventory DB application password | `123456` | Inventory DB |
| `PAYMENT_DB_NAME` | Payment service database name | `payment_db` | Payment DB |
| `PAYMENT_DB_ROOT_PWD` | Payment DB root password | `root` | Payment DB |
| `PAYMENT_DB_APP_USERNAME` | Payment DB application user | `payment_app_user` | Payment DB |
| `PAYMENT_DB_APP_USER_PWD` | Payment DB application password | `123456` | Payment DB |

#### Application Configuration

Each Spring Boot service uses the following environment variables (set by Docker Compose):

| Variable | Description | Value in Docker | Local Development |
|----------|-------------|-----------------|-------------------|
| `SPRING_DATASOURCE_URL` | JDBC connection URL | `jdbc:mysql://<service>:3306/<db>` | `jdbc:mysql://localhost:330X/<db>` |
| `SPRING_DATASOURCE_USERNAME` | Database username | From `.env` | From `application.yaml` |
| `SPRING_DATASOURCE_PASSWORD` | Database password | From `.env` | From `application.yaml` |
| `SPRING_KAFKA_BOOTSTRAP_SERVERS` | Kafka broker address | `kafka:29092` | `localhost:9092` |

**Note:** The `application.yaml` files use Spring Boot's property placeholder syntax `${VAR:default}` to support both Docker and local development environments.

### Kafka Topics

The application uses a single topic for saga orchestration:

| Topic Name | Partitions | Replication Factor | Purpose |
|------------|------------|-------------------|---------|
| `tp-saga-sale` | 3 | 1 | Saga orchestration events for order processing |

**Consumer Groups:**
- `inventory-credit` - Inventory service (credit operations)
- `inventory-debit` - Inventory service (debit operations)
- `payment` - Payment service
- `sale-cancel` - Sale service (cancellation handling)

## Health Checks

All services include optimized health checks for faster startup:

**Development Environment:**
- **Databases**: MySQL ping + connection test every 3s (start period: 20s)
- **Kafka**: Broker API version check every 5s (start period: 20s)
- **Applications**: HTTP endpoint check every 5s (start period: 25s)

**Test Environment:**
- Same as development with ephemeral storage for faster resets

Health check configuration ensures proper startup order:
1. Databases and Kafka start in parallel
2. Applications wait for their respective databases and Kafka to be healthy
3. HikariCP connection pool configured with retry logic for resilience

## Troubleshooting

### "Whitelabel Error Page" when accessing services in browser

If you see this error when accessing http://localhost:8081 (or 8082, 8083):
```
Whitelabel Error Page
This application has no explicit mapping for /error, so you are seeing this as a fallback.
There was an unexpected error (type=Not Found, status=404).
```

**This is expected behavior!** These are REST APIs without web UIs. You need to:

1. Use the correct API endpoint (e.g., http://localhost:8081/api/v1/sales)
2. Use an HTTP client like curl, Postman, or HTTPie

```bash
# Display all available endpoints
just endpoints

# Example: List all sales
curl http://localhost:8081/api/v1/sales
```

### Services not starting
```bash
# Check logs
just logs

# Check specific service
docker compose logs -f sale-service
```

### Database connection issues
```bash
# Verify databases are healthy
docker compose ps

# Check database logs
docker compose logs -f sale-db-service
```

### Kafka connection issues
```bash
# Check Kafka is healthy
docker compose logs -f kafka-service

# Verify Kafka is accessible (Kafka 4.1.0 with KRaft mode)
docker exec kafka /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:29092

# List topics to verify Kafka is working (optional)
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:29092 --list
```

### Application can't connect to Kafka
If you see errors like `Connection to node -1 (localhost/127.0.0.1:9092) could not be established`:

1. Verify the application is using the correct Kafka address:
   ```bash
   docker exec sale-service-container env | grep KAFKA
   # Should show: SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka:29092
   ```

2. Ensure Kafka is healthy before starting applications:
   ```bash
   just up              # Start all services
   docker compose ps    # Wait for Kafka to be healthy
   ```

**Note:** Topics are created automatically by Kafka when services start.

### Clean restart
```bash
# Stop everything and remove volumes
just clean

# Rebuild and start fresh
just reset
```

## Development

### Building Services Locally

```bash
# Build a specific service
cd saga-choreography/sale-service
./mvnw clean package

# Run locally (requires local MySQL and Kafka)
./mvnw spring-boot:run
```

### Hot Reload During Development

```bash
# Rebuild specific service
docker compose build sale-service

# Restart specific service
docker compose restart sale-service
```

## Testing the Saga Pattern

### 🎬 Interactive Demo (RECOMMENDED)

**The best way to understand the Saga Pattern is through our interactive demonstration!**

This guided demo walks you through each scenario with:
- 📊 Real-time database state visualization
- 🔍 Step-by-step explanations of Saga Pattern principles
- ⏸️ Pauses for observation and exploration
- 📨 Visible event flows through Kafka
- 🎓 Educational content explaining WHY this is a Saga Pattern

```bash
# Run the interactive demo
just demo

# Or directly
./scripts/demo-saga.sh
```

**What you'll learn:**
1. **Distributed Transactions** - How Saga breaks them into local transactions
2. **Event-Driven Choreography** - Services coordinating through Kafka events
3. **Semantic Locks** - Business-level validations and early failure detection
4. **Compensating Transactions** - The core of Saga Pattern (backward recovery)
5. **Eventual Consistency** - BASE vs ACID trade-offs

Each scenario demonstrates a key characteristic of the Saga Pattern with before/after database states and detailed explanations.

---

### 🧪 Automated Test Suite (CI/CD Ready)

**Production-ready automated testing with intelligent polling (no hardcoded sleeps!)**

The test suite (`tests/integration/integration-test.sh`) runs against a completely separate test environment with:
- ✅ **Different ports** (8091-8093) - Won't interfere with dev environment
- ✅ **Isolated containers** - Fresh test containers for each run
- ✅ **Ephemeral databases** - Clean state guaranteed
- ✅ **Smart polling** - No hardcoded sleeps, waits only as needed
- ✅ **CI/CD integration** - GitHub Actions runs tests automatically
- ✅ **Exit codes** - 0 = success, 1 = failure

```bash
# Run full automated test suite
just test

# What happens:
# 1. Spins up isolated test environment (compose.test.yml)
# 2. Waits for services health (polling every 1s, max 60s)
# 3. Runs 6 comprehensive test scenarios
# 4. Verifies saga behavior (success, failures, compensation)
# 5. Cleans up automatically if tests pass
# 6. Exits with proper status code for CI/CD
```

**Test Scenarios Covered:**
1. ✅ **Successful Purchase** - Happy path with balance and inventory checks
2. ❌ **Insufficient Stock** - Immediate rejection, no compensation needed
3. 🔄 **Insufficient Balance** - Saga compensation (inventory rollback)
4. ✅ **Another Successful Purchase** - Validates consistent behavior
5. 🔀 **Concurrent Transactions** - Tests eventual consistency
6. ✔️ **System Consistency** - Verifies no pending transactions

**Notes:**
- The test suite automatically starts a fresh test environment
- All containers and volumes are cleaned up after tests complete
- Test environment runs on different ports (8091-8093) to avoid conflicts with dev environment

---

### Quick Start - Automated Testing (Legacy)

The easiest way to test the system without interaction:

```bash
# Option A: First time setup (recommended)
just reset

# Option B: If already running (dev environment)
just demo  # Interactive demo
```

**Note:** Databases are initialized automatically with test data on first startup via init scripts.

**Test Users (auto-created):**
- Cristiano Fonseca (ID: 1) - R$ 1,000.00
- Rodrigo Brayner (ID: 2) - R$ 500.00

**Test Products (auto-created):**
- Product IDs: 6, 7, 8, 9, 10
- Stock quantities: 10, 5, 50, 30, 20 units

This will execute 5 different scenarios demonstrating:
- ✅ Successful event flow (sale → inventory → payment)
- ❌ Insufficient stock failures
- ❌ Insufficient balance failures (with compensation)
- 🔄 Rollback mechanisms

---

### Manual Testing

#### Execute Test Scenarios

**Scenario 1: Successful Purchase** ✅
```bash
# Cristiano buys 2 products (has R$ 1,000 - enough balance)
curl -X POST http://localhost:8081/api/v1/sales \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "productId": 6,
    "quantity": 2,
    "value": 200.00
  }'

# Expected result: FINALIZED
# Inventory: 10 → 8 units
# Balance: R$ 1,000 → R$ 800
```

**Scenario 2: Insufficient Stock** ❌
```bash
# Rodrigo tries to buy 10 products (only 5 available)
curl -X POST http://localhost:8081/api/v1/sales \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 2,
    "productId": 7,
    "quantity": 10,
    "value": 300.00
  }'

# Expected result: CANCELED
# Inventory: unchanged (5 units)
# Balance: unchanged
```

**Scenario 3: Insufficient Balance (with Compensation)** 🔄
```bash
# Rodrigo tries to buy for R$ 600 (only has R$ 500)
curl -X POST http://localhost:8081/api/v1/sales \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 2,
    "productId": 6,
    "quantity": 3,
    "value": 600.00
  }'

# Expected result: CANCELED with COMPENSATION
# Inventory: 10 → 7 → 10 (debited then credited back)
# Balance: unchanged (R$ 500)
```

#### Monitor Saga Execution

```bash
# Watch all services logs
just logs-app

# Or watch specific services
docker compose logs -f sale-service inventory-service payment-service

# View Kafka messages
just kafka-ui
# Navigate to http://localhost:8181 → Topics → tp-saga-sale

# Or consume messages directly from terminal
just kafka-consume
```

#### Verify Results

```bash
# Check sales
docker exec -it sales-db-container mysql -uroot -proot sales_db \
  -e "SELECT id, user_id, product_id, quantity, value, status FROM sale ORDER BY id DESC LIMIT 5;"

# Check inventory
docker exec -it inventory-db-container mysql -uroot -proot inventory_db \
  -e "SELECT product_id, quantity FROM inventories;"

# Check payments and balances
docker exec -it payment-db-container mysql -uroot -proot payment_db \
  -e "SELECT * FROM payments;" \
  -e "SELECT id, name, balance FROM users;"
```

---

### Understanding the Saga Flow

The choreography saga works as follows:

**Happy Path (Success):**
1. **Sale Service** receives POST request → Creates sale (status: `PENDING`)
2. **Sale Service** publishes `CREATED_SALE` event to Kafka
3. **Inventory Service** listens to `CREATED_SALE`
   - Checks stock availability
   - Debits inventory
   - Publishes `UPDATED_INVENTORY` event
4. **Payment Service** listens to `UPDATED_INVENTORY`
   - Checks user balance
   - Debits balance
   - Creates payment record
   - Publishes `VALIDATED_PAYMENT` event
5. **Sale Service** listens to `VALIDATED_PAYMENT`
   - Updates sale status to `FINALIZED`

**Failure Scenarios:**

- **Insufficient Stock:**
  - Inventory Service publishes `ROLLBACK_INVENTORY`
  - Sale Service cancels sale (status: `CANCELED`)

- **Insufficient Balance (with Compensation):**
  - Payment Service publishes `FAILED_PAYMENT`
  - Inventory Service **credits back** the reserved stock (compensation)
  - Sale Service cancels sale (status: `CANCELED`)

**Log Messages to Watch For:**
```
✅ Success:
  "Creating the sale..."
  "Sale created with success."
  "Beginning of merchandise separation."
  "End of merchandise separation."
  "Beginning of payment."
  "End of payment."
  "Sale finalized with success."

❌ Stock Failure:
  "ERROR - Insufficient quantity"
  "Canceling the sale..."
  "Sale canceled"

🔄 Payment Failure + Compensation:
  "ERROR - Insufficient funds!"
  "Crediting inventory back (compensation)"
  "Canceling the sale..."
  "Sale canceled"
```

## Documentation

- **[Saga Pattern Tutorial](./docs/saga-pattern-tutorial.md)** - Complete tutorial for teaching Saga Pattern (perfect for classes/presentations)
  - Conceptual explanations with Mermaid diagrams
  - Detailed flow descriptions (success and failure scenarios)
  - Real-world test scenarios with expected results
  - No code details - focused on architecture and patterns

- **[Kafka Basic Concepts](./docs/kafka-conceitos-basicos.md)** - Comprehensive guide to Kafka fundamentals (in Portuguese)
