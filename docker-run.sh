#!/usr/bin/env bash

# run R bayes-by-county simulation and push outputs to S3
echo "Running bayes-by-county..."

# call form:
# sh run.sh <stan_model> \
#   <minimumDeaths> \
#   <nIterations> \
#   (-stateList | -batch) \
#   (<stateList> | <batchID>) \
#   [--validate]

# example calls:
## sh run.sh us_mobility 150 200 -stateList "Illinois,NewYork"
## sh run.sh us_mobility 150 200 -stateList "Illinois,NewYork" --validate
## sh run.sh us_mobility 150 200 -stateList "all"
## sh run.sh us_mobility 150 200 -batch 1

cd /
if [ $MODEL_RUN_MODE == "batch" ]; then
  sh run.sh us_mobility $DEATHS_CUTOFF $N_ITER -batch $BATCH
else
  sh run.sh us_mobility $DEATHS_CUTOFF $N_ITER -stateList $STATE_LIST
fi

# copy images to S3 under prefix "bayes-by-county"
# directory structure:
#   bayes-by-county/
#     17031/ (FIPS)
#       cases.png
#       casesForecast.png
#       deaths.png
#       deathsForecast.png
#       Rt.png
#     <more FIPS folders>
#     CountyCodeList.txt
#     Rt_All.png

# debug
ls ./modelOutput/figures/*/*.png

# check
echo $S3_BUCKET

echo "Copying to S3 bucket..."
if [[ -n "$S3_BUCKET" ]]; then
  aws s3 sync "./modelOutput/figures" "$S3_BUCKET/bayes-by-county/" --exclude ".keep"
fi
