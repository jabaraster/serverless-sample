port module Cognito exposing (errors, signup, signupSuccess)


port signup : { username : String, email : String, password : String } -> Cmd msg


port errors : (String -> msg) -> Sub msg


port signupSuccess : ({ username : String } -> msg) -> Sub msg
