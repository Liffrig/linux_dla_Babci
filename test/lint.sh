#!/usr/bin/env bash
# Statyczna analiza skryptów (shellcheck w Dockerze – nie trzeba nic instalować).
set -euo pipefail
cd "$(dirname "$0")/.."

mapfile -t files < <(git ls-files --cached --others --exclude-standard '*.sh')
docker run --rm -v "$PWD:/mnt:ro" -w /mnt koalaman/shellcheck:stable -x -S warning "${files[@]}"
echo "shellcheck: OK (${#files[@]} plików)"
