cwlVersion: v1.0
class: Workflow

inputs:
    s3_bucket: string
    stateList: string
    deathsCutoff: string
    maxBatchSize: string
    nIter: string
    mode: string # must be "batch" -> # if [ $MODEL_RUN_MODE == "batch" ] ;

outputs:
    figures:
        type: File[]
        outputSource: model/figures

steps:
  make-batches:
    run: make-batches.cwl
    in:
      stateList: stateList
      deathsCutoff: deathsCutoff
      maxBatchSize: maxBatchSize
    out: [batches] # this is an array of files: file objects for ["batches/batch1.txt", "batches/batch2.txt", ...]

  model:
    run: model.cwl
    scatter: batch
    in:
      s3_bucket: s3_bucket
      nIter: nIter
      mode: mode
      deathsCutoff: deathsCutoff
      batch: make-batches/batches
    out: [figures]

