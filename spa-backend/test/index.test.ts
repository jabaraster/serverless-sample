import { APIGatewayEvent } from "aws-lambda";
import * as sut from "../src/index";

(async () => {
  try {
    const res = await sut.lambdaHandler(createEvent({
      type: "image/jpeg",
      size: 12000000,
    }));
    console.log(res);
  } catch (err) {
    console.log(`!!! error -> ${err} !!!`);
  }
})();

function createEvent(body: any): APIGatewayEvent {
  return {
    body: JSON.stringify(body),
    headers: {},
    httpMethod: "PUT",
    isBase64Encoded: false,
    multiValueHeaders: {},
    multiValueQueryStringParameters: {},
    path: "",
    pathParameters: {},
    queryStringParameters: {},
    requestContext: {
      accountId: "",
      apiId: "",
      authorizer: null,
      connectedAt: undefined,
      connectionId: "",
      domainName: "",
      domainPrefix: "",
      eventType: "",
      extendedRequestId: "",
      httpMethod: "PUT",
      identity: {
        accessKey: null,
        accountId: null,
        apiKey: null,
        apiKeyId: null,
        caller: null,
        cognitoAuthenticationProvider: null,
        cognitoAuthenticationType: null,
        cognitoIdentityId: null,
        cognitoIdentityPoolId: null,
        sourceIp: "",
        user: null,
        userAgent: null,
        userArn: null,
      },
      messageDirection: "",
      messageId: "",
      path: "",
      requestId: "",
      requestTime: "",
      requestTimeEpoch: 0,
      resourceId: "",
      resourcePath: "",
      routeKey: "",
      stage: "",
    },
    resource: "",
    stageVariables: {},
  };
}