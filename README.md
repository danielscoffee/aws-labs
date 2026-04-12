# aws-labs

Hands-on labs for the **AWS Certified Developer – Associate (DVA-C02)** exam.
Each lab provisions a small, self-contained slice of AWS using Terraform (primary)
or CDK (comparison), with Python Lambda handlers unit-tested via `moto`.

See [`STUDY.md`](./STUDY.md) for the exam study guide this repo is built around.

## Repository layout

```
.
├── terraform/
│   ├── env/
│   │   ├── dev/              # dev environment entrypoint (VPC stub)
│   │   └── prod/             # prod environment + OIDC role for CI
│   └── labs/
│       ├── 01-lambda-api/    # Lambda + API Gateway (REST, proxy integration)
│       ├── 02-dynamodb/      # DynamoDB table + Lambda CRUD
│       ├── 03-sqs-sns/       # SNS fan-out → SQS → Lambda
│       ├── 04-kinesis/       # Kinesis Data Streams + consumer
│       ├── 05-ecs-fargate/   # ECS Fargate service
│       ├── 06-cognito/       # Cognito user/identity pools
│       ├── 07-cicd/          # CodeBuild / CodePipeline + buildspec
│       └── 08-monitoring/    # CloudWatch + X-Ray
├── cdk/
│   └── lambda-api/           # CDK re-implementation of lab 01 (L1/L2/L3 constructs)
├── .github/workflows/        # GitHub Actions (OIDC → AWS)
├── Makefile                  # Terraform lifecycle wrapper
├── flake.nix                 # Nix dev shell (terraform, awscli, uv, python)
├── pyproject.toml            # uv workspace for Python lab tests
└── STUDY.md                  # DVA-C02 study guide
```

## Prerequisites

- Terraform `>= 1.6` (AWS provider `~> 6.0`)
- AWS CLI v2, configured with credentials that can create the lab's resources
- Python `>= 3.12` and [`uv`](https://docs.astral.sh/uv/) for running handler tests
- Node.js `>= 20` (CDK lab only)
- Optional: [Nix](https://nixos.org) — `nix develop` drops you into a shell with
  all of the above pinned via [`flake.nix`](./flake.nix)

## Configuration

The `Makefile` loads a `.env` file at the repo root and uses it to pick the
target environment and wire up the S3/DynamoDB remote state backend.

Copy the template and fill in your values:

```bash
cp .env.example .env
```

```dotenv
TERRAFORM_ENV=dev          # dev | prod | homolog
TF_STATE_BUCKET=my-tf-state
TF_STATE_KEY=aws-labs/terraform.tfstate
AWS_REGION=us-east-1
TF_LOCK_TABLE=my-tf-locks
```

`TERRAFORM_ENV` selects `terraform/env/<env>` as the working directory. The
backend values are passed to `terraform init` via `-backend-config`, so the
same Terraform code runs against different state files per environment
without edits.

## Usage

### Terraform environments (`terraform/env/<env>`)

```bash
make terraform-init         # init + configure remote backend
make terraform-fmt          # recursive fmt
make terraform-validate
make terraform-plan         # writes ./tfplan
make terraform-apply        # applies ./tfplan
make terraform-destroy
make terraform-routine      # plan + apply

make terraform-init-migrate # re-init and migrate state (backend changes)
```

### Running an individual lab

The `Makefile` targets drive the `terraform/env/*` entrypoints. To iterate on
a single lab directly:

```bash
cd terraform/labs/01-lambda-api
terraform init
terraform apply
```

### Python handler tests

Handlers in labs 01–04 and 08 are tested with `pytest` + `moto` via a uv
workspace:

```bash
uv sync --all-groups
uv run pytest                              # all labs
uv run pytest terraform/labs/02-dynamodb   # single lab
```

### CDK lab

```bash
cd cdk/lambda-api
npm install
npx cdk synth
npx cdk deploy
```

The stack in [`cdk/lambda-api/lib/stack.ts`](./cdk/lambda-api/lib/stack.ts)
is annotated to contrast CDK construct levels — **L1** (`CfnBucket`),
**L2** (`dynamodb.Table`, `lambda.Function`), and **L3** (`LambdaRestApi`
pattern) — against the equivalent raw Terraform in lab 01.

## CI

[`.github/workflows/terraform.yml`](./.github/workflows/terraform.yml) runs
`make terraform-routine` on pushes to `main`, authenticating to AWS via
GitHub OIDC (no long-lived access keys). The trust role is declared in
[`terraform/env/prod/oidc.tf`](./terraform/env/prod/oidc.tf).

> The workflow is currently commented out pending a working OIDC role ARN.

## License

[MIT](./LICENSE)
