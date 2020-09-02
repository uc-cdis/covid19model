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

inputs:
  stateList: string
  deathsCutoff: int
  maxBatchSize: int

outputs:
  batches:
    type: File[]
    outputBinding:
      glob: "batches/*"

# same as dockerfile command
baseCommand: ["bash", "docker-run.sh"]
