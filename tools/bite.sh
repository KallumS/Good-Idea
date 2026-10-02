#!/bin/bash
# Prove a test bites: break the code on purpose in a copy of the repo and
# watch a test fail.
#
#   tools/bite.sh "what is broken" test_idea.lua "PYTHON"
#
# PYTHON is run in the copy with r(path, old, new) defined, which replaces
# the first `old` in `path` with `new` (and fails if `old` is not there):
#
#   tools/bite.sh "no low interval limit" test_theory.lua \
#     "r('reascripts/gi_theory.lua', 'notes[i - 1] < 48', 'false')"
#
# Prints BIT (and the first failures), MISSED, or DID NOT APPLY. A MISSED
# is either a gap in the tests or a sabotage that changed nothing - check
# which before trusting it.

set -u
here=$(cd "$(dirname "$0")/.." && pwd)
copy=$(mktemp -d)
trap 'rm -rf "$copy"' EXIT
cp -r "$here/." "$copy"
cd "$copy" || exit 1
python3 - <<EOF || { echo "DID NOT APPLY: $1"; exit 0; }
def r(p, a, b):
    s = open(p).read()
    assert a in s, (p, a)
    open(p, "w").write(s.replace(a, b, 1))
$3
EOF
out=$(lua5.4 "tests/$2" 2>&1)
if echo "$out" | grep -q FAIL; then
  echo "BIT: $1 -> $(echo "$out" | grep FAIL | head -2 | cut -c1-150)"
else
  echo "MISSED: $1"
fi
