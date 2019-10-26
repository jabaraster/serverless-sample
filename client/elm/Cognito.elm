port module Cognito exposing (confirm, confirmCallback, errors, signup, signupCallback, signupSuccess)

import Json.Encode


port signup : { username : String, email : String, password : String } -> Cmd msg


port signupCallback : (Json.Encode.Value -> msg) -> Sub msg


port confirm : { username : String, confirmationCode : String } -> Cmd msg


port confirmCallback : (Json.Encode.Value -> msg) -> Sub msg


port errors : (String -> msg) -> Sub msg


port signupSuccess : ({ username : String } -> msg) -> Sub msg
