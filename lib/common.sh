#!/usr/bin/env bash
# Wspólne funkcje pomocnicze dla install.sh i modułów.
# shellcheck disable=SC2034  # zmienne używane w modułach

BABCIA_SHARE="/usr/local/share/babcia"
START_PAGE="file://${BABCIA_SHARE}/start/index.html"

# --- logowanie ---------------------------------------------------------
if [[ -t 1 ]]; then
  _C_INFO=$'\e[1;34m' _C_OK=$'\e[1;32m' _C_WARN=$'\e[1;33m' _C_ERR=$'\e[1;31m' _C_OFF=$'\e[0m'
else
  _C_INFO="" _C_OK="" _C_WARN="" _C_ERR="" _C_OFF=""
fi

log()  { printf '%s==>%s %s\n' "$_C_INFO" "$_C_OFF" "$*"; }
ok()   { printf '%s  ✓%s %s\n' "$_C_OK" "$_C_OFF" "$*"; }
warn() { printf '%s  !%s %s\n' "$_C_WARN" "$_C_OFF" "$*" >&2; }
die()  { printf '%sBŁĄD:%s %s\n' "$_C_ERR" "$_C_OFF" "$*" >&2; exit 1; }
skip() { printf '  - pomijam: %s\n' "$*"; }

# --- środowisko --------------------------------------------------------
is_container() { [[ "${BABCIA_CONTAINER:-0}" == 1 ]]; }
is_yes() { [[ "${1,,}" =~ ^(y|yes|tak|t|1|true)$ ]]; }

# Pomija resztę modułu w kontenerze (wywołuj: needs_systemd || return 0)
needs_systemd() {
  if is_container; then
    skip "wymaga systemd/prawdziwego systemu (tryb --container)"
    return 1
  fi
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# --- użytkownik Babci --------------------------------------------------
user_home()  { getent passwd "$BABCIA_USER" | cut -d: -f6; }
user_group() { id -gn "$BABCIA_USER"; }

# Uruchamia polecenie jako Babcia (z polskimi ustawieniami)
as_user() {
  runuser -u "$BABCIA_USER" -- env HOME="$(user_home)" LANG="${LANG:-pl_PL.UTF-8}" "$@"
}

# Katalog XDG Babci (DESKTOP, PICTURES, ...) – po polsku np. ~/Pulpit
user_xdg_dir() {
  local d
  d="$(as_user xdg-user-dir "$1" 2>/dev/null || true)"
  [[ -n "$d" && "$d" != "$(user_home)" ]] || d="$(user_home)/$2"
  printf '%s' "$d"
}

# --- pliki -------------------------------------------------------------
# Zapisuje stdin do pliku należącego do Babci (tworzy katalogi).
write_user_file() {
  local dest="$1" mode="${2:-644}" home grp
  home="$(user_home)"; grp="$(user_group)"
  # utwórz brakujące katalogi jako Babcia, żeby miały właściwego właściciela
  as_user mkdir -p "$(dirname "$dest")"
  install -o "$BABCIA_USER" -g "$grp" -m "$mode" /dev/stdin "$dest"
}

# Zapisuje stdin do pliku systemowego (root).
write_root_file() {
  local dest="$1" mode="${2:-644}"
  install -D -o root -g root -m "$mode" /dev/stdin "$dest"
}

# Podstawia ${ZMIENNE} w szablonie. Podstawiane są tylko zmienne wymienione
# w drugim argumencie (reszta "$" zostaje nietknięta).
render_template() {
  local tmpl="$1" vars="$2"
  [[ -f "$tmpl" ]] || die "brak szablonu $tmpl"
  # shellcheck disable=SC2016
  envsubst "$vars" < "$tmpl"
}

# Eksportuje zmienne dla envsubst
export_vars() { local v; for v in "$@"; do export "${v?}"; done; }

# Escapowanie tekstu do atrybutów XML
xml_escape() {
  local s="$1"
  s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"; s="${s//\"/&quot;}"
  printf '%s' "$s"
}

# --- apt ---------------------------------------------------------------
pkg_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"; }
pkg_available() { apt-cache show "$1" >/dev/null 2>&1; }

_APT_UPDATED=0
apt_update_once() {
  if [[ $_APT_UPDATED == 0 ]]; then
    log "Odświeżam listę pakietów"
    apt-get update -qq
    _APT_UPDATED=1
  fi
}

# Instaluje tylko brakujące i dostępne pakiety.
apt_install() {
  local p missing=()
  for p in "$@"; do pkg_installed "$p" || missing+=("$p"); done
  [[ ${#missing[@]} -eq 0 ]] && return 0
  apt_update_once
  local avail=()
  for p in "${missing[@]}"; do
    if pkg_available "$p"; then avail+=("$p"); else warn "pakiet niedostępny: $p"; fi
  done
  [[ ${#avail[@]} -eq 0 ]] && return 0
  log "Instaluję: ${avail[*]}"
  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${avail[@]}"
}
