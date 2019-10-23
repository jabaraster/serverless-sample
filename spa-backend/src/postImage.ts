import { APIGatewayProxyEvent } from "aws-lambda";
import * as AWS from "aws-sdk";
import * as uuid from "uuid";
import * as Defs from "./defs";
import { handler2, IApiCoreResult } from "./handler-helper";
import { IPhotoMeta } from "./types";
import { okJson } from "./web-response";

export const generateId = uuid.v4;

export function getTimestamp(): number {
  return new Date().getTime();
}

export async function getPresignedUrl(bucketName: AWS.S3.BucketName, key: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const params = {
      Bucket: bucketName,
      Key: key,
      Expires: 600,
    };
    Defs.s3.getSignedUrl("putObject", params, (err, url) => {
      if (err) {
        reject(err);
      } else {
        resolve(url);
      }
    });
  });
}

interface RequestBody {
  type: string;
  size: number;
}

async function core(evt: APIGatewayProxyEvent): Promise<IApiCoreResult<IPhotoMeta>> {
  const body: RequestBody = JSON.parse(evt.body!);
  const item: IPhotoMeta = {
    photoId: generateId(),
    timestamp: getTimestamp(),
    status: "Waiting",
    type: body.type,
    size: body.size,
    signedUrl: undefined,
  };
  await Defs.dynamodb.put({
    TableName: Defs.TABLE_NAME,
    Item: item,
  }).promise();
  item.signedUrl = await getPresignedUrl(Defs.BUCKET_NAME, `${item.photoId}.${body.type.split("/")[1]}`);
  return {
    result: item,
    responseFunction: okJson,
  };
}
const lambdaHandler = handler2(core);
export { lambdaHandler };