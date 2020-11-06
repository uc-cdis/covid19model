#!/bin/bash

echo "\n--- making county batches with these parameters ---"
echo 'stateList = '     $STATE_LIST
echo 'deathsCutoff = '  $DEATHS_CUTOFF
echo 'maxBatchSize = '  $MAX_BATCH_SIZE

# run the etl to generate all input tables
echo "\n--- input ETL ---"
cd /py
python3 /py/etl.py

## MOBILITY DATA
echo "\n- Fetch Mobility Data  -"
cd ../modelInput/mobility/
wget -O Global_Mobility_Report.csv https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv 
cd ./visit-data/
sh get-visit-data.sh
cd ../../../r
Rscript mobility-regression.r > /dev/null 2>&1

# make the batches
echo "\n--- make-batches ---"

#### example calls to Rscript
# Rscript make-batches.r -stateList "Illinois,NewYork" -deathsCutoff 100 -maxBatchSize 35
# Rscript make-batches.r -stateList "all" -deathsCutoff 100 -maxBatchSize 35

# run the Rscript
cd /batch
Rscript /batch/make-batches.r -stateList $STATE_LIST -deathsCutoff $DEATHS_CUTOFF -maxBatchSize $MAX_BATCH_SIZE -outDir $TOOL_WORKING_DIR

echo "\n--- routine completed ---\n"
