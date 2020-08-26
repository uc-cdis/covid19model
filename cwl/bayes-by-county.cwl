cwlVersion: v1.0
class: CommandLineTool

requirements:
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

# really the model currently takes no inputs, so - omitting inputs block

# missing env: S3_BUCKET
# unsolved question: how to pull off the S3 creds transfer?
# could specify a k8s secret to mount, hmm..

outputs:
  viz:
    type: File[]
    outputBinding:
      glob: "./modelOutput/figures/*/*.png"

# testing without stdout
# stdout: "stdout.txt"
