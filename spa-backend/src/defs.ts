import * as AWS from "aws-sdk";

export type Status = "Waiting" | "Completed";

export const BUCKET_NAME = process.env.BUCKET_NAME!;
export const TABLE_NAME = process.env.TABLE_NAME!;

export const dynamodb = new AWS.DynamoDB({
  region: "ap-northeast-1",
});
export const s3 = new AWS.S3();