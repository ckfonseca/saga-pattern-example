#!/bin/bash
set -e

# Directory where Kafka stores data
DATA_DIR="/var/lib/kafka/data"
CLUSTER_ID_FILE="${DATA_DIR}/.cluster_id"

# Check if data directory exists and has been initialized
if [ ! -f "${CLUSTER_ID_FILE}" ]; then
    echo "==> No existing cluster ID found. Generating new one..."

    # Generate a new cluster ID
    CLUSTER_ID=$(/opt/kafka/bin/kafka-storage.sh random-uuid)
    echo "==> Generated CLUSTER_ID: ${CLUSTER_ID}"

    # Save cluster ID for future reference
    mkdir -p "${DATA_DIR}"
    echo "${CLUSTER_ID}" > "${CLUSTER_ID_FILE}"
    echo "==> Cluster ID saved to ${CLUSTER_ID_FILE}"
else
    CLUSTER_ID=$(cat "${CLUSTER_ID_FILE}")
    echo "==> Using existing CLUSTER_ID: ${CLUSTER_ID}"
fi

# Export CLUSTER_ID for the official Kafka entrypoint to use
export CLUSTER_ID

# Start Kafka with the original Docker entrypoint
echo "==> Starting Kafka with CLUSTER_ID: ${CLUSTER_ID}"
exec /etc/kafka/docker/run
