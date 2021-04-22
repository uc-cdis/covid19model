#!/usr/bin/env bash

# exit if any step fails
set -euxo pipefail

if [[ -z "${S3_BUCKET-}" ]]; then
  echo "No S3 bucket provided (use env var S3_BUCKET)"
  exit 1
fi

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
  if [[ -z "${STATE_LIST-}" ]]; then
    echo "No state list provided (use env var STATE_LIST)"
    exit 1
  fi
  sh covid19-bayes-model-run.sh us_mobility $DEATHS_CUTOFF $N_ITER -stateList $STATE_LIST
fi
echo "Done!"

# copy images to S3 under prefix "bayes-by-county"
# directory structure:
#   bayes-by-county/
#     17031/ (FIPS)
#       cases.[svg/png]
#       casesForecast.[svg/png]
#       deaths.[svg/png]
#       deathsForecast.[svg/png]
#       Rt.[svg/png]
#     <more FIPS folders>
#     CountyCodeList.txt
#     Rt_Top20.[svg/png]

echo "Will upload to S3 bucket:"
# TODO don't copy the HTML/JS files
ls -laR modelOutput/figures/

echo "Uploading to S3 bucket..."
if [[ -n "$S3_BUCKET" ]]; then
  aws s3 sync "./modelOutput/figures" "$S3_BUCKET/bayes-by-county/" --exclude ".keep"
fi
