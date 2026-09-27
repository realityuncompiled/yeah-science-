#!/usr/bin/env bash
# Run from any directory; Python remains the canonical entry point.
set -eu
cd "$(dirname "$0")/.."
if [ -x .venv/bin/python ]; then
    exec .venv/bin/python -m app "$@"
elif [ -x .venv/Scripts/python.exe ]; then
    exec .venv/Scripts/python.exe -m app "$@"
else
    exec python3 -m app "$@"
fi
