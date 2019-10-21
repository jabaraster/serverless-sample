module Api exposing (getImages)

import Http
import Json.Decode as D
import Types exposing (..)


urlPrefix =
    "https://y3zusjx1h6.execute-api.ap-northeast-1.amazonaws.com/Prod/"


getImages : (Result Http.Error (List PhotoMeta) -> msg) -> Cmd msg
getImages operation =
    Http.get
        { url = urlPrefix ++ "images"
        , expect = Http.expectJson operation <| D.list photoMetaDecoder
        }
