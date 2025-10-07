#!/bin/bash
set -e

# Parse user inputs (from platform UI/API)
while [[ $# -gt 0 ]]; do
  case $1 in
    --hotkey) MINER_HOTKEY="$2"; shift 2 ;;
    --deposit) DEPOSIT_AMOUNT="$2"; shift 2 ;;
    --eth-key) ETH_KEY="$2"; shift 2 ;;
    --ports) RENTING_PORT_RANGE="$2"; shift 2 ;;
    *) echo "Unknown option $1"; exit 1 ;;
  esac
done

# Step 1: Verify system
if ! hostnamectl | grep -q "Ubuntu 22"; then
  echo "Error: Requires Ubuntu 22+"; exit 1
fi
if ! uname -r | grep -q "^6\.[5-9]"; then
  echo "Error: Requires kernel 6.5+"; exit 1
fi

# Step 4: Verify NVIDIA
nvidia-smi || { echo "NVIDIA driver failed"; exit 1; }
lsmod | grep nvidia || sudo modprobe nvidia
nvidia-container-cli --version || { echo "Toolkit missing"; exit 1; }
docker info --format '{{.Runtimes}}' | grep nvidia || { echo "NVIDIA runtime missing"; exit 1; }

# Step 5: Verify Sysbox
docker run --rm --runtime=sysbox-runc --gpus all daturaai/compute-subnet-executor:latest nvidia-smi || { echo "Sysbox GPU failed"; exit 1; }

# Create directory structure
mkdir -p /opt/executor-sandbox/data
cd /opt/executor-sandbox

# Step 6: Configure .env
cp .env.template .env
sed -i "s/^MINER_HOTKEY_SS58_ADDRESS=.*/MINER_HOTKEY_SS58_ADDRESS=${MINER_HOTKEY}/" .env
sed -i "s/^INTERNAL_PORT=.*/INTERNAL_PORT=${INTERNAL_PORT:-8080}/" .env
sed -i "s/^EXTERNAL_PORT=.*/EXTERNAL_PORT=${EXTERNAL_PORT:-8081}/" .env
sed -i "s/^SSH_PORT=.*/SSH_PORT=${SSH_PORT:-22}/" .env
sed -i "s/^SSH_PUBLIC_PORT=.*/SSH_PUBLIC_PORT=${SSH_PUBLIC_PORT:-${SSH_PORT}}/" .env
if [ -n "${RENTING_PORT_RANGE}" ]; then
  sed -i "s/^RENTING_PORT_RANGE=.*/RENTING_PORT_RANGE=${RENTING_PORT_RANGE}/" .env
fi

# Notes: Open firewall
sudo ufw allow ${EXTERNAL_PORT} && sudo ufw reload

# Step 7: Run sandbox
docker compose up -d
for i in {1..10}; do
  if docker ps | grep executor; then break; fi
  sleep 5
done

# Notes: GPU compatibility check
curl -s https://raw.githubusercontent.com/Datura-ai/compute-subnet/main/neurons/validators/src/services/const.py | grep -q "$(nvidia-smi | grep -o 'A100\|H100')" || { echo "Warning: GPU may not be compatible"; }

echo "Executor running at $(hostname -I | awk '{print $1}'):${EXTERNAL_PORT}"
echo "Run on miner: docker exec -it <miner-container> pdm run /root/app/src/cli.py add-executor --address $(hostname -I | awk '{print $1}') --port ${EXTERNAL_PORT} --validator <validator-hotkey> --deposit_amount ${DEPOSIT_AMOUNT} --private-key ${ETH_KEY:0:10}..."