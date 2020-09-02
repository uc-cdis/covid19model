cwlVersion: v1.0
class: Workflow

inputs:
    s3_bucket: string
    stateList: string
    deathsCutoff: int
    maxBatchSize: int
    nIter: int

# outputs:

steps:
  make-batches:
    run: make-batches.cwl
    in:
      stateList: stateList
      deathsCutoff: deathsCutoff
      maxBatchSize: maxBatchSize
    # not sure about this one!
    out: [classfile]

  model:
    run: model.cwl
    in:
      s3_bucket: s3_bucket
      nIter: nIter
    out: [extracted_file]

