#!/usr/bin/env bash
# Stop hook de social-api: corre rubocop + rspec (igual que el CI) al terminar
# cada turno, pero solo si el código cambió desde la última verificación exitosa.
# Si algo falla, sale con código 2: Claude recibe el error y sigue corrigiendo.

set -uo pipefail

MAX_ATTEMPTS=3
STATE_DIR="$CLAUDE_PROJECT_DIR/.claude"
STATE_FILE="$STATE_DIR/.verify-state"
ATTEMPTS_FILE="$STATE_DIR/.verify-attempts"
WATCHED=(app lib config db spec Gemfile Gemfile.lock .rubocop.yml)

cd "$CLAUDE_PROJECT_DIR" || exit 0

input=$(cat)
stop_hook_active=$(printf '%s' "$input" | ruby -rjson -e '
  begin
    puts JSON.parse(STDIN.read)["stop_hook_active"] ? "1" : "0"
  rescue StandardError
    puts "0"
  end')

# Huella del estado actual del código (cambios trackeados + archivos nuevos)
current_state=$( {
  git diff HEAD -- "${WATCHED[@]}" 2>/dev/null
  git ls-files -z --others --exclude-standard -- "${WATCHED[@]}" | xargs -0 -r cat
} | sha1sum | cut -d' ' -f1 )

# Sin cambios desde la última verificación verde: no hay nada que hacer
if [[ -f "$STATE_FILE" && "$(cat "$STATE_FILE")" == "$current_state" ]]; then
  rm -f "$ATTEMPTS_FILE"
  exit 0
fi

# Control de intentos para no entrar en un loop infinito de correcciones
if [[ "$stop_hook_active" == "1" ]]; then
  attempts=$(( $(cat "$ATTEMPTS_FILE" 2>/dev/null || echo 0) + 1 ))
else
  attempts=1
fi
echo "$attempts" > "$ATTEMPTS_FILE"

if (( attempts > MAX_ATTEMPTS )); then
  rm -f "$ATTEMPTS_FILE"
  echo "verify.sh: se alcanzó el máximo de $MAX_ATTEMPTS intentos; revisá los checks a mano." >&2
  exit 0
fi

failures=""
run_check() {
  local name="$1"; shift
  local output
  if ! output=$("$@" 2>&1); then
    failures+=$'\n'"### $name falló"$'\n'"$(printf '%s' "$output" | tail -n 60)"$'\n'
  fi
}

run_check "rubocop" bundle exec rubocop --config .rubocop.yml --format simple
run_check "rspec"   bundle exec rspec --format progress

if [[ -n "$failures" ]]; then
  {
    echo "Los checks del CI fallaron después de tus cambios. Corregilos antes de terminar:"
    echo "$failures"
  } >&2
  exit 2
fi

echo "$current_state" > "$STATE_FILE"
rm -f "$ATTEMPTS_FILE"
exit 0
