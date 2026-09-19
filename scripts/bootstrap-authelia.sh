#!/usr/bin/env bash
# Run from the repository root through the bootstrap-authelia flake app.
set +x
set +v
set +a
set -euo pipefail
umask 077
ulimit -c 0
exec 1>/dev/null

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

[[ $# == 0 ]] || die 'Usage: nix run path:.#bootstrap-authelia (from the repository root)'
secrets=secrets/secrets.yaml
[[ -f .sops.yaml && -f "$secrets" && ! -L "$secrets" ]] ||
  die 'Run from the repository root; .sops.yaml and a regular secrets/secrets.yaml are required.'
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-/persist/var/lib/sops-nix/key.txt}"
[[ -r "$SOPS_AGE_KEY_FILE" ]] || die 'The SOPS age key file is not readable.'
exec 3<>/dev/tty
[[ -t 3 ]] || die 'An interactive terminal is required.'

lock=secrets/.bootstrap-authelia.lock
mkdir -- "$lock" 2>/dev/null || die 'Bootstrap lock exists; check for another running bootstrap before removing it.'
encrypted_tmp=
cleanup() {
  [[ -z "$encrypted_tmp" ]] || rm -f -- "$encrypted_tmp"
  rmdir -- "$lock"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

original_checksum=$(sha256sum < "$secrets")
if ! {
  sops --decrypt --input-type yaml --output-type json "$secrets" |
    jq -e 'type == "object" and (has("immich-settings") | not)
      and (keys | all(startswith("authelia-") | not))' >/dev/null
} 2>/dev/null; then
  die 'Cannot decrypt a secrets object without existing authelia-* or immich-settings keys; refusing to continue.'
fi

printf '%s\n' 'Export the complete existing Immich system configuration to preserve its settings.' \
  'The export may contain plaintext secrets. Protect it and remove it securely when no longer needed; this command does not manage the source export.' \
  'Enter NEW only for a fresh Immich installation with no existing settings to preserve.' >&3
printf 'Immich configuration export path, or NEW: ' >&3
IFS= read -r -u 3 immich_export
printf '\n' >&3
if [[ "$immich_export" == NEW ]]; then
  immich_settings='{}'
else
  [[ -f "$immich_export" && -r "$immich_export" ]] || die 'The Immich configuration export must be a readable regular file.'
  if ! immich_settings=$(jq -cse '
    if length == 1 and (.[0] | type == "object")
    then .[0]
    else error("Expected exactly one JSON object")
    end
  ' 2>/dev/null < "$immich_export"); then
    die 'The Immich configuration export must contain exactly one valid JSON object.'
  fi
fi
unset immich_export

printf 'Initial admin username (input hidden): ' >&3
IFS= read -r -s -u 3 username
printf '\nInitial admin email (input hidden): ' >&3
IFS= read -r -s -u 3 email
printf '\n' >&3
[[ "$username" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]] || die 'Invalid username: use letters, digits, underscores, dots or hyphens.'
[[ "$email" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]] || die 'Invalid email address.'
printf 'Password (input hidden): ' >&3
IFS= read -r -s -u 3 password
printf '\nConfirm password (input hidden): ' >&3
IFS= read -r -s -u 3 confirmation
printf '\n' >&3
[[ -n "$password" && "$password" == "$confirmation" ]] || die 'Passwords must be nonempty and match.'

# Authelia requires a TTY on stdout for its password prompt, so it cannot be
# captured safely. Feed the password to Argon2 via a pipe, never argv or a file.
if ! password_hash=$(printf '%s' "$password" | python3 -I -c '
import sys
from argon2 import PasswordHasher
from argon2.low_level import Type
print(PasswordHasher(time_cost=3, memory_cost=65536, parallelism=4,
                     hash_len=32, salt_len=16, type=Type.ID)
      .hash(sys.stdin.buffer.read()))
' 2>/dev/null); then
  die 'Password hashing failed.'
fi
unset password confirmation
[[ "$password_hash" == \$argon2id\$* ]] || die 'Unexpected password hash format.'

printf 'Generating keys and encrypting secrets; nothing sensitive will be printed.\n' >&2
session_secret=$(openssl rand -hex 32)
storage_key=$(openssl rand -hex 32)
oidc_hmac_secret=$(openssl rand -hex 64)
jwks=$(openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 2>/dev/null)

# Authelia generates and hashes each client secret internally; capture both
# values instead of passing a generated secret back in a --password argument.
immich=$(authelia crypto hash generate pbkdf2 --variant sha512 \
  --random --random.charset numeric-hex --random.length 64 2>/dev/null) || die 'Immich client generation failed.'
paperless=$(authelia crypto hash generate pbkdf2 --variant sha512 \
  --random --random.charset numeric-hex --random.length 64 2>/dev/null) || die 'Paperless client generation failed.'

# NUL-separated fields are transported only through pipes. In particular, do
# not use jq --arg for secrets: those values would be visible in process argv.
if ! additions=$(printf '%s\0' "$username" "$email" "$password_hash" \
  "$session_secret" "$storage_key" "$oidc_hmac_secret" "$jwks" "$immich" "$paperless" "$immich_settings" |
  jq -Rse '
    def client:
      capture("^Random Password: (?<secret>[0-9a-fA-F]{64})\nDigest: (?<digest>\\$pbkdf2-sha512\\$[^\r\n]+)$");
    split("\u0000")[:-1] as $v |
    ($v[7] | client) as $immich |
    ($v[8] | client) as $paperless |
    {
      "authelia-users": ({users: {($v[0]): {
        disabled: false, displayname: $v[0], password: $v[2],
        email: $v[1], groups: ["admins"]
      }}} | tojson),
      "authelia-session-secret": $v[3],
      "authelia-storage-encryption-key": $v[4],
      "authelia-oidc-hmac-secret": $v[5],
      "authelia-jwks": ($v[6] + "\n"),
      "authelia-immich-client-secret": $immich.secret,
      "authelia-paperless-client-secret": $paperless.secret,
      "authelia-immich-client-digest": $immich.digest,
      "authelia-paperless-client-digest": $paperless.digest,
      "immich-settings": $v[9]
    }
  ' 2>/dev/null); then
  die 'Could not assemble secrets; unexpected cryptographic command output.'
fi
unset username email password_hash session_secret storage_key oidc_hmac_secret jwks immich paperless immich_settings

encrypted_tmp=$(mktemp secrets/.bootstrap-authelia.XXXXXXXX.yaml)
# Only SOPS ciphertext reaches disk. Suppress tool diagnostics which could
# quote plaintext input on errors, and retain pipefail before replacing anything.
if ! {
  sops --decrypt --input-type yaml --output-type json "$secrets" |
    jq -e --slurpfile additions <(printf '%s' "$additions") '
      if type == "object" and (has("immich-settings") | not)
        and (keys | all(startswith("authelia-") | not))
      then . + $additions[0]
      else error("Existing Authelia or Immich settings keys or invalid secrets object")
      end
    ' |
    sops --encrypt --config .sops.yaml --filename-override "$secrets" \
      --input-type json --output-type yaml /dev/stdin > "$encrypted_tmp"
} 2>/dev/null; then
  die 'Secret merge or encryption failed; the existing secrets file was not replaced.'
fi
unset additions
[[ -s "$encrypted_tmp" ]] || die 'Encryption produced an empty file.'
[[ ! -L "$secrets" && "$(sha256sum < "$secrets")" == "$original_checksum" ]] ||
  die 'The secrets file changed during bootstrap; refusing to replace it.'
mv -fT -- "$encrypted_tmp" "$secrets"
encrypted_tmp=
printf '%s\n' 'Authelia secrets and Immich baseline settings added to secrets/secrets.yaml (encrypted).' \
  'No services were activated. With the filesystem notifier, retrieve verification links from its configured file on the server, not email.' >&2
