# sid_Docker 🧬

A lightweight, battery-optimized, containerized Linux GUI workstation tailored for **MacBook Air/Pro (Apple Silicon M-Series)** and Linux/Windows systems. Pre-configured with **AutoDockTools 1.5.7 (ADT)**, **VMD 2.0.0 (Visual Molecular Dynamics)**, **PMV**, **AutoDock 4**, **AutoDock Vina**, and **OpenBabel 3.1.1** accessible directly through your web browser via **KasmVNC**.

---

## ⚡ Key Highlights & Optimizations

* **MacBook Air Fanless Optimization**: Idle container load is **~0.3% CPU** and **~650 MB RAM**. The Mac chassis stays completely cool.
* **Solid Black Backdrop**: Background wallpaper is configured to pure black (`#000000`), reducing remote desktop tile-encoding CPU overhead by over 90% and making window dragging buttery smooth over VNC/WebRTC.
* **Window Decoration Fixes**: Titlebars, close `[X]`, and maximize `[□]` buttons remain fully functional without losing borders when maximized (`borderless_maximize = false`).
* **Clean Single Bottom Panel**: Clean XFCE interface with Applications Menu, taskbar, expanding separator, and system tray. Zero desktop icon clutter.
* **Network Security**: Port 3000 is bound strictly to `127.0.0.1` (localhost only), preventing exposure to public or campus Wi-Fi networks.
* **Pre-configured Terminal**: Shell prompt set to `sid_Docker` across interactive and login sessions.

---

## 📦 Installed Tools & Software

| Tool | Version | Description | Launch Command / Menu |
| :--- | :--- | :--- | :--- |
| **AutoDockTools (ADT)** | 1.5.7 | Molecular docking setup and analysis | Applications Menu → `AutoDockTools` or `adt` |
| **Python Molecular Viewer (PMV)**| 1.5.7 | Scripps molecular visualization | Applications Menu → `PMV` or `pmv` |
| **VMD** | 2.0.0 | Visual Molecular Dynamics (OpenGL) | Applications Menu → `VMD` or `vmd` |
| **AutoDock Vina** | 1.2.x | High-performance docking engine | Terminal → `vina` |
| **AutoDock 4** | 4.2.6 | Lamarckian genetic docking engine | Terminal → `autodock` |
| **OpenBabel** | 3.1.1 | Chemical format converter & 3D builder| Terminal → `obabel` |
| **Desktop Environment** | XFCE 4.16 | Lightweight X11 desktop environment | Web Browser (KasmVNC) |

---

## 📋 Prerequisites

* **Docker Desktop** installed on macOS, Linux, or Windows.
  * *For Apple Silicon (M1/M2/M3/M4)*: In **Docker Desktop > Settings > General**, ensure **"Use Rosetta for x86/amd64 emulation on Apple Silicon"** is checked.
* **Docker Compose V2** (`docker compose`).

---

## 🚀 Quick Start Guide

### Step 1: Clone the Repository
```bash
git clone https://github.com/sid0sid-ops/sid_Docker.git
cd sid_Docker
```

### Step 2: Download the Required Tool Archives
Due to licensing and GitHub's 100 MB file limit, place the official source tarballs directly into the root of this directory:

1. **MGLTools 1.5.7 (Linux 64-bit)**:
   * Download `mgltools_x86_64Linux2_1.5.7p1.tar.gz` from the [Scripps MGLTools Downloads Page](https://ccsb.scripps.edu/mgltools/downloads/).
   * Place `mgltools_x86_64Linux2_1.5.7p1.tar.gz` in the `sid_Docker/` folder.

2. **VMD 2.0.0 (Linux OpenGL 64-bit)**:
   * Register for free and download the Linux 64-bit OpenGL release (`vmd-2.0.0.bin.LINUXAMD64.tar.gz` or similar) from the [UIUC VMD Download Page](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD).
   * Rename the downloaded tarball to `vmd.tar.gz` and place it in the `sid_Docker/` folder.

### Step 3: Build and Start the Workstation
```bash
docker compose up -d --build
```

### Step 4: Access the Desktop
Open your browser and navigate to:
```text
http://127.0.0.1:3000
```
Your desktop environment will open immediately. No login credentials required.

---

## 📂 File Sharing & Workspace

* **Workspace Mount**:
  By default, `docker-compose.yml` mounts `..:/workspace` (or `./workspace:/workspace`) so all your docking files (PDB, PDBQT, GPF, DPF, SDF, and config files) on your host Mac/PC are directly accessible inside `/workspace`.
* **Desktop Persistence**:
  User settings (XFCE panels, bash history, terminal settings) are persistently stored in the local `./config` folder and survive container recreations.

---

## 🛠️ Typical Docking Workflow

You can run your entire docking pipeline inside the container terminal:

```bash
# 1. Convert ligand to 3D PDBQT with OpenBabel
obabel ligand.sdf -O ligand.pdbqt --gen3d -p 7.4

# 2. Run docking using AutoDock Vina
vina --config config.txt --log vina_output.log

# 3. Analyze docked poses visually
adt &
# or
vmd docked_complex.pdb
```

---

## 🔋 Recommended Daily Usage (Battery Saving)

* **Start Session**:
  ```bash
  docker compose up -d
  ```
  Open `http://127.0.0.1:3000`.

* **Stop Session**:
  ```bash
  docker compose stop
  ```
  When done, quit Docker Desktop (**Command + Q** on macOS) to free the hypervisor memory and prevent background battery drain.

---

## 📄 License
This Docker recipe is distributed under the MIT License. MGLTools and VMD retain their respective academic and institutional licenses (CCSB Scripps & UIUC).
