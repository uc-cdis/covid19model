cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: EnvVarRequirement
    envDef:
      S3_BUCKET: $(inputs.s3_bucket) # S3 bucket to copy output viz files to
      MODEL_RUN_MODE: $(inputs.mode)
      DEATHS_CUTOFF: $(inputs.deathsCutoff)
      N_ITER: $(inputs.nIter)
      BATCH: $(inputs.batch.contents)
  - class: DockerRequirement
    dockerPull: "quay.io/cdis/bayes-by-county:v3.2"
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

# returning a dummy output so the engine doesn't choke after scatter finishes
outputs:
  output:
    type: string
    outputBinding:
      outputEval: "$('output')"

# testing without stdout
# stdout: "stdout.txt"
