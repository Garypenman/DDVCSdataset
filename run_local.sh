#!/bin/bash
set -e

MANIFEST="runs.manifest.csv"

tail -n +2 "$MANIFEST" | while IFS=',' read JOB XML NEV HEP ROOT; do
  echo "Running job $JOB: $XML"
  ./bin/epic "$XML" &
done

wait
