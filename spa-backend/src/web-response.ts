import { APIGatewayProxyResult } from "aws-lambda";

export function ok(body: any, headers: {[key: string]: string} = {}): APIGatewayProxyResult {
  return core(200, body, headers);
}

export function noContent(headers: {[key: string]: string} = {}): APIGatewayProxyResult {
  return core(204, {}, headers);
}

export function okJson(body: any, headers: {[key: string]: string} = {}): APIGatewayProxyResult {
  headers["Content-Type"] = "application/json";
  return core(200, body, headers);
}

export function badRequest(body: any): APIGatewayProxyResult {
  return core(400, body, {});
}

export function internalServerError(body: any): APIGatewayProxyResult {
  return core(500, body, {});
}

function core(statusCode: number, body: any, headers: {[key: string]: string}): APIGatewayProxyResult {
  headers["Access-Control-Allow-Origin"] = "*";
  return {
    statusCode,
    headers,
    body: typeof body === "string" ? body : JSON.stringify(body),
  };
}