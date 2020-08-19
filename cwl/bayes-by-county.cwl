cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: DockerRequirement
    # tag?
    dockerPull: "quay.io/cdis/bayes-by-county:master"
  # these match those req's in nb-etl's job.yaml in cloud-automation
  - class: ResourceRequirement
    coresMin: 4
    # this is in MiB -> converts to 16GiB
    ramMin: 16384

# same as dockerfile command
baseCommand: ["bash", "/docker-run.sh"]

# really the model currently takes no inputs, so - omitting inputs block

outputs:
  output:
    type: "stdout"

stdout: "stdout.txt"
