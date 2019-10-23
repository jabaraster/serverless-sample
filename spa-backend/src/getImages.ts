import * as Defs from "./defs";
import { handler, IApiCoreResult } from "./handler-helper";
import { IPhotoMeta } from "./types";
import { okJson } from "./web-response";

async function core(): Promise<IApiCoreResult<IPhotoMeta[]>> {
    const res = await Defs.dynamodb.scan({
        TableName: Defs.TABLE_NAME,
    }).promise();
    const metas = res.Items as IPhotoMeta[];
    metas.sort((a0, a1) => {
        return a1.timestamp - a0.timestamp;
    });
    return {
        result: metas,
        responseFunction: okJson,
    };
}

const lambdaHandler = handler(core);
export {lambdaHandler };