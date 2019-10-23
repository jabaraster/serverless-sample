import { APIGatewayEvent } from "aws-lambda";
import * as Defs from "./defs";
import { handler2, IApiCoreResult } from "./handler-helper";
import { IPhotoMeta } from "./types";
import { badRequest, okJson } from "./web-response";

interface RequestBody {
  photoId: string;
  timestamp: number;
  status: Defs.Status;
}

async function core(evt: APIGatewayEvent): Promise<IApiCoreResult<string | IPhotoMeta>> {
  const body: RequestBody = JSON.parse(evt.body!);
  if (!validate(body)) {
    return {
      result: "Validation error.",
      responseFunction: badRequest,
    };
  }
  await Defs.dynamodb.update({
    TableName: Defs.TABLE_NAME,
    Key: {
      photoId: body.photoId,
    },
    AttributeUpdates: {
      status: {
        Value: body.status,
      },
    },
  }).promise();
  const res = await Defs.dynamodb.get({
    TableName: Defs.TABLE_NAME,
    Key: {
      photoId: body.photoId,
    },
  }).promise();
  return {
    result: res.Item as IPhotoMeta,
    responseFunction: okJson,
  };
}

function validate(body: RequestBody): boolean {
  const hasError = !body.photoId
    || (body.timestamp === null || body.timestamp === undefined)
    || !body.status
    ;
  return !hasError;
}

const lambdaHandler = handler2(core);
export { lambdaHandler };