import {
    AuthenticationDetails,
    CognitoUser,
    CognitoUserAttribute,
    CognitoUserPool,
    CognitoUserSession,
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

    authenticate: ISubscriber;
    authenticateOnSuccess: ISender;
    authenticateOnFailure: ISender;
    authenticateNewPasswordRequired: ISender;

    loggedIn: ISubscriber;
    loggedInCallback: ISender;
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

export interface AuthenticateArg {
    email: string;
    password: string;
}
export function authenticate(ports: IPorts): (_: AuthenticateArg) => void {
    return (arg: AuthenticateArg) => {
        const authenticationDetails = new AuthenticationDetails({
            Username: arg.email,
            Password: arg.password,
        });
        const cognitoUser = new CognitoUser({
            Username: arg.email,
            Pool: userPool,
        });
        cognitoUser.authenticateUser(authenticationDetails, {
            onSuccess: (
                session: CognitoUserSession,
                userConfirmationNecessary?: boolean,
            ) => {
                ports.authenticateOnSuccess.send({ session, userConfirmationNecessary });
            },
            onFailure: (err) => {
                ports.authenticateOnFailure.send(err);
            },
            newPasswordRequired: (
                userAttributes: any,
                requiredAttributes: any,
            ) => {
                ports.authenticateNewPasswordRequired.send({ userAttributes, requiredAttributes });
            },
        });
    };
}

export function loggedIn(ports: IPorts): () => void {
    return async () => {
        const currentUser = userPool.getCurrentUser();
        if (!currentUser) {
            ports.loggedInCallback.send(false);
            return;
        }

        try {
            const session = currentUser.getSession((a: any) => {
                console.log(`In getSession: ${a}`);
            });
            console.log(`Session: ${session}`);
            ports.loggedInCallback.send(false);

        } catch (err) {
            console.log("!!! error !!!");
            console.log(err);
            ports.loggedInCallback.send(false);
        }
    };
}