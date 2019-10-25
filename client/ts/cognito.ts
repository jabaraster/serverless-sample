import * as AWS from "aws-sdk";
import {
    AuthenticationDetails,
    CognitoUser,
    CognitoUserAttribute,
    CognitoUserPool,
    ISignUpResult
} from "amazon-cognito-identity-js";

const USER_POOL_ID = "ap-northeast-1_ghBpsqysn";
const USER_POOL_CLIENT_ID = "5kqujpdgbhiend2u84nt246kkh";
const userPool = new CognitoUserPool({
    UserPoolId: USER_POOL_ID,
    ClientId: USER_POOL_CLIENT_ID,
});

interface SignupArg {
    username: string;
    email: string;
    password: string;
}
function signup(arg: SignupArg): Promise<ISignUpResult> {
    return new Promise((resolve, reject) => {
        const attributes = [new CognitoUserAttribute({
            Name: "email",
            Value: arg.email,
        })];
        userPool.signUp(arg.username, arg.password, attributes, [], (err, res) => {
            if (err) {
                console.log("!!! error !!!");
                console.log(err);
                reject(err);
            } else {
                console.log("!!! success !!!");
                console.log(res);
                resolve(res);
            }
        });
    });
}

interface ConfirmArg {
    username: string;
    confirmationCode: string;
}
function confirm_(arg: ConfirmArg): Promise<any> {
    return new Promise((resolve, reject) => {
        const cognitoUser = new CognitoUser({
            Username: arg.username,
            Pool: userPool,
        });
        cognitoUser.confirmRegistration(arg.confirmationCode, true, (err, res) => {
            if (err) {
                console.log("!!! error !!!");
                console.log(err);
                reject(err);
            } else {
                console.log("!!! success !!!");
                console.log(res);
                resolve(res);
            }
        });
    });
}

function registerPort(ports: any, name: string, func: any) {
    if (!ports) { return; }
    const f = ports[name];
    if (f) {
        f.subscribe(func);
    }
}
const w: any = window;
if (w.Elm) {
    const app = w.Elm.Index.init();
    const ports = app.ports;
    registerPort(ports, "signup", signup);
    registerPort(ports, "confirm", confirm_);
}