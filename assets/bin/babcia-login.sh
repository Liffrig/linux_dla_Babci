#!/usr/bin/env bash
# Linux dla Babci – uruchamiany przy każdym logowaniu (autostart XFCE).
# Robi rzeczy, które wymagają działającej sesji graficznej.
set -u

CONF=/usr/local/share/babcia/login.conf
WALLPAPER=""
WALLPAPER_CYCLE="no"
# shellcheck source=/dev/null
[[ -r "$CONF" ]] && source "$CONF"

# XFCE 4.18+ pyta "Czy ufasz temu programowi?" przy ikonach na pulpicie,
# dopóki plik nie ma sumy kontrolnej w metadanych gvfs.
trust_desktop_icons() {
  local desk f sum
  desk="$(xdg-user-dir DESKTOP)"
  for f in "$desk"/*.desktop; do
    [[ -f "$f" ]] || continue
    chmod +x "$f"
    sum="$(sha256sum "$f" | cut -d' ' -f1)"
    if [[ "$(gio info -a metadata::xfce-exe-checksum "$f" 2>/dev/null | awk '/xfce-exe-checksum/ {print $2}')" != "$sum" ]]; then
      gio set -t string "$f" metadata::xfce-exe-checksum "$sum"
    fi
  done
}

xfset() { xfconf-query -c xfce4-desktop -p "$1" -n -t "$2" -s "$3"; }

# Tapeta ustawiana tylko raz (flaga), żeby nie nadpisywać rotacji ani zmian Babci.
# Ponowne ustawienie: rm ~/.config/babcia/wallpaper-set
set_wallpaper() {
  [[ -n "$WALLPAPER" && -r "$WALLPAPER" ]] || return 0
  local flag="$HOME/.config/babcia/wallpaper-set"
  [[ "$(cat "$flag" 2>/dev/null)" == "$WALLPAPER|$WALLPAPER_CYCLE" ]] && return 0

  local base keys period enable=true
  case "$WALLPAPER_CYCLE" in
    hourly)  period=4 ;;
    daily)   period=5 ;;
    startup) period=3 ;;
    *)       enable=false; period=5 ;;
  esac
  # poczekaj, aż xfdesktop utworzy klucze dla monitorów (np. monitorVGA-1)
  for _ in $(seq 15); do
    keys="$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/workspace0/last-image$' || true)"
    [[ -n "$keys" ]] && break
    sleep 1
  done
  for key in $keys; do
    base="${key%/last-image}"
    xfset "$base/last-image" string "$WALLPAPER"
    xfset "$base/image-style" int 5                 # 5 = powiększone (wypełnia ekran)
    xfset "$base/backdrop-cycle-enable" bool "$enable"
    xfset "$base/backdrop-cycle-period" int "$period"
    xfset "$base/backdrop-cycle-random-order" bool true
  done
  [[ -n "$keys" ]] && mkdir -p "${flag%/*}" && echo "$WALLPAPER|$WALLPAPER_CYCLE" > "$flag"
}

trust_desktop_icons
# xfdesktop odczytuje metadane przy starcie – odśwież pulpit
xfdesktop --reload >/dev/null 2>&1 || true

# Ułóż ikony alfabetycznie (tylko raz – potem Babcia może je przestawiać).
# Ponowne ułożenie: rm ~/.config/babcia/icons-arranged
flag="$HOME/.config/babcia/icons-arranged"
if [[ ! -e "$flag" ]]; then
  sleep 2
  xfdesktop --arrange >/dev/null 2>&1 && mkdir -p "${flag%/*}" && touch "$flag"
fi

set_wallpaper
