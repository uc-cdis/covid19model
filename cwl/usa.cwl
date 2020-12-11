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
    output:
        type: string[]
        outputSource: model/output

steps:
  make-batches:
    run: make-batches.cwl
    in:
      s3_bucket: s3_bucket
      stateList: stateList
      deathsCutoff: deathsCutoff
      maxBatchSize: maxBatchSize
    out: [batches]

  model:
    run: model.cwl
    scatter: batch
    in:
      s3_bucket: s3_bucket
      nIter: nIter
      mode: mode
      deathsCutoff: deathsCutoff
      batch: make-batches/batches
    out: [output]

  write-county-list:
    run: write-county-list.cwl
    in:
      s3_bucket: s3_bucket
      stateList: stateList
      deathsCutoff: deathsCutoff
      maxBatchSize: maxBatchSize
      hold: model/output
    out: [batches]
