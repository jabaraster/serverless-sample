import { handler, IApiCoreResult } from "./handler-helper";
import { ok } from "./web-response";

async function core(): Promise<IApiCoreResult<void>> {
    return {
        responseFunction: ok,
    };
}

const lambdaHandler = handler(core);
export { lambdaHandler };