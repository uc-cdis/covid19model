#!/bin/sh
set -e

if [[ $1 && $1 == "all" ]]; then
  echo "Linting all R files"
  linter='
  #! /usr/bin/R
  if (!("styler" %in% installed.packages()[, "Package"])) {
    print("Installing styler")
    install.packages("styler", repo = "http://cran.rstudio.com")
  }
  suppressWarnings(library(styler))
  style_dir(".")
  '
  echo "$linter" > .linter.R
  Rscript .linter.R
  rm -f .linter.R
else
  echo "Linting staged R files"
  linter='
  #! /usr/bin/R
  if (!("styler" %in% installed.packages()[, "Package"])) {
    print("Installing styler")
    install.packages("styler", repo = "http://cran.rstudio.com")
  }
  suppressWarnings(library(styler))
  args <- commandArgs(trailingOnly = TRUE)
  file_name <- args[2]
  style_file(file_name)
  '
  echo "$linter" > .linter.R
  staged=$(git diff --staged --name-only)
  for file in ${staged}; do
    if [[ ${file: -2} != ".r" && ${file: -2} != ".R" ]]; then
      continue
    fi
    echo "  $file"
    Rscript .linter.R --args $file >/dev/null
  done
fi

rm -f .linter.R
