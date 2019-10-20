import { APIGatewayProxyEvent } from "aws-lambda";
import * as Defs from "./defs";
import { handler2, IApiCoreResult } from "./handler-helper";
import { badRequest, noContent } from "./web-response";

async function core(evt: APIGatewayProxyEvent): Promise<IApiCoreResult<null>> {
    const photoId = evt.pathParameters!.id;
    if (!photoId) {
        return {
            result: null,
            responseFunction: badRequest,
        };
    }
    await Defs.dynamodb.delete({
        TableName: Defs.TABLE_NAME,
        Key: {
            photoId,
        },
    }).promise();
    return {
        responseFunction: noContent,
    };
}

const lambdaHandler = handler2(core);
export { lambdaHandler };