#!/bin/bash

echo "\n--- making county batches with these parameters ---"
echo 'stateList = '     $STATE_LIST
echo 'deathsCutoff = '  $DEATHS_CUTOFF
echo 'maxBatchSize = '  $MAX_BATCH_SIZE

# run the etl to generate all input tables
echo "\n--- input ETL ---"
cd /py
python3 etl.py

# make the batches
echo "\n--- make-batches ---"

#### example calls to Rscript
# Rscript make-batches.r -stateList "Illinois,NewYork" -deathsCutoff 100 -maxBatchSize 35
# Rscript make-batches.r -stateList "all" -deathsCutoff 100 -maxBatchSize 35

# run the Rscript
cd /batch
Rscript make-batches.r -stateList $STATE_LIST -deathsCutoff $DEATHS_CUTOFF -maxBatchSize $MAX_BATCH_SIZE

echo "\n--- routine completed ---\n"