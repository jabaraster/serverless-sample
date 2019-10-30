module Api exposing
    ( getImages
    , PostPhotoMetaRequest, postPhotoMeta
    , uploadPhotoData
    , updatePhotoMeta
    )

{-|

@docs getImages
@docs PostPhotoMetaRequest, postPhotoMeta
@docs uploadPhotoData
@docs updatePhotoMeta

-}

import Bytes exposing (Bytes)
import File exposing (File)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Time exposing (Posix)
import Types exposing (..)


urlPrefix =
    "https://y3zusjx1h6.execute-api.ap-northeast-1.amazonaws.com/Prod/"


getImages : (Result Http.Error (List PhotoMeta) -> msg) -> Cmd msg
getImages operation =
    Http.get
        { url = urlPrefix ++ "images"
        , expect = Http.expectJson operation <| JD.list photoMetaDecoder
        }


type alias PostPhotoMetaRequest =
    { imageType : String
    , size : Int
    }


encodePostPhotoMetaRequest : PostPhotoMetaRequest -> JE.Value
encodePostPhotoMetaRequest meta =
    JE.object [ ( "type", JE.string meta.imageType ), ( "size", JE.int meta.size ) ]


postPhotoMeta : PostPhotoMetaRequest -> (Result Http.Error PhotoMeta -> msg) -> Cmd msg
postPhotoMeta meta operation =
    Http.request
        { url = urlPrefix ++ "images"
        , body = Http.jsonBody <| encodePostPhotoMetaRequest meta
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
                { url = signedUrl
                , method = "PUT"
                , headers = []
                , body = Http.bytesBody meta.imageType data
                , expect = Http.expectWhatever operation
                , timeout = Nothing
                , tracker = Nothing
                }


encodeUpdatePhotoMetaRequest : PhotoId -> UploadStatus -> Posix -> JE.Value
encodeUpdatePhotoMetaRequest photoId status time =
    JE.object
        [ ( "photoId", JE.string photoId )
        , ( "status"
          , encodeUploadStatus status
          )
        , ( "timestamp", JE.int <| Time.posixToMillis time )
        ]


updatePhotoMeta : PhotoId -> UploadStatus -> Posix -> (Result Http.Error () -> msg) -> Cmd msg
updatePhotoMeta photoId status time operation =
    Http.request
        { url = urlPrefix ++ "images"
        , body = Http.jsonBody <| encodeUpdatePhotoMetaRequest photoId status time
        , expect = Http.expectWhatever operation
        , method = "PUT"
        , headers = []
        , timeout = Nothing
        , tracker = Nothing
        }
