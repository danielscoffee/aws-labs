import * as cdk from "aws-cdk-lib";
import * as dynamodb from "aws-cdk-lib/aws-dynamodb";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as apigw from "aws-cdk-lib/aws-apigateway";
import * as logs from "aws-cdk-lib/aws-logs";
import * as s3 from "aws-cdk-lib/aws-s3";
import { Construct } from "constructs";
import * as path from "path";

export class LambdaApiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // L1 construct (CfnXxx = raw CloudFormation resource)
    // Use L1 when you need a property CDK's L2 doesn't expose yet.
    const rawBucket = new s3.CfnBucket(this, "RawBucket", {
      bucketEncryption: {
        serverSideEncryptionConfiguration: [{
          serverSideEncryptionByDefault: { sseAlgorithm: "AES256" },
        }],
      },
    });

    // L2 construct (opinionated, sane defaults)
	// const table = new dynamodb.Table(this, "Items", {
      partitionKey: { name: "pk", type: dynamodb.AttributeType.STRING },
      sortKey:      { name: "sk", type: dynamodb.AttributeType.STRING },
      billingMode:  dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // dev only
    });

    // GSI added on the L2 Table after construction
    table.addGlobalSecondaryIndex({
      indexName:    "status-index",
      partitionKey: { name: "status", type: dynamodb.AttributeType.STRING },
    });

    const fn = new lambda.Function(this, "ApiHandler", {
      runtime:      lambda.Runtime.PYTHON_3_12,
      handler:      "handler.lambda_handler",
      code:         lambda.Code.fromAsset(path.join(__dirname, "../lambda")),
      tracing:      lambda.Tracing.ACTIVE,          // X-Ray
      logRetention: logs.RetentionDays.ONE_WEEK,
      environment: {
        TABLE_NAME: table.tableName,
      },
    });

    // Grant least-privilege: CDK generates the IAM policy automatically
    table.grantReadWriteData(fn);

    // L3 construct / pattern (composes multiple L2s behind one API) 
    // LambdaRestApi = Lambda + RestApi + proxy resource + stage + permission
    const api = new apigw.LambdaRestApi(this, "Api", {
      handler: fn,
      deployOptions: {
        stageName:      "dev",
        tracingEnabled: true,   // X-Ray on API Gateway too
        loggingLevel:   apigw.MethodLoggingLevel.INFO,
      },
      defaultCorsPreflightOptions: {
        allowOrigins: apigw.Cors.ALL_ORIGINS,
      },
    });

    // Outputs (visible in `cdk deploy` and CloudFormation Outputs tab)
    new cdk.CfnOutput(this, "ApiUrl",    { value: api.url });
    new cdk.CfnOutput(this, "TableName", { value: table.tableName });
    new cdk.CfnOutput(this, "RawBucketRef", { value: rawBucket.ref });
  }
}
