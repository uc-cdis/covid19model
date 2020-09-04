cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: EnvVarRequirement
    envDef:
      S3_BUCKET: $(inputs.s3_bucket) # S3 bucket to copy output viz files to
      MODEL_RUN_MODE: $(inputs.mode)
      DEATHS_CUTOFF: $(inputs.deathsCutoff)
      N_ITER: $(inputs.nIter)
      BATCH: $(inputs.batch.path)
  - class: DockerRequirement
    dockerPull: "quay.io/cdis/bayes-by-county:feat_batch-cwl"
  # these match those req's in nb-etl's job.yaml in cloud-automation
  - class: ResourceRequirement
    coresMin: 4
    coresMax: 4
    # this is in MiB -> converts to 16GiB
    ramMin: 16384
    ramMax: 16384

# same as dockerfile command
baseCommand: ["bash", "/docker-run.sh"]

inputs:
  s3_bucket: string
  nIter: string
  mode: string
  deathsCutoff: string
  batch: File

outputs:
  figures:
    type: File[]
    outputBinding:
      glob: 
        - "/modelOutput/figures/*.*"
        - "/modelOutput/figures/*/*.png"

# testing without stdout
# stdout: "stdout.txt"