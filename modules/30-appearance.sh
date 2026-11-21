#!/usr/bin/env bash
# OPIS: wygląd XFCE – duże czcionki, kursor, pasek, bez blokady ekranu
# shellcheck disable=SC2154  # zmienne z config.env

XFCONF_VARS='${GTK_THEME} ${ICON_THEME} ${CURSOR_THEME} ${CURSOR_SIZE} ${FONT_NAME} ${FONT_SIZE} ${DPI} ${DOUBLE_CLICK_TIME} ${PANEL_SIZE} ${DESKTOP_ICON_SIZE} ${SINGLE_CLICK_BOOL} ${PANEL_BACKGROUND}'

check_theme() {
  [[ -d "/usr/share/themes/$GTK_THEME" ]] || warn "brak motywu $GTK_THEME"
  [[ -d "/usr/share/icons/$ICON_THEME" ]] || warn "brak ikon $ICON_THEME"
  [[ -d "/usr/share/icons/$CURSOR_THEME" ]] || warn "brak kursora $CURSOR_THEME"
}

xfconf_files() {
  local dir tmpl ch
  dir="$(user_home)/.config/xfce4/xfconf/xfce-perchannel-xml"
  export SINGLE_CLICK_BOOL=false
  if is_yes "$SINGLE_CLICK"; then SINGLE_CLICK_BOOL=true; fi
  # w XML wartości muszą być escapowane
  FONT_NAME="$(xml_escape "$FONT_NAME")"
  export PANEL_BACKGROUND
  PANEL_BACKGROUND="$(panel_background "${PANEL_COLOR:-}")"
  export_vars GTK_THEME ICON_THEME CURSOR_THEME CURSOR_SIZE FONT_NAME FONT_SIZE DPI \
              DOUBLE_CLICK_TIME PANEL_SIZE DESKTOP_ICON_SIZE SINGLE_CLICK_BOOL PANEL_BACKGROUND

  for tmpl in "$ASSETS"/xfce/*.xml.tmpl; do
    ch="$(basename "$tmpl" .tmpl)"
    render_template "$tmpl" "$XFCONF_VARS" | write_user_file "$dir/$ch"
  done
  ok "ustawienia XFCE (${dir/#$(user_home)/\~})"
}

# 0–255 -> "0.2902" (bez awk/printf %f – polskie locale dałoby przecinek)
frac() { local v=$(( $1 * 10000 / 255 )); printf '%d.%04d' $((v / 10000)) $((v % 10000)); }

# "#4a2c6b" -> właściwości xfconf z jednolitym kolorem tła paska (puste = z motywu)
panel_background() {
  local hex="${1#\#}" r g b
  [[ -n "$hex" ]] || return 0
  [[ "$hex" =~ ^[0-9a-fA-F]{6}$ ]] || die "PANEL_COLOR: oczekiwano #RRGGBB, jest '$1'"
  r=$((16#${hex:0:2})); g=$((16#${hex:2:2})); b=$((16#${hex:4:2}))
  cat <<EOF
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="$(frac "$r")"/>
        <value type="double" value="$(frac "$g")"/>
        <value type="double" value="$(frac "$b")"/>
        <value type="double" value="1.0"/>
      </property>
EOF
}

cursor_fallback() {
  # kursor także dla aplikacji spoza GTK i dla ekranu logowania
  write_user_file "$(user_home)/.icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$CURSOR_THEME
EOF
  write_user_file "$(user_home)/.Xresources" <<EOF
Xcursor.theme: $CURSOR_THEME
Xcursor.size: $CURSOR_SIZE
Xft.dpi: $DPI
EOF
}

hide_autostart() {
  # wyłącza programy startujące automatycznie (tylko dla Babci)
  local name f
  for name in "$@"; do
    f="$(user_home)/.config/autostart/$name.desktop"
    write_user_file "$f" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Hidden=true
X-GNOME-Autostart-enabled=false
EOF
  done
}

main() {
  check_theme
  xfconf_files
  # starsze wersje tego repo dodawały przycisk Firefoksa na pasek
  rm -rf "$(user_home)/.config/xfce4/panel/launcher-2"
  cursor_fallback
  # wygaszacze/blokady ekranu i okno powitalne Minta
  hide_autostart light-locker xscreensaver xfce4-screensaver mintwelcome
  ok "wygląd"
}
