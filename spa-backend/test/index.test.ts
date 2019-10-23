import { APIGatewayEvent } from "aws-lambda";
import * as getter from "../src/getImages";
import * as poster from "../src/postImage";
import { IPhotoMeta } from "../src/types";
import * as updater from "../src/updateImage";

(async () => {
  try {
    const url = await poster.getPresignedUrl("jabara-serverless-app-photos", "IMG_5097.JPG");
    console.log(`curl -v -X PUT -H "content-type: image/jpeg" -H "content-length: 150756" --upload-file "/Users/jabaraster/Pictures/wallpaper/IMG_5097.JPG" "${url}"`);
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