#!/usr/bin/env bash
# OPIS: konto Babci (bez uprawnień administratora) i automatyczne logowanie
# shellcheck disable=SC2154  # zmienne z config.env

create_user() {
  if id "$BABCIA_USER" >/dev/null 2>&1; then
    ok "konto $BABCIA_USER już istnieje"
  else
    log "Tworzę konto $BABCIA_USER"
    useradd -m -s /bin/bash -c "$BABCIA_FULLNAME" "$BABCIA_USER"
    if [[ -n "${BABCIA_PASSWORD:-}" ]]; then
      echo "$BABCIA_USER:$BABCIA_PASSWORD" | chpasswd
    elif is_container; then
      echo "$BABCIA_USER:$BABCIA_USER" | chpasswd
    elif [[ $ASSUME_YES == 1 ]]; then
      die "podaj BABCIA_PASSWORD w config.env (tryb --yes)"
    else
      echo "Ustaw hasło dla $BABCIA_USER (przyda się przy wylogowaniu):"
      passwd "$BABCIA_USER"
    fi
  fi

  # zwykłe grupy "biurkowe" (dźwięk, kamera, pendrive'y, drukarki)
  local g
  for g in audio video plugdev lpadmin netdev; do
    getent group "$g" >/dev/null && usermod -aG "$g" "$BABCIA_USER"
  done

  if id -nG "$BABCIA_USER" | tr ' ' '\n' | grep -qxE 'sudo|admin|wheel'; then
    warn "$BABCIA_USER ma uprawnienia administratora (grupa sudo)."
    warn "Zalecane: osobne konto admina dla Ciebie, a potem: sudo deluser $BABCIA_USER sudo"
  fi
}

user_dirs() {
  # polskie nazwy katalogów (Pulpit, Obrazy, Pobrane...)
  as_user xdg-user-dirs-update --force >/dev/null 2>&1 || as_user xdg-user-dirs-update || true
  # Mint: bez okna powitalnego przy pierwszym logowaniu
  write_user_file "$(user_home)/.linuxmint/mintwelcome/norun.flag" < /dev/null
}

autologin() {
  needs_systemd || return 0
  local conf=/etc/lightdm/lightdm.conf.d/70-babcia-autologin.conf
  if is_yes "$AUTOLOGIN"; then
    getent group autologin >/dev/null || groupadd -r autologin
    usermod -aG autologin "$BABCIA_USER"
    write_root_file "$conf" <<EOF
# Linux dla Babci – automatyczne logowanie
[Seat:*]
autologin-user=$BABCIA_USER
autologin-user-timeout=0
autologin-session=xfce
EOF
    ok "autologowanie: $BABCIA_USER"
  else
    rm -f "$conf"
    skip "autologowanie wyłączone w konfiguracji"
  fi
}

main() {
  create_user
  user_dirs
  autologin
}
