#!/bin/bash

echo "\n--- making county batches with these parameters ---"
echo 'stateList = '     $STATE_LIST
echo 'deathsCutoff = '  $DEATHS_CUTOFF
echo 'maxBatchSize = '  $MAX_BATCH_SIZE

#### example calls to Rscript
# Rscript make-batches.r -stateList "Illinois,NewYork" -deathsCutoff 100 -maxBatchSize 35
# Rscript make-batches.r -stateList "all" -deathsCutoff 100 -maxBatchSize 35

# run the Rscript
Rscript make-batches.r -stateList $STATE_LIST -deathsCutoff $DEATHS_CUTOFF -maxBatchSize $MAX_BATCH_SIZE

echo "\n--- routine completed ---\n"