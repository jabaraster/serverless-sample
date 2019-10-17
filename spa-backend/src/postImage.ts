import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import * as AWS from "aws-sdk";
import * as uuid from "uuid";
import * as Defs from "./defs";
import { badRequest, okJson } from "./web-response";

export const generateId = uuid.v4;

export function getTimestamp(): number {
  return new Date().getTime();
}

export function getPresignedUrl(bucketName: AWS.S3.BucketName, key: string): string {
  const params = { Bucket: bucketName, Key: key, Expires: 60 };
  return Defs.s3.getSignedUrl("putObject", params);
}

interface RequestBody {
  type: string;
  size: number;
}
export async function lambdaHandler(evt: APIGatewayEvent): Promise<APIGatewayProxyResult> {
  const body: RequestBody = JSON.parse(evt.body!);
  const item = {
    photo_id: { S: generateId() },
    timestamp: { N: getTimestamp().toString() },
    status: { S: "Waiting" },
    type: { S: body.type },
    size: { N: body.size.toString() },
  };
  try {
    await Defs.dynamodb.putItem({
      TableName: Defs.TABLE_NAME,
      Item: item,
    }, () => {/*dummy*/ }).promise();
    return okJson({
      photoId: item.photo_id.S,
      timestamp: item.timestamp.N,
      status: item.status.S,
      type: item.type.S,
      size: item.size.N,
      signedUrl: getPresignedUrl(Defs.BUCKET_NAME, item.photo_id.S),
    });
  } catch (err) {
    return badRequest(err);
  }
}