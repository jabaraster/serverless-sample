import * as AWS from "aws-sdk";
// import {
//     CognitoUserPool,
//     CognitoUserAttribute,
//     AuthenticationDetails,
//     CognitoUser
// } from "amazon-cognito-identity-js";

const USER_POOL_ID = "ap-northeast-1_ghBpsqysn";
const USER_POOL_CLIENT_ID = "5kqujpdgbhiend2u84nt246kkh";


interface SignupArg {
    username: string;
    email: string;
    password: string;
}
function signup(arg: SignupArg) {
    console.log(`signup! username: ${arg.username} email: ${arg.email} password: ${arg.password}`);
};

function confirm_(username: string, confirmationNumber: number) {
    console.log("confirm!");
};

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