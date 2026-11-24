#!/usr/bin/env bash

# Enable Nvidia GPU support if detected
if which nvidia-smi >/dev/null 2>&1; then
  export LIBGL_KOPPER_DRI2=1
  export MESA_LOADER_DRIVER_OVERRIDE=zink
  export GALLIUM_DRIVER=zink
fi

exec /usr/bin/startxfce4
