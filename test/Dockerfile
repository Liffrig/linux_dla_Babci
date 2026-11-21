# Podgląd pulpitu Babci w kontenerze (XFCE w VNC + noVNC w przeglądarce).
# Uruchamiaj przez: ./test/preview.sh
#
# Uwaga: kontener nie ma systemd, więc moduły wymagające usług systemowych
# (autologowanie, zram, automatyczne aktualizacje, zdalna pomoc) są pomijane
# (install.sh --container). Te części testuj w maszynie wirtualnej (README).

ARG BASE_IMAGE=linuxmintd/mint22.3-amd64:latest
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Warsaw

# Warstwa "systemu" – odpowiednik świeżo zainstalowanego Minta XFCE
# (minimalny zestaw, pełny mint-meta-xfce nie instaluje się w obrazie Dockera).
# Obraz Dockera wycina tłumaczenia (.mo) – przywracamy, żeby XFCE był po polsku.
RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes \
    && apt-get update && apt-get install -y --no-install-recommends \
        locales language-pack-pl language-pack-gnome-pl tzdata sudo ca-certificates curl python3 gettext-base \
        dbus dbus-x11 at-spi2-core libglib2.0-bin gvfs xdg-user-dirs xdg-utils \
        x11-xserver-utils \
        xfce4-session xfwm4 xfce4-panel xfdesktop4 xfce4-settings xfconf \
        xfce4-notifyd thunar xfce4-whiskermenu-plugin xfce4-pulseaudio-plugin \
        mint-themes mint-y-icons mint-x-icons mint-cursor-themes \
        fonts-ubuntu fonts-noto-core fonts-noto-color-emoji \
        firefox ristretto mousepad \
        tigervnc-standalone-server tigervnc-tools novnc python3-websockify \
    && locale-gen pl_PL.UTF-8 \
    && update-locale LANG=pl_PL.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=pl_PL.UTF-8 \
    LANGUAGE=pl_PL:pl \
    LC_ALL=pl_PL.UTF-8

# Właściwe skrypty repo – ta warstwa przebudowuje się przy każdej zmianie.
COPY . /opt/babcia
RUN /opt/babcia/install.sh --container --yes --config /opt/babcia/config.env.example

EXPOSE 6080
ENTRYPOINT ["/opt/babcia/test/entrypoint.sh"]
