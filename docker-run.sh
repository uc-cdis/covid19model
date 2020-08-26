#!/usr/bin/env bash

# run R bayes-by-county simulation and push outputs to S3
echo "Running bayes-by-county..."

# sh run.sh <stan_model> <deaths_cutoff> <nIterations>
cd /
sh run.sh us_mobility 520 150

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

echo "Copying to S3 bucket..."
if [[ -n "$S3_BUCKET" ]]; then
  aws s3 sync "./modelOutput/figures" "$S3_BUCKET/bayes-by-county/" --exclude ".keep"
fi
