#!/usr/bin/env node
import * as cdk from "aws-cdk-lib";
import { LambdaApiStack } from "../lib/stack";

const app = new cdk.App();

new LambdaApiStack(app, "LambdaApiStack", {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region:  process.env.CDK_DEFAULT_REGION ?? "us-east-1",
  },
});
