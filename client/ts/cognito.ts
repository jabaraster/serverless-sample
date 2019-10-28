import {
    CognitoUser,
    CognitoUserAttribute,
    CognitoUserPool,
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

    verify?: ISubscriber;
    verifyCallback: ISender;
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

export interface VerifyArg {
    username: string;
    verificationCode: string;
}
export function verify(ports: IPorts): (_: VerifyArg) => void {
    return (arg: VerifyArg) => {
        const cognitoUser = new CognitoUser({
            Username: arg.username,
            Pool: userPool,
        });
        cognitoUser.confirmRegistration(arg.verificationCode, true, (error, result) => {
            ports.verifyCallback.send({ error, result });
        });
    };
}