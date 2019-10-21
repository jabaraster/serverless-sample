module Index exposing (Model, Msg(..), Page(..), init, main, parseUrl, subscriptions, update, view)

import Api
import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import File exposing (File)
import File.Select as Select
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import List.Extra as LE
import List.Split as LS
import RemoteResource exposing (RemoteResource)
import Task
import Types exposing (PhotoMeta)
import Url exposing (Url)
import Url.Parser exposing (..)


main : Platform.Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


type Page
    = HomePage


type alias Model =
    { key : Key
    , page : Page
    , images : RemoteResource (List PhotoMeta)
    , selectedImageFile : Maybe File
    , selectedImageUrl : String
    }


type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
    | ImagesLoaded (Result Http.Error (List PhotoMeta))
    | ImageRequested
    | ImageSelected File
    | SelectedImageLoaded String


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        page =
            parseUrl url
    in
    case page of
        HomePage ->
            ( { key = key
              , page = page
              , images = RemoteResource.emptyLoading
              , selectedImageFile = Nothing
              , selectedImageUrl = ""
              }
            , Api.getImages ImagesLoaded
            )


parseUrl : Url -> Page
parseUrl url =
    Maybe.withDefault HomePage <|
        Url.Parser.parse
            (Url.Parser.oneOf
                [ Url.Parser.map HomePage Url.Parser.top
                ]
            )
            url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                page =
                    parseUrl url
            in
            case page of
                HomePage ->
                    ( { model | page = page }, Cmd.none )

        ImagesLoaded res ->
            ( { model | images = RemoteResource.updateData model.images res }, Cmd.none )

        ImageRequested ->
            ( model
            , Select.file [ "image/*" ] ImageSelected
            )

        ImageSelected file ->
            ( { model | selectedImageFile = Just file }
            , Task.perform SelectedImageLoaded <| File.toUrl file
            )

        SelectedImageLoaded url ->
            ( { model | selectedImageUrl = url }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Document Msg
view model =
    let
        doc =
            viewForPage model
    in
    { title = doc.title
    , body =
        div [ class "header" ]
            [ div [ class "pure-menu pure-menu-horizontal" ]
                [ a [ class "pure-menu-heading", href "" ] [ text "Photo Gallery" ]
                , ul [ class "pure-menu-list" ]
                    [ li [ class "pure-menu-item pure-menu-selected" ] [ a [ class "pure-menu-link", href "#" ] [ text "Home" ] ]
                    , li [ class "pure-menu-item" ] [ a [ class "pure-menu-link", href "#upload-image" ] [ text "Upload" ] ]
                    , li [ class "pure-menu-item" ] [ a [ class "pure-menu-link", href "#" ] [ text "Settings" ] ]
                    , li [ class "pure-menu-item" ] [ a [ class "pure-menu-link", href "#" ] [ text "Login" ] ]
                    ]
                ]
            ]
            :: doc.body
            ++ [ div [ class "footer" ] [ text "This sample app made by jabaraster." ] ]
    }


viewPreview : Maybe File -> String -> Html Msg
viewPreview mFile url =
    case mFile of
        Nothing ->
            text ""

        Just file ->
            div []
                [ div [] [ text <| "Type: " ++ File.mime file ]
                , div [] [ text <| "Size: " ++ (formatComma <| File.size file) ]
                , img [ src url, class "preview" ] []
                ]


viewForPage : Model -> Document Msg
viewForPage model =
    let
        title =
            "Home"

        base =
            div [ class "text-box pure-u-1 pure-u-md-1 pure-u-lg-1 pure-u-xl-1" ]
                [ div [ class "l-box" ]
                    [ h1 [ class "text-box-head" ] [ text "Photo Garally" ]
                    , p [ class "text-box-subhead" ] [ text "A collection of various photos from around the world" ]
                    ]
                ]

        form =
            div [ class "pure-u-1 form-box" ]
                [ div [ class "l-box" ]
                    [ h2 [] [ text "Upload a Photo" ]

                    -- , input [ type_ "file", placeholder "Photo from your computer", accept "image/*", required True ] []
                    , button [ onClick ImageRequested, class "pure-button" ] [ text "Select" ]
                    , viewPreview model.selectedImageFile model.selectedImageUrl
                    , button [ class "pure-button pure-button-primary" ] [ text "Upload" ]
                    ]
                ]
    in
    case model.page of
        HomePage ->
            case model.images.data of
                Nothing ->
                    { title = title
                    , body =
                        [ div [ class "pure-g" ]
                            [ text "Now loading..."
                            , form
                            ]
                        ]
                    }

                Just (Ok images) ->
                    { title = title
                    , body =
                        [ div [ class "pure-g" ] <|
                            base
                                :: List.map
                                    (\image ->
                                        div [ class "photo pure-u-1-3 pure-u-md-1-3 pure-u-lg-1-3 pure-u-xl-1-3" ]
                                            [ img [ src <| imageUrl image ] []
                                            ]
                                    )
                                    images
                                ++ [ form ]
                        ]
                    }

                _ ->
                    { title = "Home"
                    , body =
                        [ div [ class "pure-g" ]
                            [ base
                            , p [] [ text "Fail loading..." ]
                            , form
                            ]
                        ]
                    }


imageUrlBase =
    "https://jabara-serverless-app-photos.s3-ap-northeast-1.amazonaws.com/"


imageUrl : PhotoMeta -> String
imageUrl image =
    let
        tokens =
            String.split image.imageType
    in
    case LE.getAt 1 <| String.split "/" image.imageType of
        Nothing ->
            imageUrlBase ++ image.photoId

        Just suf ->
            imageUrlBase ++ image.photoId ++ "." ++ suf


formatComma : Int -> String
formatComma =
    String.join "," << List.reverse << List.map String.fromList << LS.chunksOfRight 3 << String.toList << String.fromInt
