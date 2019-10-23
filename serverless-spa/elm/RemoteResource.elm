module RemoteResource exposing (RemoteResource, empty, emptyLoading, finishLoading, hasData, loadIfNecessary, map, new, startLoading, updateData, updateSuccessData, value, withDummyData)

import Http


type alias RemoteResource a =
    { data : Maybe (Result Http.Error a)
    , dummyData : Maybe a
    , loading : Bool
    }


empty : RemoteResource a
empty =
    { data = Nothing, dummyData = Nothing, loading = False }


emptyLoading : RemoteResource a
emptyLoading =
    { empty | loading = True }


withDummyData : a -> RemoteResource a
withDummyData dummyData =
    { empty | dummyData = Just dummyData }


new : Result Http.Error a -> RemoteResource a
new res =
    { empty | data = Just res }


value : a -> RemoteResource a -> a
value defaultValue rr =
    case rr.data of
        Nothing ->
            defaultValue

        Just (Err _) ->
            defaultValue

        Just (Ok val) ->
            val


map : (a -> b) -> RemoteResource a -> RemoteResource b
map operation rr =
    case rr.data of
        Nothing ->
            { data = Nothing
            , dummyData = Maybe.map operation rr.dummyData
            , loading = rr.loading
            }

        Just (Err e) ->
            { data = Just <| Err e
            , dummyData = Maybe.map operation rr.dummyData
            , loading = rr.loading
            }

        Just (Ok val) ->
            { data = Just <| Ok <| operation val
            , dummyData = Maybe.map operation rr.dummyData
            , loading = rr.loading
            }


updateData : RemoteResource a -> Result Http.Error a -> RemoteResource a
updateData rr newData =
    { rr | data = Just newData, loading = False, dummyData = Nothing }


updateSuccessData : RemoteResource a -> a -> RemoteResource a
updateSuccessData rr newData =
    { rr | data = Just <| Ok newData, loading = False, dummyData = Nothing }


startLoading : RemoteResource a -> RemoteResource a
startLoading rr =
    { rr | loading = True }


finishLoading : RemoteResource a -> RemoteResource a
finishLoading rr =
    { rr | loading = False }


hasData : RemoteResource a -> Bool
hasData =
    Maybe.withDefault False << Maybe.map (\_ -> True) << .data


loadIfNecessary : RemoteResource a -> Cmd msg -> ( RemoteResource a, Cmd msg )
loadIfNecessary rr cmd =
    if hasData rr then
        ( rr, Cmd.none )

    else
        ( startLoading rr, cmd )
