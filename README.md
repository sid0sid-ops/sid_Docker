# sid_Docker (Bio-Linux Workstation) 🧬

A slim, modular, manual-start (`restart: "no"`) **Ubuntu 22.04 (`linux/amd64`) Linux GUI workstation** built for **Apple Silicon Macs (M1/M2/M3/M4 via Rosetta)** and x86_64 Linux/Windows hosts.

Designed specifically as a lightweight Linux environment (`~1.59 GB` on disk / `371 MB` compressed content) for GUI and x86_64-only bioinformatics applications (**VMD 2.0.0** and **AutoDockTools 1.5.7**), plus clean isolated testing and removal of any other Linux bioinformatics tools—while fast native CLI tools like **AutoDock Vina** can continue running directly on your Mac.

---

## ⚡ Key Highlights

* **Ultra-Slim Image (`~1.59 GB` vs `4.81 GB`)**: Built directly from `ubuntu:22.04` + standalone **KasmVNC 1.5.2** + minimal XFCE (no Docker-in-Docker, no Node.js, no extra CLI bloat). Bind-mounted installers and MGLTools `-d` installs keep wasted layers out of the final image.
* **MacBook Air Fanless & Manual Control (`restart: "no"`)**: Zero auto-start on boot, zero background auto-updates. Pure black XFCE backdrop (`#000000`) and disabled compositing keep VNC CPU usage minimal.
* **Single-Port Built-in File Upload/Download Channel (`/files/`)**: Drag-and-drop `.pdb`, `.pdbqt`, `.gro`, `.trr`, `.sdf` files from `http://127.0.0.1:3000/files/` (or via the **Upload / Files** button in the sidebar) straight into `/workspace/files`, or use the zero-copy host `./files` folder.
* **Install, Test & Delete Any Linux Tool Cleanly**:
  * Use **`micromamba`** (pre-installed, persistent under `./envs/`) for 1-command isolated installs and zero-trace deletions.
  * Or use passwordless **`sudo apt`** / manual installs inside the container, and reset the OS cleanly back to **Ubuntu + VMD + ADT** anytime via `docker compose down && docker compose up -d`.
* **Localhost-Only Security**: Single port `3000` binds strictly to `127.0.0.1`.

---

## 📦 Installed Tools & Ports

| Component / Port | Version / URL | Purpose | Launch |
| :--- | :--- | :--- | :--- |
| **AutoDockTools (ADT)** | `1.5.7` (MGLTools) | Docking preparation & analysis GUI | Applications Menu → `AutoDockTools (ADT)` or `adt` |
| **VMD** | `2.0.0` (LINUXAMD64) | Molecular visualization & trajectory analysis | Applications Menu → `VMD` or `vmd` |
| **micromamba** | `2.10.0` | Isolated Conda/Bioconda env manager | Terminal → `micromamba` |
| **Linux Desktop** | `http://127.0.0.1:3000` | Lightweight XFCE desktop in browser | Open in browser (no login required) |
| **File Upload/Download Channel** | `http://127.0.0.1:3000/files/` | Upload `.pdb`/data files or download results | Sidebar **Upload / Files** button or URL |

> **Why `platform: linux/amd64` + `ubuntu:22.04`?**
> Legacy prebuilt Linux bioinformatics binaries (MGLTools 1.5.7 and VMD 2.0.0) target `x86_64` `glibc`. Ubuntu 22.04 (`~32 MB` compressed) is smaller than Arch Linux (`~400+ MB`), provides standard `glibc` compatibility (unlike Alpine `musl`), and runs fast under Rosetta on Apple Silicon.

---

## 📋 Prerequisites

* **Docker Desktop** installed on macOS, Linux, or Windows.
  * *Apple Silicon (M1/M2/M3/M4)*: In **Docker Desktop → Settings → General**, enable **"Use Rosetta for x86_64/amd64 emulation on Apple Silicon"**.
* **Docker Compose V2** (`docker compose`).

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/sid0sid-ops/sid_Docker.git
cd sid_Docker
```

### 2. Fetch Dependencies & Add Licensed Tool Archives
Run the helper script to download KasmVNC (`2.5 MB`) and static `micromamba` into `installers/`:
```bash
./get-deps.sh
```

Then download the two official Linux x86_64 archives and place them inside `installers/`:
1. **MGLTools 1.5.7 (Linux 64-bit)**: Download `mgltools_x86_64Linux2_1.5.7p1.tar.gz` from the [Scripps MGLTools Downloads Page](https://ccsb.scripps.edu/mgltools/downloads/).
2. **VMD 2.0.0 (Linux 64-bit OpenGL)**: Download from the [UIUC VMD Download Page](https://www.ks.uiuc.edu/Development/Download/download.cgi?PackageName=VMD) and rename it to `installers/vmd.tar.gz`.

### 3. (Optional) Mount an Existing Coursework / Projects Folder
Create a local `.env` file (gitignored) if you want an existing host directory mounted at `/workspace/projects`:
```bash
echo "PROJECTS_DIR=/path/to/your/projects" > .env
```

### 4. Build & Start Manually
```bash
docker compose up -d --build
```

Open:
* **Linux Desktop**: `http://127.0.0.1:3000`
* **File Upload/Download Portal**: `http://127.0.0.1:3000/files/` (or click **Upload / Files** in the desktop sidebar)

---

## 📂 File Sharing & Workspace Layout

| Host Path | Container Path | Purpose |
| :--- | :--- | :--- |
| `./files` | `/workspace/files` | Dropzone & browser upload/download target |
| `${PROJECTS_DIR:-./projects}` | `/workspace/projects` | Your host projects/coursework directory |
| `./workspace` | `/workspace/scratch` | Scratch space for temporary experiments |
| `./config` | `/config` | Persistent Linux `$HOME` & XFCE settings |
| `./envs` | `/opt/mamba/envs` | Persistent `micromamba` environments |

---

## 🧪 Installing, Testing & Deleting Other Linux Tools

### Method 1: Isolated `micromamba` Environments (Recommended)
Install any Bioconda / Conda-forge tool (e.g., PyMOL, GROMACS, MDAnalysis, AmberTools) without touching Ubuntu system packages or MGLTools:

```bash
# Install into an isolated environment
micromamba create -n test_pymol -c conda-forge pymol-open-source
micromamba activate test_pymol
pymol

# Delete completely with zero trace
micromamba deactivate
micromamba env remove -n test_pymol
micromamba clean --all -y
```

### Method 2: `sudo apt` / Manual Linux Testing + Instant OS Reset
Test `.deb` packages or Ubuntu tools freely using passwordless `sudo`:

```bash
sudo apt update && sudo apt install -y <package>
```

To wipe all ad-hoc `apt` or `/usr/local` test installs and restore a clean **Ubuntu + VMD + ADT** system while preserving `/workspace` and `/config`:

```bash
docker compose down && docker compose up -d
```

---

## 🔋 Daily Start / Stop (Manual Only)

```bash
# Start session
docker compose up -d

# Stop session when done (keeps container state; nothing auto-starts)
docker compose stop
```

On macOS, quit Docker Desktop (**Command + Q**) after stopping to free VM RAM and prevent background battery drain.

---

## 📄 License

Distributed under the MIT License. MGLTools/AutoDockTools, VMD, KasmVNC, and Micromamba retain their respective academic and open-source licenses.
