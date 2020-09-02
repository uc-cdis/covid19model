cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: EnvVarRequirement
    envDef:
      S3_BUCKET: $(inputs.s3_bucket) # S3 bucket to copy output viz files to
  - class: DockerRequirement
    dockerPull: "quay.io/cdis/bayes-by-county:feat_cwl"
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
  s3_bucket: "string"
  nIter: int # iterations - make this dynamic

outputs:
  viz:
    type: File[]
    outputBinding:
      glob: "./modelOutput/figures/*/*.png"

# testing without stdout
# stdout: "stdout.txt"
