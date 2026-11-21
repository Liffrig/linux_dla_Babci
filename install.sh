#!/usr/bin/env bash
# =====================================================================
#  Linux dla Babci – konfiguracja Linux Mint XFCE dla starszej osoby.
#
#  Użycie:  sudo ./install.sh [opcje]
#    --config PLIK   plik konfiguracyjny (domyślnie ./config.env)
#    --only 30,40    uruchom tylko wybrane moduły (numery)
#    --skip 70       pomiń wybrane moduły
#    --list          pokaż moduły i zakończ
#    --yes, -y       bez pytań (np. hasło musi być w config.env)
#    --force         nie przerywaj, gdy Babcia jest zalogowana
#    --container     tryb testowy w Dockerze (bez systemd)
#
#  Skrypt jest idempotentny – można go uruchamiać wielokrotnie.
# =====================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$REPO_DIR/assets"
# shellcheck source=lib/common.sh
source "$REPO_DIR/lib/common.sh"

CONFIG="$REPO_DIR/config.env"
ONLY="" SKIP="" ASSUME_YES=0 FORCE=0 LIST=0
export BABCIA_CONTAINER=0

usage() { sed -n '3,14s/^#  \{0,1\}//p' "$0"; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)    CONFIG="$(realpath "$2")"; shift ;;
    --only)      ONLY="$2"; shift ;;
    --skip)      SKIP="$2"; shift ;;
    --list)      LIST=1 ;;
    -y|--yes)    ASSUME_YES=1 ;;
    --force)     FORCE=1 ;;
    --container) BABCIA_CONTAINER=1; ASSUME_YES=1 ;;
    -h|--help)   usage; exit 0 ;;
    *) usage; die "nieznana opcja: $1" ;;
  esac
  shift
done

mapfile -t MODULES < <(find "$REPO_DIR/modules" -maxdepth 1 -name '[0-9][0-9]-*.sh' | sort)

if [[ $LIST == 1 ]]; then
  for m in "${MODULES[@]}"; do
    printf '%s  %s\n' "$(basename "$m" .sh)" "$(sed -n 's/^# OPIS: //p' "$m")"
  done
  exit 0
fi

[[ $EUID -eq 0 ]] || die "uruchom przez sudo: sudo $0 $*"
[[ -f "$CONFIG" ]] || die "brak $CONFIG – skopiuj: cp config.env.example config.env"

# shellcheck source=config.env.example
source "$CONFIG"
: "${BABCIA_USER:?brak BABCIA_USER w konfiguracji}"
[[ "$BABCIA_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "nieprawidłowy login: $BABCIA_USER"

if ! is_container; then
  grep -qi 'linux mint' /etc/os-release 2>/dev/null || warn "to nie wygląda na Linux Minta – kontynuuję na własne ryzyko"
  LOGFILE=/var/log/babcia-install.log
  exec > >(tee -a "$LOGFILE") 2>&1
  log "Log: $LOGFILE ($(date '+%F %T'))"

  # xfconfd trzyma ustawienia w pamięci i nadpisałby nasze pliki
  if [[ $FORCE == 0 ]] && pgrep -u "$BABCIA_USER" -x xfce4-session >/dev/null 2>&1; then
    die "użytkownik $BABCIA_USER jest zalogowany – wyloguj go i uruchom skrypt z innego konta (lub z TTY: Ctrl+Alt+F2). Ewentualnie --force."
  fi
fi

selected() {
  local n="$1" x
  if [[ -n "$ONLY" ]]; then
    for x in ${ONLY//,/ }; do [[ "$x" == "$n" ]] && return 0; done
    return 1
  fi
  for x in ${SKIP//,/ }; do [[ "$x" == "$n" ]] && return 1; done
  return 0
}

export REPO_DIR ASSETS ASSUME_YES

for m in "${MODULES[@]}"; do
  name="$(basename "$m" .sh)"; num="${name%%-*}"
  selected "$num" || continue
  log "[$name] $(sed -n 's/^# OPIS: //p' "$m")"
  # każdy moduł w podpowłoce: własne funkcje, błąd przerywa całość
  # shellcheck source=/dev/null
  ( set -euo pipefail; source "$m"; main )
done

log "Gotowe! 🎉"
is_container || echo "    Uruchom ponownie komputer, żeby wszystko zadziałało."
