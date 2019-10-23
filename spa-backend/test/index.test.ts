import { APIGatewayEvent } from "aws-lambda";
import * as getter from "../src/getImages";
import * as poster from "../src/postImage";
import { IPhotoMeta } from "../src/types";
import * as updater from "../src/updateImage";

(async () => {
  try {
    const postRes = await poster.lambdaHandler(createEvent({
      type: "image/png",
      size: 100039,
    }));
    console.log(postRes);

    const photoMeta: IPhotoMeta = JSON.parse(postRes.body);
    const updateRes = await updater.lambdaHandler(createEvent({
      photoId: photoMeta.photoId,
      timestamp: 10939348,
      status: "Uploaded",
    }));
    console.log("-----------------------");
    console.log(updateRes);

    console.log("-----------------------");
    console.log(await getter.lambdaHandler());

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