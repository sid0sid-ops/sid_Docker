#!/bin/bash
# Brief delay so xfce4-session, xfconfd, and xfdesktop register monitorVNC-0 first
sleep 2

# 1. Desktop icons off and clear any Desktop items
rm -rf "$HOME/Desktop"/*
xfconf-query -c xfce4-desktop -p /desktop-icons/style -n -t int -s 0 2>/dev/null || true

# 2. Pure black background (reduces CPU encoding and VNC latency)
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVNC-0/workspace0/image-style -n -t int -s 0 2>/dev/null || true
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVNC-0/workspace0/color-style -n -t int -s 0 2>/dev/null || true
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitorVNC-0/workspace0/rgba1 -n -a -t double -s 0.0 -t double -s 0.0 -t double -s 0.0 -t double -s 1.0 2>/dev/null || true

# 3. Window manager maximize / borderless fixes
xfconf-query -c xfwm4 -p /general/borderless_maximize -n -t bool -s false 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/titleless_maximize -n -t bool -s false 2>/dev/null || true

# 4. Single bottom panel configuration (height 32, locked, bottom position)
xfconf-query -c xfce4-panel -p /panels/panel-1/position -n -t string -s 'p=10;x=0;y=0' 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/position-locked -n -t bool -s true 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-1/size -n -t int -s 32 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels -n -a -t int -s 1 2>/dev/null || true
xfconf-query -c xfce4-panel -p /panels/panel-2 -rR 2>/dev/null || true

# 5. Expanding panel separator (separates menu/taskbar on left from systray/clock on right)
xfconf-query -c xfce4-panel -p /plugins/plugin-5/expand -n -t bool -s true 2>/dev/null || true
xfconf-query -c xfce4-panel -p /plugins/plugin-5/style -n -t int -s 0 2>/dev/null || true

# 6. Ensure user PS1 prompt is set in ~/.bashrc
if [ -f "$HOME/.bashrc" ] && ! grep -q "sid_Docker" "$HOME/.bashrc"; then
  echo 'export PS1="\[\033[01;32m\]sid_Docker\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> "$HOME/.bashrc"
fi
