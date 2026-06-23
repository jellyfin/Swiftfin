#!/bin/zsh
# Bruno verification harness — runs the pure-logic unit checks without an Xcode test target.
# Compiles the real Shared/Objects/Bruno/*.swift pure types together with the verify mains.
set -e
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
echo "== RNG verification =="
swiftc -O Shared/Objects/Bruno/BrunoRNG.swift bruno-verify/main.swift -o "$OUT/rng_verify"
"$OUT/rng_verify"
