#!/usr/bin/env bash
# Start pulpitu Babci w kontenerze: Xtigervnc (:1) + XFCE + noVNC (port 6080).
set -euo pipefail

BABCIA_USER="${BABCIA_USER:-babcia}"
GEOMETRY="${GEOMETRY:-1366x768}"   # typowa rozdzielczość starszego laptopa
uid="$(id -u "$BABCIA_USER")"

export XDG_RUNTIME_DIR="/tmp/runtime-$BABCIA_USER"
install -d -m 700 -o "$BABCIA_USER" "$XDG_RUNTIME_DIR"

runuser -u "$BABCIA_USER" -- Xtigervnc :1 -geometry "$GEOMETRY" -depth 24 \
  -SecurityTypes None -localhost=1 -AlwaysShared -desktop "Babcia" >/tmp/xvnc.log 2>&1 &

for _ in $(seq 50); do [[ -S /tmp/.X11-unix/X1 ]] && break; sleep 0.1; done

runuser -u "$BABCIA_USER" -- env -i \
  HOME="$(getent passwd "$BABCIA_USER" | cut -d: -f6)" USER="$BABCIA_USER" \
  LANG="$LANG" LANGUAGE="$LANGUAGE" LC_ALL="$LC_ALL" TZ="$TZ" \
  PATH=/usr/local/bin:/usr/bin:/bin DISPLAY=:1 XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=XFCE \
  dbus-run-session -- startxfce4 >/tmp/xfce.log 2>&1 &

echo
echo "  Pulpit Babci: http://localhost:6080/vnc.html?autoconnect=1&resize=scale"
echo "  (uid $uid, rozdzielczość $GEOMETRY; logi: docker exec babcia-preview cat /tmp/xfce.log)"
echo "  Ctrl+C kończy podgląd."
echo

exec websockify --web /usr/share/novnc 6080 localhost:5901
