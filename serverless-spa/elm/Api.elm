module Api exposing (PostPhotoMeta, encodePostPhotoMeta, getImages, postPhotoMeta, uploadPhotoData, urlPrefix)

import Bytes exposing (Bytes)
import File exposing (File)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Types exposing (..)


urlPrefix =
    "https://y3zusjx1h6.execute-api.ap-northeast-1.amazonaws.com/Prod/"


getImages : (Result Http.Error (List PhotoMeta) -> msg) -> Cmd msg
getImages operation =
    Http.get
        { url = urlPrefix ++ "images"
        , expect = Http.expectJson operation <| JD.list photoMetaDecoder
        }


type alias PostPhotoMeta =
    { imageType : String
    , size : Int
    }


encodePostPhotoMeta : PostPhotoMeta -> JE.Value
encodePostPhotoMeta meta =
    JE.object [ ( "type", JE.string meta.imageType ), ( "size", JE.int meta.size ) ]


postPhotoMeta : PostPhotoMeta -> (Result Http.Error PhotoMeta -> msg) -> Cmd msg
postPhotoMeta meta operation =
    Http.riskyRequest
        { url = urlPrefix ++ "images"
        , body = Http.jsonBody <| encodePostPhotoMeta meta
        , expect = Http.expectJson operation photoMetaDecoder
        , method = "POST"
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }


uploadPhotoData : Bytes -> PhotoMeta -> (Result Http.Error () -> msg) -> Cmd msg
uploadPhotoData data meta operation =
    case meta.signedUrl of
        Nothing ->
            Cmd.none

        Just signedUrl ->
            Http.request
                { url = Debug.log "Signed Url" signedUrl
                , method = "PUT"
                , headers = []
                , body = Http.bytesBody meta.imageType data
                , expect = Http.expectWhatever operation
                , timeout = Nothing
                , tracker = Nothing
                }
