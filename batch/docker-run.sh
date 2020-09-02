#!/bin/bash

### example call for this script
# sh docker-run.sh -stateList "Illinois,NewYork" -deathsCutoff 100 -maxBatchSize 35

echo "\n--- making county batches with these parameters ---"
echo 'stateList = '     $2
echo 'deathsCutoff = '  $4
echo 'maxBatchSize = '  $6

#### example calls to Rscript
# Rscript make-batches.r -stateList "Illinois,NewYork" -deathsCutoff 100 -maxBatchSize 35
# Rscript make-batches.r -stateList "all" -deathsCutoff 100 -maxBatchSize 35

# run the Rscript
Rscript make-batches.r -stateList $2 -deathsCutoff $4 -maxBatchSize $6

echo "\n--- routine completed ---\n"