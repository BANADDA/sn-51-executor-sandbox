# SN-51 Executor Sandbox Image Guide

This guide explains how to use the custom-compute-subnet-executor Docker image to run an executor for the Compute Subnet on a rented GPU instance. The image encapsulates the executor setup, running in a Sysbox container with NVIDIA GPU access for secure, isolated mining.

## Prerequisites

### Host Requirements

Your rented GPU instance must have:

- **OS**: Ubuntu 22.04+ with kernel 6.5+ (verify with `hostnamectl`)
- **NVIDIA Drivers**: Installed and working (`nvidia-smi` shows GPU)
- **Docker**: Installed with NVIDIA Container Toolkit (`nvidia-container-cli --version`)
- **Sysbox**: Installed for rootless containers (`docker run --runtime=sysbox-runc` works)
- **GPU**: Compatible with Compute Subnet (e.g., A100, H100; see `const.py`)

Contact your platform provider if these are not pre-configured.

### User Requirements

You need:

- Miner hotkey SS58 address
- Validator hotkey, deposit amount, and Ethereum private key (for miner setup)
- Optional: Custom ports for internal/external, SSH, and renting range (e.g., 2000-2005)

## Using the Image

### 1. Prepare the Environment

Your platform should provide `docker-compose.yml` and `.env.template` in `/opt/executor-sandbox`.

Create a data directory:

```bash
mkdir -p /opt/executor-sandbox/data
```

Edit `.env` with your settings (provided via platform UI):

```bash
cp /opt/executor-sandbox/.env.template /opt/executor-sandbox/.env
nano /opt/executor-sandbox/.env
```

Update the following variables:

- `MINER_HOTKEY_SS58_ADDRESS`: Your miner hotkey
- `INTERNAL_PORT`, `EXTERNAL_PORT`: Defaults (8080, 8081) or custom values
- `SSH_PORT`, `SSH_PUBLIC_PORT`: Defaults (22) or custom values
- `RENTING_PORT_RANGE`: E.g., 2000-2005 (or use `RENTING_PORT_MAPPINGS`)

### 2. Run the Executor Sandbox

Pull the image:

```bash
docker pull <registry>/custom-compute-subnet-executor:latest
```

Replace `<registry>` with your platform's registry (e.g., `docker.io/your-org`).

Start the sandbox:

```bash
cd /opt/executor-sandbox
docker compose up -d
```

Verify it's running:

```bash
docker ps
docker logs executor
```

### 3. Add Executor to Central Miner

On your central miner, run:

```bash
docker exec -it <miner-container> pdm run /root/app/src/cli.py add-executor \
  --address <rental-ip> \
  --port <external-port> \
  --validator <validator-hotkey> \
  --deposit_amount <deposit-amount> \
  --private-key <eth-private-key>
```

Where:

- `<rental-ip>`: Instance IP (provided by platform)
- `<external-port>`: From `.env` (e.g., 8081)
- Other values: From your platform UI inputs

### 4. Monitor the Executor

Check earnings on [Taomarketcap](https://taomarketcap.com).

View logs:

```bash
docker logs -f executor
```

## Troubleshooting

**GPU Not Detected**: Run the following test:

```bash
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

If it fails, check NVIDIA drivers (`nvidia-smi`) and toolkit installation.

**Sysbox Issues**: Test with:

```bash
docker run --rm --runtime=sysbox-runc --gpus all daturaai/compute-subnet-executor:latest nvidia-smi
```

**Port Errors**: Ensure `<external-port>` is open:

```bash
sudo ufw allow <external-port>
```

**Logs**: Check container logs or system logs:

```bash
docker logs executor
sudo journalctl -u docker
```

## Contributing

To contribute to this project or suggest improvements, reach out to the developer on GitHub: [@BANADDA](https://github.com/BANADDA). Submit issues or pull requests to enhance the executor sandbox.

## License

[Add your license information here]

---

For additional support, consult your platform provider's documentation or contact their support team.