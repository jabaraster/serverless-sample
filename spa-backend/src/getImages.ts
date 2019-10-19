import * as Defs from "./defs";
import { handler, IApiCoreResult } from "./handler-helper";
import { IPhotoMeta } from "./types";
import { okJson } from "./web-response";

async function core(): Promise<IApiCoreResult<IPhotoMeta[]>> {
    const res = await Defs.dynamodb.scan({
        TableName: Defs.TABLE_NAME,
    }).promise();
    return {
        result: res.Items as IPhotoMeta[],
        responseFunction: okJson,
    };
}

const lambdaHandler = handler(core);
export {lambdaHandler };