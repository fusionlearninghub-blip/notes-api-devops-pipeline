# Notes API — CI/CD Pipeline on AWS ECS Fargate

A production-shaped deployment pipeline: containerized FastAPI service,
Terraform-managed AWS infrastructure, and a GitHub Actions pipeline that
tests, scans, and deploys on every merge to `main` behind a manual
approval gate.

The sample app (a small notes API) exists only as a vehicle. **The point
of this repo is the infrastructure and pipeline around it** — see
[`docs/architecture.md`](docs/architecture.md) for the full diagram and
the reasoning behind each design decision.

## Stack

| Layer | Tooling |
|---|---|
| App | Python 3.12, FastAPI |
| Container | Docker (multi-stage, non-root, health-checked) |
| Infra as Code | Terraform, modular (network / alb / ecs / monitoring) |
| Compute | AWS ECS Fargate behind an Application Load Balancer |
| Registry | Amazon ECR (image scanning + immutable tags) |
| CI/CD | GitHub Actions — lint → test → build → scan (Trivy) → push → manual gate → deploy |
| Observability | CloudWatch dashboards, alarms, container insights, SNS alerts |
| Security | IAM least-privilege (separate execution/task roles), OIDC (no long-lived AWS keys in CI), private subnets for compute |

## Repo layout

```
app/                      FastAPI app + tests + Dockerfile
terraform/
  modules/                Reusable modules: network, alb, ecs, monitoring
  environments/prod/      Root module wiring everything together
.github/workflows/
  ci-cd.yml               App pipeline: test, build, scan, push, deploy
  terraform.yml           Infra pipeline: plan on PR, apply on merge (gated)
docs/architecture.md      Diagram + documented design trade-offs
```

## Running locally

```bash
cd app
pip install -r requirements-dev.txt
pytest tests/ -v
uvicorn main:app --reload
# → http://localhost:8000/health
```

Or with Docker:

```bash
cd app
docker build -t notes-api .
docker run -p 8000:8000 notes-api
```

## Deploying to your own AWS account

This was built and tested for correctness (all app tests pass, all
Terraform module wiring cross-checked), but **you need to run the actual
deploy yourself** with your own AWS credentials — I don't have a way to
provision resources in your account for you.

### 1. One-time bootstrap (state backend)

Terraform needs an S3 bucket + DynamoDB table for remote state, created
before first `init`:

```bash
aws s3api create-bucket --bucket <your-unique-bucket-name> --region us-east-1
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Update `terraform/environments/prod/main.tf` backend block with your
bucket and table names.

### 2. Provision infrastructure

```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

### 3. Build and push the first image manually (CI takes over after this)

```bash
cd app
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker build -t notes-api .
docker tag notes-api:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/notes-api:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/notes-api:latest
```

### 4. Wire up GitHub Actions

- Create an IAM role trusted for GitHub OIDC (`token.actions.githubusercontent.com`), scoped to this repo, with permissions for ECR/ECS/CloudWatch.
- Add repo secrets: `AWS_DEPLOY_ROLE_ARN`, `AWS_ACCOUNT_ID`.
- Create a GitHub Environment named `production` with required reviewers — this is what makes the deploy step a manual approval gate.
- Push to `main`: tests run, image builds and gets scanned, then waits for your approval before deploying.

### 5. Verify

```bash
curl http://$(terraform output -raw alb_dns_name)/health
```

## Design decisions

Every non-obvious choice (Fargate vs EKS, single NAT gateway, immutable
image tags, the manual approval gate) is documented with its trade-off
in [`docs/architecture.md`](docs/architecture.md) — worth a read before
an interview.

## Estimated AWS cost

Roughly $35–50/month running continuously (ALB ~$16, NAT Gateway ~$32,
Fargate tasks minimal at this scale). Destroy with `terraform destroy`
when not actively demoing it.

