#!/bin/bash

# Źródło skryptu
REPO_URL="https://github.com/twoja-organizacja/git-hooks"
SCRIPT_PATH="secret-scanner.sh"

# Pobierz skrypt
echo "Pobieranie najnowszej wersji skanera sekretów..."
curl -s "${REPO_URL}/raw/main/${SCRIPT_PATH}" -o /tmp/secret-scanner.sh

# Zainstaluj hook w bieżącym repozytorium
echo "Instalowanie git hook w bieżącym repozytorium..."
mkdir -p .git/hooks
cp /tmp/secret-scanner.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "Skaner sekretów został pomyślnie zainstalowany!"
Użytkownicy mogliby użyć:

curl -s https://github.com/twoja-organizacja/git-hooks/raw/main/install-hook.sh |
