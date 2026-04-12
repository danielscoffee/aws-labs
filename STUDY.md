# AWS Certified Developer Associate — Study Guide

## Exam Overview

- **Code:** DVA-C02
- **Format:** 65 questions (multiple choice / multiple response)
- **Duration:** 130 minutes
- **Passing score:** 720 / 1000
- **Domains:**

| Domain | Weight |
|--------|--------|
| 1. Development with AWS Services | 32% |
| 2. Security | 26% |
| 3. Deployment | 24% |
| 4. Troubleshooting & Optimization | 18% |

---

## Domain 1 — Development with AWS Services

> [!WARNING]
> Need to pratice this module
### AWS Lambda
- [x] Function lifecycle: cold start vs warm start
- [x] Invocation types: synchronous, asynchronous, event source mapping
- [x] Layers, environment variables, reserved concurrency
- [x] Destinations (on success / on failure)
- [x] Lambda with API Gateway (proxy integration)
- [x] Limits: 15 min timeout, 10 GB memory, 250 MB deployment package (unzipped)

### API Gateway
- [ ] REST API vs HTTP API vs WebSocket API
- [ ] Stages, deployments, stage variables
- [ ] Integration types: Lambda proxy, HTTP, AWS service, Mock
- [ ] Throttling: default 10k req/s, burst 5k
- [ ] Caching, usage plans, API keys
- [ ] CORS configuration

### DynamoDB
- [ ] Data model: tables, items, attributes
- [ ] Primary key types: partition key, composite key
- [ ] Read/Write capacity: provisioned vs on-demand
- [ ] Indexes: LSI (at creation) vs GSI (anytime)
- [ ] Streams + Lambda triggers
- [ ] DAX for read caching
- [ ] Conditional writes, transactions (`TransactWriteItems`)
- [ ] TTL attribute
- [ ] Pagination with `LastEvaluatedKey`

### S3
- [ ] Storage classes and lifecycle policies
- [ ] Versioning, MFA Delete
- [ ] Pre-signed URLs
- [ ] S3 Events → Lambda / SQS / SNS
- [ ] Cross-region replication (CRR) vs same-region (SRR)
- [ ] Encryption: SSE-S3, SSE-KMS, SSE-C, client-side
- [ ] Bucket policies vs ACLs vs CORS

### SQS / SNS / EventBridge
- [ ] SQS: standard vs FIFO, visibility timeout, DLQ, long polling
- [ ] SNS: fan-out pattern, filter policies, message attributes
- [ ] EventBridge: rules, targets, event buses, schema registry
- [ ] SQS as Lambda event source (batch size, bisect on error)

### Step Functions
- [ ] Standard vs Express workflows
- [ ] States: Task, Choice, Wait, Parallel, Map, Pass, Fail, Succeed
- [ ] Error handling: Catch, Retry
- [ ] Integration with Lambda, ECS, DynamoDB, SQS

### Kinesis
- [ ] Kinesis Data Streams: shards, partition keys, sequence numbers
- [ ] Kinesis Data Firehose: delivery to S3/Redshift/OpenSearch
- [ ] Kinesis Data Analytics: real-time SQL processing
- [ ] Enhanced fan-out vs standard consumers

### ECS / ECR / Fargate
- [ ] Task definitions, services, clusters
- [ ] Launch types: EC2 vs Fargate
- [ ] IAM roles for tasks (task role vs execution role)
- [ ] ECR image push/pull, lifecycle policies

### Elastic Beanstalk
- [ ] Deployment modes: All at once, Rolling, Rolling with additional batch, Immutable, Blue/Green
- [ ] `.ebextensions` for environment customization
- [ ] Saved configurations, environment tiers (web vs worker)
- [ ] `Procfile` and `Buildfile`

### AppSync
- [ ] GraphQL: queries, mutations, subscriptions
- [ ] Resolvers: Unit vs Pipeline
- [ ] Data sources: DynamoDB, Lambda, HTTP, RDS, OpenSearch

### Cognito
- [ ] User Pools: sign-up/sign-in, JWT tokens (ID, Access, Refresh)
- [ ] Identity Pools: federated identities, temporary AWS credentials
- [ ] Triggers: pre-sign-up, post-confirmation, pre-token generation
- [ ] Hosted UI vs custom UI

---

## Domain 2 — Security

### IAM
- [ ] Policies: identity-based, resource-based, permissions boundaries, SCPs
- [ ] Policy evaluation logic (explicit deny > SCP > permissions boundary > identity policy > resource policy)
- [ ] Roles: assume role, cross-account access, service roles
- [ ] IAM conditions (`aws:RequestedRegion`, `aws:MultiFactorAuthPresent`, etc.)

### STS
- [ ] `AssumeRole`, `AssumeRoleWithWebIdentity`, `AssumeRoleWithSAML`
- [ ] Session duration, external ID, trust policies

### KMS
- [ ] CMK vs AWS managed keys vs customer managed keys
- [ ] Envelope encryption concept
- [ ] Key policies + grants
- [ ] `GenerateDataKey`, `Encrypt`, `Decrypt` API calls
- [ ] Automatic key rotation

