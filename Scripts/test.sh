#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
swiftc -module-cache-path "$test_dir/modules" 'Tally Bar/TrackerStore.swift' Tests/TrackerTests.swift -o "$test_dir/tracker-tests"
"$test_dir/tracker-tests"
