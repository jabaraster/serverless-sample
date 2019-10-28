port module Cognito exposing (errors, signup, signupCallback, signupSuccess, verify, verifyCallback)

import Json.Encode


port signup : { username : String, email : String, password : String } -> Cmd msg


port signupCallback : (Json.Encode.Value -> msg) -> Sub msg


port verify : { username : String, verificationCode : String } -> Cmd msg


port verifyCallback : (Json.Encode.Value -> msg) -> Sub msg


port errors : (String -> msg) -> Sub msg


port signupSuccess : ({ username : String } -> msg) -> Sub msg
