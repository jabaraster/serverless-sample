module Types exposing
    ( CognitoErrorInterface
    , PhotoId
    , PhotoMeta
    , SignupResponse(..)
    , SignupResultInterface
    , SignupResultUser
    , UploadStatus(..)
    , VerifyResponse(..)
    , ZonedTime
    , cognitoErrorInterfaceDecoder
    , encodeUploadStatus
    , photoMetaDecoder
    , signupResponseDecoder
    , signupResultUserDecoder
    , uploadStatusDecoder
    , verifyResponseDecoder
    )

import Dict
import Json.Decode as JD
import Json.Encode as JE
import Time exposing (Posix, Zone)
import Tuple


type alias ZonedTime =
    { time : Posix
    , zone : Zone
    }


type UploadStatus
    = Waiting
    | Uploaded
    | Unknown


encodeUploadStatus : UploadStatus -> JE.Value
encodeUploadStatus status =
    JE.string <|
        case status of
            Waiting ->
                "Waiting"

            Uploaded ->
                "Uploaded"

            Unknown ->
                "Unknown"


uploadStatusDecoder : JD.Decoder UploadStatus
uploadStatusDecoder =
    JD.andThen
        (\s ->
            case s of
                "Waiging" ->
                    JD.succeed Waiting

                "Uploaded" ->
                    JD.succeed Uploaded

                _ ->
                    JD.succeed Unknown
        )
        JD.string


type alias PhotoId =
    String


type alias PhotoMeta =
    { photoId : PhotoId
    , size : Int
    , status : UploadStatus
    , timestamp : Int
    , imageType : String
    , signedUrl : Maybe String
    }


photoMetaDecoder : JD.Decoder PhotoMeta
photoMetaDecoder =
    JD.map6 PhotoMeta
        (JD.field "photoId" JD.string)
        (JD.field "size" JD.int)
        (JD.field "status" uploadStatusDecoder)
        (JD.field "timestamp" JD.int)
        (JD.field "type" JD.string)
        (JD.maybe <| JD.field "signedUrl" JD.string)


type SignupResponse
    = SignupError CognitoErrorInterface
    | SignupResult SignupResultInterface


type alias CognitoErrorInterface =
    { code : String
    , message : String
    }


type alias SignupResultInterface =
    { user : SignupResultUser
    }


cognitoErrorInterfaceDecoder : JD.Decoder CognitoErrorInterface
cognitoErrorInterfaceDecoder =
    JD.map2 CognitoErrorInterface
        (JD.field "code" JD.string)
        (JD.field "message" JD.string)


signupErrorDecoder : JD.Decoder (Maybe SignupResponse)
signupErrorDecoder =
    JD.nullable <|
        JD.andThen (JD.succeed << SignupError) cognitoErrorInterfaceDecoder


signupResultInterfaceDecoder : JD.Decoder SignupResultInterface
signupResultInterfaceDecoder =
    JD.map SignupResultInterface
        (JD.field "user" signupResultUserDecoder)


signupResultDecoder : JD.Decoder (Maybe SignupResponse)
signupResultDecoder =
    JD.nullable <|
        JD.andThen (JD.succeed << SignupResult) signupResultInterfaceDecoder


signupResponseDecoder : JD.Decoder SignupResponse
signupResponseDecoder =
    JD.map2 Tuple.pair
        (JD.field "error" signupErrorDecoder)
        (JD.field "result" signupResultDecoder)
        |> JD.andThen
            (\t ->
                case t of
                    ( Just e, Nothing ) ->
                        JD.succeed e

                    ( Nothing, Just r ) ->
                        JD.succeed r

                    _ ->
                        JD.fail "Invalid json string."
            )


type alias SignupResultUser =
    { username : String
    }


signupResultUserDecoder : JD.Decoder SignupResultUser
signupResultUserDecoder =
    JD.map SignupResultUser (JD.field "username" JD.string)


type VerifyResponse
    = VerifyError CognitoErrorInterface
    | VerifyResult


verifyErrorDecoder : JD.Decoder (Maybe VerifyResponse)
verifyErrorDecoder =
    JD.nullable <|
        JD.andThen (JD.succeed << VerifyError) cognitoErrorInterfaceDecoder


verifyResultDecoder : JD.Decoder (Maybe VerifyResponse)
verifyResultDecoder =
    JD.nullable <| JD.succeed VerifyResult


verifyResponseDecoder =
    JD.map2 Tuple.pair
        (JD.field "error" verifyErrorDecoder)
        (JD.field "result" verifyResultDecoder)
        |> JD.andThen
            (\t ->
                case t of
                    ( Just e, Nothing ) ->
                        JD.succeed e

                    ( Nothing, Just r ) ->
                        JD.succeed r

                    _ ->
                        JD.fail "Invalid json string."
            )
