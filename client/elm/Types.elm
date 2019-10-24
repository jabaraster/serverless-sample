module Types exposing (PhotoId, PhotoMeta, UploadStatus(..), ZonedTime, encodeUploadStatus, photoMetaDecoder, uploadStatusDecoder)

import Json.Decode as JD
import Json.Encode as JE
import Time exposing (Posix, Zone)


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
