port module Cognito exposing
    ( signup, signupCallback
    , verify, verifyCallback
    , authenticate, authenticateOnSuccess, authenticateOnFailure, authenticateNewPasswordRequired
    , loggedIn
    , loggedInCallback
    )

{-|

@docs signup, signupCallback
@docs verify, verifyCallback
@docs authenticate, authenticateOnSuccess, authenticateOnFailure, authenticateNewPasswordRequired
@docs loggedIn

-}

import Json.Encode


port signup : { username : String, email : String, password : String } -> Cmd msg


port signupCallback : (Json.Encode.Value -> msg) -> Sub msg


port verify : { username : String, verificationCode : String } -> Cmd msg


port verifyCallback : (Json.Encode.Value -> msg) -> Sub msg


port authenticate : { email : String, password : String } -> Cmd msg


port authenticateOnSuccess : (Json.Encode.Value -> msg) -> Sub msg


port authenticateOnFailure : (Json.Encode.Value -> msg) -> Sub msg


port authenticateNewPasswordRequired : (Json.Encode.Value -> msg) -> Sub msg


port loggedIn : () -> Cmd msg


port loggedInCallback : (Json.Encode.Value -> msg) -> Sub msg
