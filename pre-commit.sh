#!/bin/bash

check_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  local need_escape="$4"
  
  local matches
  if [ "$need_escape" = "true" ]; then
    matches=$(grep -n -E -- "$pattern" "$file" 2>/dev/null || echo "")
  else
    matches=$(grep -n -E "$pattern" "$file" 2>/dev/null || echo "")
  fi
  
  if [ -n "$matches" ]; then
    while IFS= read -r match; do
      line_num=$(echo "$match" | cut -d: -f1)
      content=$(echo "$match" | cut -d: -f2-)
      echo -e "\e[31mPotential $description found in file $file at line $line_num:\e[0m"
      echo -e "\e[33m  $content\e[0m"
    done <<< "$matches"
    return 1
  fi
  return 0
}

find_secrets() {
  local file="$1"
  local secrets_found=false
  
  check_pattern "$file" "api_key[[:space:]]*=[[:space:]]*(\'|\")?\w+(\'|\")?" "API key" false || secrets_found=true
  check_pattern "$file" "password[[:space:]]*=[[:space:]]*(\'|\")?\w+(\'|\")?" "password" false || secrets_found=true
  check_pattern "$file" "token[[:space:]]*=[[:space:]]*(\'|\")?\w+(\'|\")?" "token" false || secrets_found=true
  check_pattern "$file" "secret[[:space:]]*=[[:space:]]*(\'|\")?\w+(\'|\")?" "secret" false || secrets_found=true
  check_pattern "$file" "client_id[[:space:]]*=[[:space:]]*(\'|\")?\w+(\'|\")?" "client ID" false || secrets_found=true
  check_pattern "$file" "client_secret[[:space:]]*=[[:space:]]*(\'|\")?\w+(\'|\")?" "client secret" false || secrets_found=true
  check_pattern "$file" "AKIA[0-9A-Z]{16}" "AWS key" false || secrets_found=true
  check_pattern "$file" "arn:aws:iam::[0-9]{12}:user" "AWS ARN" false || secrets_found=true
  check_pattern "$file" "-----BEGIN [A-Z ]+ PRIVATE KEY-----" "private key" true || secrets_found=true
  check_pattern "$file" "ssh-rsa AAAA[0-9A-Za-z+/]+" "SSH key" false || secrets_found=true
  check_pattern "$file" "[a-zA-Z0-9+/]{42}=" "Base64 encoded secret" false || secrets_found=true
  check_pattern "$file" "Authorization: Basic [a-zA-Z0-9+/=]+" "Basic Auth" false || secrets_found=true
  check_pattern "$file" "Authorization: Bearer [a-zA-Z0-9._-]+" "Bearer token" false || secrets_found=true
  check_pattern "$file" "access_token=[a-zA-Z0-9._-]+" "Access token" false || secrets_found=true
  check_pattern "$file" "[a-zA-Z0-9]{40}" "Potential hash or token" false || secrets_found=true
  
  if [ "$secrets_found" = true ]; then
    return 1
  fi
  return 0
}


files=$(git diff --cached --name-only)
secrets_found=false

for file in $files; do
if [ -f "$file" ]; then
  if command -v file >/dev/null 2>&1; then
    if file --mime "$file" | grep -q "text/"; then
      if ! find_secrets "$file"; then
        secrets_found=true
      fi
    fi
  else
    if ! find_secrets "$file"; then
      secrets_found=true
    fi
  fi
fi
done

if [ "$secrets_found" = true ]; then
echo -e "\n\e[31mWarning: Potential secrets were found in the files to be committed!\e[0m"
echo -e "\e[31mPlease remove them before committing or use --no-verify to force the commit.\e[0m"
exit 1
fi

exit 0
