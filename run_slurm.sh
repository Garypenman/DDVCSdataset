#!/bin/bash
#SBATCH --job-name=ddvcs
#SBATCH --array=1-$(($(wc -l < runs.manifest.csv)-1))
#SBATCH --time=02:00:00
#SBATCH --mem=4G
#SBATCH --output=logs/%A_%a.out
#SBATCH --error=logs/%A_%a.err

LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" runs.manifest.csv)
IFS=',' read JOB XML NEV HEP ROOT <<< "$LINE"

echo "Running job $JOB"
./bin/epic "$XML"
