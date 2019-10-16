import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import * as AWS from "aws-sdk";
import * as uuid from "uuid";

const BUCKET_NAME = process.env.BUCKET_NAME!;
const TABLE_NAME  = process.env.TABLE_NAME!;

const dynamodb = new AWS.DynamoDB({
  region: "ap-northeast-1",
});
const s3 = new AWS.S3();

export const generateId = uuid.v4;

export function getTimestamp(): number {
  return new Date().getTime();
}

export function getPresignedUrl(bucketName: AWS.S3.BucketName, key: string): string {
  const params = { Bucket: bucketName, Key: key, Expires: 60 };
  return s3.getSignedUrl("putObject", params);
}

interface LambdaHandlerRequest {
  type: string;
  size: number;
}
export async function lambdaHandler(evt: APIGatewayEvent): Promise<APIGatewayProxyResult> {
  const body: LambdaHandlerRequest = JSON.parse(evt.body!);
  const item = {
    photo_id: { S: generateId() },
    timestamp: { N: getTimestamp().toString() },
    status: { S: "Waiting" },
    type: { S: body.type },
    size: { N: body.size.toString() },
  };
  try {
    await dynamodb.putItem({
      TableName: TABLE_NAME,
      Item: item,
    }, () => {/*dummy*/ }).promise();
    return {
      statusCode: 200,
      body: JSON.stringify({
        photoId: item.photo_id.S,
        timestamp: item.timestamp.N,
        status: item.status.S,
        type: item.type.S,
        size: item.size.N,
        signedUrl: getPresignedUrl(BUCKET_NAME, item.photo_id.S),
      }),
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    };
  } catch (err) {
    return {
      statusCode: 400,
      body: err.toString(),
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    };
  }
}