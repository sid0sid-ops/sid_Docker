FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

# 1. Install XFCE Desktop + OpenGL/Mesa + AutoDock + Vina + OpenBabel + Make
RUN rm -f /etc/apt/sources.list.d/*node* \
    && apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-terminal \
    thunar \
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
    x11-xserver-utils \
    autodock \
    autodock-vina \
    openbabel \
    make \
    python3-xdg \
    && rm -rf /var/lib/apt/lists/*

# 2. Configure sid_Docker prompt across login, interactive, and new user shells
RUN echo 'export PS1="\[\033[01;32m\]sid_Docker\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' > /etc/profile.d/ps1.sh \
    && echo 'export PS1="\[\033[01;32m\]sid_Docker\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /etc/bash.bashrc \
    && echo 'export PS1="\[\033[01;32m\]sid_Docker\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /etc/skel/.bashrc

# 3. Switch default desktop to XFCE
COPY root/defaults/startwm.sh /defaults/startwm.sh
RUN chmod +x /defaults/startwm.sh

# 4. Install MGLTools 1.5.7 (AutoDockTools & PMV)
COPY mgltools_x86_64Linux2_1.5.7p1.tar.gz /tmp/mgltools.tar.gz
RUN mkdir -p /opt/mgltools \
    && tar -xzf /tmp/mgltools.tar.gz -C /opt/mgltools --strip-components=1 \
    && rm /tmp/mgltools.tar.gz \
    && cd /opt/mgltools && bash install.sh \
    && chmod -R a+rX /opt/mgltools

# 5. Install VMD 2.0.0
COPY vmd.tar.gz /tmp/vmd.tar.gz
RUN mkdir -p /tmp/vmd-src \
    && tar -xzf /tmp/vmd.tar.gz -C /tmp/vmd-src --strip-components=1 \
    && rm /tmp/vmd.tar.gz \
    && cd /tmp/vmd-src \
    && ./configure LINUXAMD64 \
    && cd src \
    && make install \
    && rm -rf /tmp/vmd-src \
    && cp /usr/local/lib/vmd/plugins/noarch/tcl/rmsx2.3/fonts/noto-emoji/png/dna.png /usr/share/pixmaps/vmd.png

ENV PATH="/opt/mgltools/bin:${PATH}"

# 6. Persistent Desktop configuration, Autostart scripts, and Applications Menu
COPY root/applications/ /usr/share/applications/
COPY root/autostart/clean-desktop.desktop /etc/xdg/autostart/clean-desktop.desktop
COPY root/scripts/clean-desktop.sh /usr/local/bin/clean-desktop.sh
RUN chmod +x /usr/local/bin/clean-desktop.sh
