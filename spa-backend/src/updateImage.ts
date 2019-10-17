import { APIGatewayEvent, APIGatewayProxyResult } from "aws-lambda";
import * as Defs from "./defs";
import { badRequest, okJson } from "./web-response";

interface RequestBody {
  photoId: string;
  timestamp: number;
  status: Defs.Status;
}

export async function lambdaHandler(evt: APIGatewayEvent): Promise<APIGatewayProxyResult> {
  console.log(evt.body);
  const body: RequestBody = JSON.parse(evt.body!);
  if (!validate(body)) {
    return badRequest("Validation error.");
  }
  await Defs.dynamodb.updateItem({
    TableName: Defs.TABLE_NAME,
    Key: {
      photoId: { S: body.photoId },
    },
    AttributeUpdates: {
      status: {
        Value: { S: body.status.toString() },
        Action: "PUT",
      },
    },
  }, () => {/*dummy*/ }).promise();
  return okJson({});
}

function validate(body: RequestBody): boolean {
  const hasError = !body.photoId
    || (body.timestamp === null || body.timestamp === undefined)
    || !body.status
    ;
  return !hasError;
}