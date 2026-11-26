#!/usr/bin/env bash
set -euo pipefail

export HOME=/config
export USER=sid
export DISPLAY=:1
export XDG_RUNTIME_DIR=/config/.XDG
export MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX:-/opt/mamba}"

mkdir -p /config/.XDG /config/.config/gtk-3.0 /workspace/files /workspace/scratch /opt/mamba/envs
chmod 700 /config/.XDG

# Seed Thunar sidebar bookmarks on first run for quick access to Mac shared folders
if [ ! -f /config/.config/gtk-3.0/bookmarks ]; then
  cat <<'EOF' > /config/.config/gtk-3.0/bookmarks
file:///workspace/files Files (Upload / Dropzone)
file:///workspace/projects Projects
file:///workspace/scratch Scratch Tests
EOF
fi

# Seed user bashrc with sid_Docker prompt and micromamba hook if missing
if [ ! -f /config/.bashrc ]; then
  cp /etc/skel/.bashrc /config/.bashrc 2>/dev/null || touch /config/.bashrc
fi
if ! grep -q "sid_Docker" /config/.bashrc; then
  cat <<'EOF' >> /config/.bashrc
export PATH="/opt/mgltools/bin:$PATH"
export PS1="\[\033[01;32m\]sid_Docker\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
export MAMBA_ROOT_PREFIX=/opt/mamba
if command -v micromamba >/dev/null 2>&1; then
  eval "$(micromamba shell hook --shell bash)"
fi
EOF
fi

chown -R sid:sid /config /opt/mamba/envs /workspace/files /workspace/scratch 2>/dev/null || true

# Clean stale X locks and prepare X11/ICE socket directories
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
mkdir -p /tmp/.X11-unix /tmp/.ICE-unix
chmod 1777 /tmp/.X11-unix /tmp/.ICE-unix

PIDS=()
cleanup() {
  for pid in "${PIDS[@]:-}"; do
    kill -TERM "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
  exit 0
}
trap cleanup TERM INT

# 1. Start local browser file upload/download portal (http://127.0.0.1:3001)
sudo -E -H -u sid python3 /usr/local/bin/file_portal.py &
PIDS+=($!)

# 2. Start KasmVNC server directly on port 3000 (no auth, HTTP localhost only)
sudo -E -H -u sid /usr/bin/Xkasmvnc :1 \
  -PublicIP 127.0.0.1 \
  -disableBasicAuth \
  -SecurityTypes None \
  -AlwaysShared \
  -httpd /usr/share/kasmvnc/www \
  -http-header Cross-Origin-Embedder-Policy=require-corp \
  -http-header Cross-Origin-Opener-Policy=same-origin \
  -geometry 1280x800 \
  -depth 24 \
  -sslOnly 0 \
  -RectThreads 0 \
  -websocketPort 3000 \
  -interface 0.0.0.0 \
  -Log *:stdout:10 &
PIDS+=($!)

# Wait briefly for X display socket
for _ in $(seq 1 50); do
  if [ -S /tmp/.X11-unix/X1 ]; then
    break
  fi
  sleep 0.2
done

# 3. Start lightweight XFCE desktop session
sudo -E -H -u sid env DISPLAY=:1 PATH="/opt/mgltools/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" dbus-launch --exit-with-session startxfce4 &
PIDS+=($!)

wait -n "${PIDS[@]}"
cleanup
