#!/usr/bin/env bash
#
# VM provisioning for the Ollama/vLLM GPU stack.
# Run INSIDE the guest VM (Ubuntu 22.04 / Debian 12) after the GPUs have been
# passed through at the Proxmox host level. See PROVISIONING.md Part 1.
#
# Installs: NVIDIA driver, Docker Engine + Compose plugin, NVIDIA Container
# Toolkit. Idempotent — safe to re-run.
#
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (sudo ./setup.sh)" >&2
  exit 1
fi

# The non-root user to add to the docker group (the invoking sudo user).
TARGET_USER="${SUDO_USER:-root}"

echo "==> Checking GPUs are visible to the VM"
if ! lspci -nn | grep -qi '10de:'; then
  echo "ERROR: No NVIDIA GPUs found via lspci." >&2
  echo "       GPU passthrough is not working — fix Proxmox Part 1 first." >&2
  exit 1
fi
lspci -nn | grep -i '10de:' || true

echo "==> Installing base packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

# ---------------------------------------------------------------------------
# NVIDIA driver
# ---------------------------------------------------------------------------
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
  echo "==> NVIDIA driver already working; skipping driver install"
else
  echo "==> Installing NVIDIA driver"
  # ubuntu-drivers picks a driver compatible with Pascal (P4000/P2000).
  apt-get install -y ubuntu-drivers-common
  ubuntu-drivers autoinstall
  echo "==> Driver installed. A REBOOT is required before nvidia-smi will work."
  NEEDS_REBOOT=1
fi

# ---------------------------------------------------------------------------
# Docker Engine + Compose plugin
# ---------------------------------------------------------------------------
if command -v docker >/dev/null 2>&1; then
  echo "==> Docker already installed; skipping"
else
  echo "==> Installing Docker Engine"
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
fi

if [[ "$TARGET_USER" != "root" ]]; then
  echo "==> Adding $TARGET_USER to docker group"
  usermod -aG docker "$TARGET_USER"
fi

# ---------------------------------------------------------------------------
# NVIDIA Container Toolkit (lets Docker expose GPUs to containers)
# ---------------------------------------------------------------------------
if [[ -f /etc/apt/sources.list.d/nvidia-container-toolkit.list ]] \
   && command -v nvidia-ctk >/dev/null 2>&1; then
  echo "==> NVIDIA Container Toolkit already installed; skipping repo setup"
else
  echo "==> Installing NVIDIA Container Toolkit"
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    > /etc/apt/sources.list.d/nvidia-container-toolkit.list
  apt-get update
  apt-get install -y nvidia-container-toolkit
fi

echo "==> Configuring Docker to use the NVIDIA runtime"
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------
if [[ "${NEEDS_REBOOT:-0}" == "1" ]]; then
  cat <<'EOF'

============================================================
 Driver was just installed — REBOOT now, then re-run this
 script to complete verification:

   sudo reboot
   # after reboot:
   sudo ./setup.sh
============================================================
EOF
  exit 0
fi

echo "==> Verifying GPU access from a container"
if docker run --rm --gpus all nvidia/cuda:11.8.0-runtime-ubuntu22.04 nvidia-smi; then
  echo
  echo "SUCCESS: Docker can see the GPUs. Next:"
  echo "  docker compose up -d ollama"
  echo "  # or: docker compose -f docker-compose-webui.yml up -d"
else
  echo "GPU verification failed — check driver + toolkit install above." >&2
  exit 1
fi
