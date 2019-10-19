import { APIGatewayProxyEvent } from "aws-lambda";
import * as Defs from "./defs";
import { handler2, IApiCoreResult } from "./handler-helper";
import { IPhotoMeta } from "./types";
import { badRequest, okJson } from "./web-response";

async function core(evt: APIGatewayProxyEvent): Promise<IApiCoreResult<IPhotoMeta | null>> {
    const photoId = evt.pathParameters!.id;
    if (!photoId) {
        return {
            result: null,
            responseFunction: badRequest,
        };
    }
    const res = await Defs.dynamodb.get({
        TableName: Defs.TABLE_NAME,
        Key: {
            photoId,
        },
    }).promise();
    return {
        result: res.Item as IPhotoMeta,
        responseFunction: okJson,
    };
}

const lambdaHandler = handler2(core);
export { lambdaHandler };