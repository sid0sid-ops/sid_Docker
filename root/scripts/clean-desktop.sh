#!/bin/bash
# Brief delay so xfce4-session, xfconfd, and xfdesktop register display monitors first
sleep 2

# 1. Disable desktop icon clutter (without deleting any files user saves to ~/Desktop)
xfconf-query -c xfce4-desktop -p /desktop-icons/style -n -t int -s 0 2>/dev/null || true

# 2. Pure black background (reduces CPU encoding and VNC latency)
for mon in monitorVNC-0 monitor0; do
  xfconf-query -c xfce4-desktop -p "/backdrop/screen0/${mon}/workspace0/image-style" -n -t int -s 0 2>/dev/null || true
  xfconf-query -c xfce4-desktop -p "/backdrop/screen0/${mon}/workspace0/color-style" -n -t int -s 0 2>/dev/null || true
  xfconf-query -c xfce4-desktop -p "/backdrop/screen0/${mon}/workspace0/rgba1" -n -a -t double -s 0.0 -t double -s 0.0 -t double -s 0.0 -t double -s 1.0 2>/dev/null || true
done

# 3. Window manager maximize & click fixes (disable Alt+Click window grab so macOS Option never blocks clicks)
xfconf-query -c xfwm4 -p /general/borderless_maximize -n -t bool -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/titleless_maximize -n -t bool -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/easy_click -n -t string -s "none" 2>/dev/null || true

# 4. Clear virtual duplicate Alt_L keycode 204 that gets stuck under KasmVNC on macOS
xmodmap -e "keycode 204 =" 2>/dev/null || true

# 5. Ensure user PS1 prompt is set in ~/.bashrc
if [ -f "$HOME/.bashrc" ] && ! grep -q "sid_Docker" "$HOME/.bashrc"; then
  echo 'export PS1="\[\033[01;32m\]sid_Docker\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> "$HOME/.bashrc"
fi
