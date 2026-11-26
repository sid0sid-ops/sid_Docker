# syntax=docker/dockerfile:1.7
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH="/opt/mgltools/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    MAMBA_ROOT_PREFIX="/opt/mamba"

# 1. Strip apt docs/man/foreign locales, force IPv4, and use fast Ubuntu CDN mirror
RUN printf 'path-exclude /usr/share/doc/*\npath-exclude /usr/share/man/*\npath-exclude /usr/share/info/*\npath-exclude /usr/share/groff/*\npath-exclude /usr/share/lintian/*\npath-exclude /usr/share/linda/*\npath-exclude /usr/share/locale/*\npath-include /usr/share/locale/en*\n' > /etc/dpkg/dpkg.cfg.d/01_nodoc \
    && printf 'Acquire::Languages "none";\nAcquire::ForceIPv4 "true";\nAcquire::Retries "3";\n' > /etc/apt/apt.conf.d/99slim \
    && sed -i 's|http://archive.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g; s|http://security.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list

# 2. Install slim XFCE desktop + OpenGL/X11 libs + KasmVNC + basic Linux CLI tools
RUN --mount=type=bind,source=installers/kasmvnc.deb,target=/mnt/kasmvnc.deb \
    apt-get update && apt-get install -y --no-install-recommends \
      xfwm4 \
      xfce4-panel \
      xfce4-session \
      xfdesktop4 \
      xfce4-settings \
      xfce4-terminal \
      thunar \
      tango-icon-theme \
      dbus-x11 \
      x11-xserver-utils \
      python3-xdg \
      libglu1-mesa \
      libgl1-mesa-glx \
      libgl1-mesa-dri \
      libxmu6 \
      libxi6 \
      libxrender1 \
      libxft2 \
      libxss1 \
      libsm6 \
      libice6 \
      libxinerama1 \
      libxcursor1 \
      libxrandr2 \
      libxtst6 \
      fonts-dejavu-core \
      sudo \
      curl \
      ca-certificates \
      nano \
      unzip \
      make \
      /mnt/kasmvnc.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/*

# 3. Install micromamba (single static binary for clean isolated tool testing/removal)
RUN --mount=type=bind,source=installers/micromamba,target=/mnt/micromamba \
    install -m 0755 /mnt/micromamba /usr/local/bin/micromamba \
    && mkdir -p /opt/mamba/envs

# 4. Install MGLTools 1.5.7 (AutoDockTools / ADT) using -d so installer archives are not kept
RUN --mount=type=bind,source=installers/mgltools_x86_64Linux2_1.5.7p1.tar.gz,target=/mnt/mgltools.tar.gz \
    mkdir -p /tmp/mgl-src /opt/mgltools \
    && tar -xzf /mnt/mgltools.tar.gz -C /tmp/mgl-src --strip-components=1 \
    && cd /tmp/mgl-src && bash install.sh -d /opt/mgltools \
    && rm -rf /tmp/mgl-src /opt/mgltools/share/doc \
    && chmod -R a+rX /opt/mgltools

# 5. Install VMD 2.0.0
RUN --mount=type=bind,source=installers/vmd.tar.gz,target=/mnt/vmd.tar.gz \
    mkdir -p /tmp/vmd-src \
    && tar -xzf /mnt/vmd.tar.gz -C /tmp/vmd-src --strip-components=1 \
    && cd /tmp/vmd-src \
    && ./configure LINUXAMD64 \
    && cd src && make install \
    && mkdir -p /usr/share/pixmaps \
    && cp /usr/local/lib/vmd/plugins/noarch/tcl/rmsx2.3/fonts/noto-emoji/png/dna.png /usr/share/pixmaps/vmd.png \
    && rm -rf /tmp/vmd-src /usr/local/lib/vmd/doc

# 6. Create non-root user 'sid' with passwordless sudo and /config persistent home
RUN groupadd -g 1000 sid \
    && useradd -m -d /config -u 1000 -g 1000 -s /bin/bash sid \
    && usermod -aG sudo sid \
    && echo "sid ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sid \
    && chmod 0440 /etc/sudoers.d/sid \
    && echo 'export PS1="\[\033[01;32m\]sid_Docker\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' > /etc/profile.d/sid_prompt.sh \
    && mkdir -p /workspace/files /workspace/projects /workspace/scratch \
    && chown -R sid:sid /config /opt/mamba

# 7. Desktop menu launchers, clean XFCE defaults, KasmVNC config, and entrypoint
COPY root/kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml
COPY root/xfce/xfce4-panel.xml /etc/xdg/xfce4/panel/default.xml
COPY root/xfce/xfwm4.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
COPY root/applications/ /usr/share/applications/
COPY root/autostart/clean-desktop.desktop /etc/xdg/autostart/clean-desktop.desktop
COPY root/scripts/clean-desktop.sh /usr/local/bin/clean-desktop.sh
COPY root/scripts/file_portal.py /usr/local/bin/file_portal.py
COPY root/scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/clean-desktop.sh /usr/local/bin/file_portal.py /usr/local/bin/entrypoint.sh

EXPOSE 3000 3001
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
