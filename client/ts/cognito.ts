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

export interface ISubscriber {
    subscribe: (_: any) => void;
}
export interface ISender {
    send: (_: any) => void;
}
export interface IPorts {
    signup?: ISubscriber;
    signupCallback: ISender;

    confirm?: ISubscriber;
    confirmCallback: ISender;
}

export interface IApp {
    ports: IPorts;
}

export interface SignupArg {
    username: string;
    email: string;
    password: string;
}
export function signup(ports: IPorts): (_: SignupArg) => void {
    return (arg: SignupArg) => {
        const attributes = [new CognitoUserAttribute({
            Name: "email",
            Value: arg.email,
        })];
        userPool.signUp(arg.username, arg.password, attributes, [], (error, result) => {
            ports.signupCallback.send({ error, result });
        });
    };
}

export interface ConfirmArg {
    username: string;
    confirmationCode: string;
}
export function confirm(ports: IPorts): (_: ConfirmArg) => void {
    return (arg: ConfirmArg) => {
        const cognitoUser = new CognitoUser({
            Username: arg.username,
            Pool: userPool,
        });
        cognitoUser.confirmRegistration(arg.confirmationCode, true, (error, result) => {
            ports.confirmCallback.send({ error, result });
        });
    };
}