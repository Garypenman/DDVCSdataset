#!/bin/bash
set -e

MANIFEST="runs.manifest.csv"
EPIC_BIN="./bin/epic"

mkdir -p metadata

tail -n +2 "$MANIFEST" | while IFS=',' read JOB XML NEV HEP ROOT; do

  # Derive a clean logfile name from the XML
  XML_BASENAME=$(basename "$XML" .xml)
  LOGFILE="metadata/${XML_BASENAME}.log"

  echo "Running job $JOB"
  echo "  XML     : $XML"
  echo "  Logfile : $LOGFILE"

  "$EPIC_BIN" --scenario="$XML" --seed="$RANDOM" \
    > "$LOGFILE" 2>&1 &

  # Small delay to avoid hammering the filesystem / stdout
  sleep 2

done

wait
