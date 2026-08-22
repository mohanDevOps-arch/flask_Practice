# Ansible: deploy the flask container to EC2

There is exactly one playbook here — `deploy.yml`. It's run on the EC2 target by
the built-in SSM document **`AWS-ApplyAnsiblePlaybooks`**, which:

1. Resolves the target instance(s) by tag (`Project=flask-practice`).
2. Downloads this repo at the exact commit being deployed onto the target.
3. Installs Ansible if missing (`InstallDependencies=True`).
4. Runs `ansible-playbook infra/ansible/deploy.yml -e image_uri=<uri>`.

The playbook itself:

- Runs `connection: local` — Ansible executes on the EC2, not from the CI runner.
- Fetches `MONGO_URI` and `SECRET_KEY` from SSM Parameter Store (SecureString).
- Logs the target's Docker to ECR using the instance's IAM role.
- Pulls the image, stops+removes the old container, runs the new one.
- Waits for `/health` to return `{"status":"healthy"}` before exiting.

## Running it manually

You almost never need to — the pipeline does it. If you want to try locally:

```bash
# Package the repo + playbook and invoke via SSM
aws ssm send-command \
  --document-name "AWS-ApplyAnsiblePlaybooks" \
  --targets "Key=tag:Project,Values=flask-practice" \
  --parameters '{
    "SourceType":["GitHub"],
    "SourceInfo":["{\"owner\":\"immrdg\",\"repository\":\"flask_Practice\",\"getOptions\":\"branch:main\"}"],
    "InstallDependencies":["True"],
    "PlaybookFile":["infra/ansible/deploy.yml"],
    "ExtraVariables":["image_uri=1234.dkr.ecr.us-east-1.amazonaws.com/flask-practice:abc12345"]
  }'
```

## Requirements on the target

- Docker running (Terraform's `user_data` sets this up).
- IAM role with `AmazonSSMManagedInstanceCore`, `AmazonEC2ContainerRegistryReadOnly`,
  and read access to the two SSM parameters (Terraform grants this).
- Outbound HTTPS reachable (to fetch the repo from GitHub and pull from ECR).
