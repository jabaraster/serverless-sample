import * as cognito from "./cognito";

(() => {
    const Elm = (window as any).Elm;
    if (!Elm) { return; }

    const app = Elm.Index.init() as cognito.IApp;
    const ports = app.ports;
    if (!ports) { return; }

    const f = (callback: any, sub?: cognito.ISubscriber) => {
        if (!sub) { return; }
        sub.subscribe(callback);
    };
    console.log(ports);
    f(cognito.signup(ports), ports.signup);
    f(cognito.confirm(ports), ports.confirm);
})();