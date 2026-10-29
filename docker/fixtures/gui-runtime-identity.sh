#!/bin/sh
set -eu
work=$(mktemp -d /tmp/nextclade-identity-test.XXXXXX)
helper=
group=
runtime=
cleanup_test() {
  if [ -n "$group" ]; then kill -TERM "-$group" 2>/dev/null || :; fi
  if [ -n "$helper" ]; then kill -TERM "$helper" 2>/dev/null || :; wait "$helper" 2>/dev/null || :; fi
  if [ -n "$runtime" ] && [ -L "$runtime" ]; then unlink "$runtime"; fi
  rm -rf "$work"
}
trap cleanup_test EXIT
nextclade-web --port 5824 >"$work/output" 2>&1 &
helper=$!
count=0
until grep -F 'Nextclade Web is ready.' "$work/output" >/dev/null; do
  count=$((count + 1)); [ "$count" -lt 100 ]; sleep 0.1
done
runtime_log=$(awk '/Internal HTTP log:/ {getline; sub(/^[[:space:]]+/, ""); print; exit}' "$work/output")
case "$runtime_log" in /tmp/nextclade-web.*/http.log) ;; *) exit 91 ;; esac
runtime=$(dirname "$runtime_log")
group=$(cat "$runtime/service.pid")
mv "$runtime" "$work/owned-runtime"
mkdir "$work/foreign"
printf '%s\n' 'must remain unchanged' > "$work/foreign/sentinel"
ln -s "$work/foreign" "$runtime"
kill -TERM "$helper"
set +e
wait "$helper"
status=$?
set -e
helper=
cat "$work/output"
test "$status" -eq 74
grep -F 'runtime identity changed' "$work/output"
test -s "$work/owned-runtime/http.log"
test "$(cat "$work/foreign/sentinel")" = 'must remain unchanged'
test -L "$runtime"
if wget -qO- -T 1 http://127.0.0.1:5824/_taf_health >/dev/null 2>&1; then
  echo 'FAIL: changed runtime identity left owned server listening' >&2
  exit 92
fi
echo 'PASS: changed runtime retained diagnostics/foreign data and stopped owned service'
