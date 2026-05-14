#!/bin/bash
set -e

echo "=============================================="
echo " WARNING: This will DELETE test-generated files"
echo "=============================================="
echo
echo "The following files will be removed:"
echo "  - output/*.hepmc"
echo "  - output/histos/*.root"
echo "  - metadata/*.log"
echo "  - scenarios/*.xml"
echo
read -r -p "Are you sure you want to run this? (yes/NO): " ANSWER

if [[ "$ANSWER" != "yes" ]]; then
  echo "Aborted. Nothing was removed."
  exit 0
fi

echo
echo "Cleaning test outputs..."

# HepMC outputs
rm -f output/*.hepmc

# ROOT histograms
rm -f output/histos/*.root

# Log files
rm -f metadata/*.log

# Steering XMLs
rm -f scenarios/*.xml

echo "Done."
