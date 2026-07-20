# Provisioning from scratch (Proxmox → VM → Ollama)

This repo defines the **containers** (Dockerfiles + compose). It does **not** by
itself stand up a working host — the GPUs must be passed into the VM and the VM
must have the NVIDIA driver, Docker, and the NVIDIA Container Toolkit. This doc
plus `setup.sh` close that gap.

Hardware target: 4× Quadro P4000 + 2× Quadro P2000 (6 GPUs, Pascal / compute 6.1).

---

## Part 1 — Proxmox host: GPU passthrough (manual, one-time)

Passthrough happens at the hypervisor and cannot be scripted from inside the
repo. Do this on the **Proxmox host**, not the VM.

### 1. Enable IOMMU

Edit the kernel cmdline. For an Intel host:

```bash
# /etc/default/grub  ->  GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
# (AMD host: use "amd_iommu=on iommu=pt")
update-grub
```

If the host boots with systemd-boot instead of GRUB, put the same flags in
`/etc/kernel/cmdline` and run `proxmox-boot-tool refresh`.

### 2. Load VFIO modules

```bash
cat >> /etc/modules <<'EOF'
vfio
vfio_iommu_type1
vfio_pci
EOF
```

### 3. Stop the host from grabbing the NVIDIA cards

```bash
cat > /etc/modprobe.d/blacklist-nvidia.conf <<'EOF'
blacklist nouveau
blacklist nvidia
blacklist nvidiafb
EOF
```

Bind the GPUs to vfio-pci by vendor:device id. Find the ids with
`lspci -nn | grep -i nvidia` (P4000/P2000 are all NVIDIA vendor `10de`):

```bash
# example — replace with YOUR device ids from lspci
echo "options vfio-pci ids=10de:1bb1,10de:1c30" > /etc/modprobe.d/vfio.conf
update-initramfs -u -k all
reboot
```

After reboot, `lspci -nnk -d 10de:` should show `Kernel driver in use: vfio-pci`
for each card.

### 4. Attach the GPUs to the VM

In the Proxmox UI: **VM → Hardware → Add → PCI Device**, add each GPU (or edit
`/etc/pve/qemu-server/<vmid>.conf` and add `hostpciN:` lines). For 6 cards you
generally want:

- `machine: q35` and OVMF (UEFI) BIOS on the VM
- Add all 6 as separate `hostpci0..5` entries, or use function-level entries if
  cards share IOMMU groups.

> With 6 discrete GPUs, confirm each is in its **own** IOMMU group
> (`find /sys/kernel/iommu_groups/ -type l`). If cards are grouped together you
> may need ACS override — treat that as a security trade-off, not a default.

---

## Part 2 — Inside the VM (scripted)

Use an Ubuntu 22.04 (or Debian 12) guest. Then:

```bash
git clone https://github.com/tmecklem/ollama-server.git
cd ollama-server
sudo ./setup.sh          # installs NVIDIA driver, Docker, NVIDIA Container Toolkit
# log out/in (or: newgrp docker) so your user picks up the docker group
```

`setup.sh` is idempotent — re-running it is safe. It verifies GPU visibility at
the end with a CUDA container.

---

## Part 3 — Run the stack

```bash
# Ollama only:
docker compose up -d ollama

# Ollama + Open WebUI GUI (http://<vm-ip>:3000):
docker compose -f docker-compose-webui.yml up -d

# Pull a model (downloads into the ollama_data volume, NOT into git):
docker exec ollama-server ollama pull mixtral:8x7b-instruct-v0.1-q4_K_M
```

See `README.md` for model recommendations and `GUI_ACCESS.md` for the web UI.

---

## What is still NOT in git (by design)

- **Models** — pulled at runtime into the `ollama_data` Docker volume (tens of GB).
- **Persistent volumes** — `ollama_data`, `open-webui-data` live on the VM disk.
  Back these up separately; they are not reconstructable from this repo.
- **Proxmox host config** — Part 1 above lives on the hypervisor, outside any VM.
