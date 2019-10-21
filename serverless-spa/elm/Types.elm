module Types exposing (PhotoMeta, Status(..), photoMetaDecoder, statusDecoder)

import Json.Decode as D


type Status
    = Waiting
    | Uploaded
    | Unknown


statusDecoder : D.Decoder Status
statusDecoder =
    D.andThen
        (\s ->
            case s of
                "Waiging" ->
                    D.succeed Waiting

                "Uploaded" ->
                    D.succeed Uploaded

                _ ->
                    D.succeed Unknown
        )
        D.string


type alias PhotoMeta =
    { photoId : String
    , size : Int
    , status : Status
    , timestamp : Int
    , imageType : String
    , signedUrl : Maybe String
    }


photoMetaDecoder : D.Decoder PhotoMeta
photoMetaDecoder =
    D.map6 PhotoMeta
        (D.field "photoId" D.string)
        (D.field "size" D.int)
        (D.field "status" statusDecoder)
        (D.field "timestamp" D.int)
        (D.field "type" D.string)
        (D.maybe <| D.field "signedUrl" D.string)
