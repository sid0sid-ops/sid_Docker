#!/usr/bin/env bash
set -euo pipefail

mkdir -p installers

echo "Downloading KasmVNC 1.5.2 (Ubuntu Jammy amd64)..."
curl -4 -fSL -o installers/kasmvnc.deb \
  https://github.com/kasmtech/KasmVNC/releases/download/v1.5.2/kasmvncserver_ubuntu_jammy_1.5.2_amd64.deb

echo "Downloading static micromamba (linux-64)..."
curl -4 -fSL https://micro.mamba.pm/api/micromamba/linux-64/latest \
  | tar -xj -C installers --strip-components=1 bin/micromamba
chmod +x installers/micromamba

echo ""
echo "Done! Next, download the two licensed tool archives manually into installers/:"
echo "  1. installers/mgltools_x86_64Linux2_1.5.7p1.tar.gz  (from https://ccsb.scripps.edu/mgltools/downloads/)"
echo "  2. installers/vmd.tar.gz                           (Linux 64-bit OpenGL tarball from UIUC VMD, renamed to vmd.tar.gz)"
echo ""
echo "Then build & start manually:"
echo "  docker compose up -d --build"
