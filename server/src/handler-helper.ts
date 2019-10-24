import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { internalServerError } from "./web-response";

export interface IApiCoreResult<R> {
    result?: R;
    responseHeaders?: { [key: string]: string };
    responseFunction: ((body?: any, headers?: { [key: string]: string }) => APIGatewayProxyResult);
}

export function handler<R>(func: () => Promise<IApiCoreResult<R>>): () => Promise<APIGatewayProxyResult> {
    return async () => {
        try {
            const res = await func();
            return res.responseFunction(res.result, res.responseHeaders);
        } catch (err) {
            console.log("!!! error !!!");
            console.log(err);
            console.log(JSON.stringify(err));
            return internalServerError({ errorMessage: err.message });
        }
    };
}

export function handler2<R>(
    func: (e: APIGatewayProxyEvent) => Promise<IApiCoreResult<R>>,
): (e: APIGatewayProxyEvent) => Promise<APIGatewayProxyResult> {
    return async (e: APIGatewayProxyEvent) => {
        try {
            const res = await func(e);
            return res.responseFunction(res.result, res.responseHeaders);
        } catch (err) {
            console.log("!!! error !!!");
            console.log(err);
            console.log(JSON.stringify(err));
            return internalServerError({ errorMessage: err.message });
        }
    };
}