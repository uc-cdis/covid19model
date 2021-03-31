#!/usr/bin/env bash

# exit if any step fails
set -euxo pipefail

# run R bayes-by-county simulation and push outputs to S3
echo "Running bayes-by-county..."

# call form:
# sh covid19-bayes-model-run.sh <stan_model> \
#   <minimumDeaths> \
#   <nIterations> \
#   (-stateList | -batch) \
#   (<stateList> | <batchID>) \
#   [--validate]

# example calls:
## sh covid19-bayes-model-run.sh us_mobility 150 200 -stateList "Illinois,NewYork"
## sh covid19-bayes-model-run.sh us_mobility 150 200 -stateList "Illinois,NewYork" --validate
## sh covid19-bayes-model-run.sh us_mobility 150 200 -stateList "all"
## sh covid19-bayes-model-run.sh us_mobility 150 200 -batch 1

# cd / # TODO remove
if [ $MODEL_RUN_MODE == "batch" ]; then
  sh covid19-bayes-model-run.sh us_mobility $DEATHS_CUTOFF $N_ITER -batch "$BATCH"
else
  sh covid19-bayes-model-run.sh us_mobility $DEATHS_CUTOFF $N_ITER -stateList $STATE_LIST
fi
echo "Done!"

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

echo "Will upload to S3 bucket:"
# TODO don't copy the HTML/JS files
ls -laR modelOutput/figures/

echo "Uploading to S3 bucket..."
if [[ -n "$S3_BUCKET" ]]; then
  aws s3 sync "./modelOutput/figures" "$S3_BUCKET/bayes-by-county/" --exclude ".keep"
fi
