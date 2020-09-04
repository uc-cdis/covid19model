cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: EnvVarRequirement
    envDef:
      STATE_LIST: $(inputs.stateList)
      DEATHS_CUTOFF: $(inputs.deathsCutoff)
      MAX_BATCH_SIZE: $(inputs.maxBatchSize)
  - class: DockerRequirement
    dockerPull: "quay.io/cdis/make-county-batches:feat_batch-cwl"
  - class: ResourceRequirement
    coresMin: 2
    coresMax: 2
    # this is in MiB -> converts to 16GiB
    ramMin: 16384
    ramMax: 16384

inputs:
  stateList: string
  deathsCutoff: string
  maxBatchSize: string

outputs:
  batches:
    type: File[]
    outputBinding:
      glob: "batches/*"

# same as dockerfile command
baseCommand: ["bash", "/batch/docker-run.sh"]
