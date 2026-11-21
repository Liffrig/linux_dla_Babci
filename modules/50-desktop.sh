#!/usr/bin/env bash
# OPIS: strona startowa z kafelkami i duże ikony na pulpicie
# shellcheck disable=SC2154  # zmienne z config.env

start_page() {
  export BABCIA_GREETING ACCENT_COLOR
  printf '%s\n' "${TILES[@]}" \
    | python3 -I "$REPO_DIR/lib/gen_startpage.py" "$ASSETS/startpage/index.html.tmpl" \
    | write_root_file "$BABCIA_SHARE/start/index.html"
  ok "strona startowa: $START_PAGE"
}

desktop_icons() {
  local desk pics entry name cmd icon file n=0
  desk="$(user_xdg_dir DESKTOP Pulpit)"
  pics="$(user_xdg_dir PICTURES Obrazy)"
  as_user mkdir -p "$desk" "$pics"

  # usuń poprzednio wygenerowane ikony (idempotencja), zostaw pliki Babci
  for file in "$desk"/*.desktop; do
    [[ -f "$file" ]] && grep -q '^X-Babcia=true' "$file" && rm -f "$file"
  done

  for entry in "${DESKTOP_ICONS[@]}"; do
    IFS='|' read -r name cmd icon <<<"$entry"
    cmd="${cmd//%PICTURES%/\"$pics\"}"
    cmd="${cmd//%START_PAGE%/$START_PAGE}"
    n=$((n + 1))
    file="$desk/$(printf '%02d' "$n")-$(tr -c 'A-Za-z0-9' '_' <<<"$name" | sed 's/_*$//').desktop"
    write_user_file "$file" 755 <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=$cmd
Icon=$icon
Terminal=false
StartupNotify=true
X-Babcia=true
EOF
  done
  ok "ikony na pulpicie: $n (${desk/#$(user_home)/\~})"
}

wallpapers() {
  local f wp="${WALLPAPER:-}"
  install -d -m 755 "$BABCIA_SHARE/wallpapers"
  for f in "$ASSETS"/wallpapers/*.jpg; do
    install -m 644 "$f" "$BABCIA_SHARE/wallpapers/"
  done
  # nazwa pliku z assets/wallpapers/ albo pełna ścieżka
  if [[ -n "$wp" && "$wp" != /* ]]; then wp="$BABCIA_SHARE/wallpapers/$wp"; fi
  if [[ -n "$wp" && ! -r "$wp" ]]; then
    warn "brak tapety $wp – zostaje tapeta Minta"
    wp=""
  fi
  WALLPAPER_PATH="$wp"
  [[ -n "$wp" ]] && ok "tapeta: $wp (zmiana: ${WALLPAPER_CYCLE:-no})"
  return 0
}

login_hook() {
  # Skrypt uruchamiany przy każdym logowaniu Babci (oznacza ikony jako zaufane,
  # ustawia tapetę) – rzeczy, które wymagają działającej sesji.
  install -D -m 755 "$ASSETS/bin/babcia-login.sh" /usr/local/bin/babcia-login
  write_root_file "$BABCIA_SHARE/login.conf" <<EOF
WALLPAPER=$(printf '%q' "$WALLPAPER_PATH")
WALLPAPER_CYCLE=$(printf '%q' "${WALLPAPER_CYCLE:-no}")
EOF
  write_user_file "$(user_home)/.config/autostart/babcia-login.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Linux dla Babci – logowanie
Exec=/usr/local/bin/babcia-login
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF
  ok "skrypt logowania: /usr/local/bin/babcia-login"
}

main() {
  start_page
  desktop_icons
  wallpapers
  login_hook
}