### Secrets Manager vs SSM Parameter Store
- [ ] Secrets Manager: automatic rotation, cross-account, charged per secret
- [ ] Parameter Store: `String`, `StringList`, `SecureString`; standard vs advanced tiers
- [ ] Referencing secrets in Lambda / ECS environment variables

### ACM / HTTPS
- [ ] Certificate provisioning for ALB / API Gateway / CloudFront
- [ ] DNS vs email validation

---

## Domain 3 — Deployment

### CI/CD with AWS Developer Tools
- [ ] **CodeCommit:** Git-based repos, branch policies, triggers
- [ ] **CodeBuild:** `buildspec.yml` structure (phases: install, pre_build, build, post_build), artifacts, caching
- [ ] **CodeDeploy:** EC2/Lambda/ECS deployments, `appspec.yml`, lifecycle hooks
- [ ] **CodePipeline:** stages, actions, approval actions, cross-region actions

### CodeDeploy Deployment Strategies
- [ ] EC2/On-premises: In-place, Blue/Green
- [ ] Lambda: Canary, Linear, All-at-once
- [ ] ECS: Blue/Green (integrated with ALB)

### SAM (Serverless Application Model)
- [ ] `template.yaml` vs standard CloudFormation
- [ ] Resource types: `AWS::Serverless::Function`, `Api`, `SimpleTable`
- [ ] `sam build`, `sam deploy`, `sam local invoke`
- [ ] Globals section

### CloudFormation
- [ ] Template anatomy: Parameters, Mappings, Conditions, Resources, Outputs
- [ ] Intrinsic functions: `Ref`, `Fn::GetAtt`, `Fn::Sub`, `Fn::ImportValue`
- [ ] Stack updates: change sets
- [ ] `DeletionPolicy`, `UpdateReplacePolicy`
- [ ] Cross-stack references with Exports/Imports
- [ ] Custom resources (Lambda-backed)

### CDK
- [ ] Constructs: L1 (Cfn*), L2, L3 (Patterns)
- [ ] `cdk synth`, `cdk deploy`, `cdk diff`

---

## Domain 4 — Troubleshooting & Optimization

### CloudWatch
- [ ] Metrics, custom metrics (`put-metric-data`), metric math
- [ ] Alarms: states (OK, ALARM, INSUFFICIENT_DATA), actions
- [ ] Logs: log groups, log streams, metric filters, subscription filters
- [ ] CloudWatch Logs Insights query syntax
- [ ] Container Insights, Lambda Insights

### X-Ray
- [ ] Concepts: traces, segments, subsegments, annotations vs metadata
- [ ] Sampling rules
- [ ] Service map
- [ ] SDK instrumentation (Node.js, Python, Java, Go)
- [ ] Enabling on Lambda: `AWS_XRAY_DAEMON_ADDRESS`, active tracing toggle
- [ ] X-Ray with API Gateway and ECS

### Performance Optimization
- [ ] Lambda: minimize cold starts (provisioned concurrency, keep small packages), connection reuse outside handler
- [ ] DynamoDB: avoid hot partitions, use sparse indexes, batch operations
- [ ] API Gateway: caching, response compression
- [ ] SQS: long polling, batch processing
- [ ] ElastiCache: Lazy Loading vs Write-Through vs TTL strategies

---

## Key AWS SDK / CLI Patterns

```bash
# Common patterns worth memorizing
aws s3 presign s3://bucket/key --expires-in 3600
aws dynamodb put-item --table-name T --item file://item.json
aws sqs send-message --queue-url <url> --message-body "hello"
aws lambda invoke --function-name fn --payload '{}' output.json
aws cloudformation deploy --template-file template.yaml --stack-name my-stack
aws ssm get-parameter --name /myapp/key --with-decryption
```

---

## Cheat Sheet — Common Limits

| Service | Limit |
|---------|-------|
| Lambda timeout | 15 minutes |
| Lambda deployment package | 50 MB (zipped), 250 MB (unzipped) |
| Lambda concurrent executions (default) | 1,000 per region |
| SQS message size | 256 KB |
| SQS visibility timeout max | 12 hours |
| SQS retention max | 14 days |
| DynamoDB item size | 400 KB |
| API Gateway payload | 10 MB (REST), 10 MB (HTTP) |
| Kinesis record size | 1 MB |
| S3 single PUT | 5 GB (multipart recommended above 100 MB) |

---

## Study Resources

- [ ] [AWS Developer Associate Exam Guide (DVA-C02)](https://aws.amazon.com/certification/certified-developer-associate/)
- [ ] AWS Skill Builder — Official practice questions
- [ ] Stephane Maarek — Udemy course (DVA-C02)
- [ ] TutorialsDojo practice exams
- [ ] AWS Documentation for services in this guide
- [ ] AWS Workshops (serverless, CI/CD)

---

## Practice Plan

| Week | Focus |
|------|-------|
| 1 | Lambda, API Gateway, DynamoDB, S3 |
| 2 | SQS, SNS, EventBridge, Kinesis, Step Functions |
| 3 | Security (IAM, KMS, Cognito, Secrets Manager) |
| 4 | Deployment (CI/CD tools, SAM, CloudFormation) |
| 5 | Monitoring (CloudWatch, X-Ray) + optimization |
| 6 | Full practice exams + weak area review |

---

*Last updated: 2026-03-23*
