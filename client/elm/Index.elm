module Index exposing (Model, Msg(..), Page(..), init, main, parseUrl, subscriptions, update, view)

import Api
import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import Bytes exposing (Bytes)
import Cognito
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
import Time exposing (Posix)
import Types exposing (PhotoMeta, UploadStatus(..))
import Url exposing (Url)
import Url.Parser as UP exposing ((</>))


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
    | LoginPage
    | UploadPage
    | SettingsPage
    | NotFoundPage


type alias Model =
    { key : Key
    , page : Page
    , images : RemoteResource (List PhotoMeta)
    , selectedImageFile : Maybe File
    , selectedImageUrl : String
    , uploadPhotoMeta : Maybe PhotoMeta
    }


type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
    | ImagesLoaded (Result Http.Error (List PhotoMeta))
    | ImageRequested
    | ImageSelected File
    | SelectedImageLoaded String
    | StartUploadPhotoProcess
    | PostPhotoMetaCompleted (Result Http.Error PhotoMeta)
    | SelectedImageBytesLoaded Bytes
    | CurrentTimeGet Posix
    | UploadPhotoCompleted (Result Http.Error ())
    | UploadStatusUpdated (Result Http.Error ())


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        page =
            parseUrl url

        model =
            { key = key
            , page = page
            , images = RemoteResource.emptyLoading
            , selectedImageFile = Nothing
            , selectedImageUrl = ""
            , uploadPhotoMeta = Nothing
            }
    in
    case page of
        HomePage ->
            ( model
            , Api.getImages ImagesLoaded
            )

        _ ->
            ( model, Cmd.none )


parseUrl : Url -> Page
parseUrl url =
    Debug.log "" <|
        Maybe.withDefault NotFoundPage <|
            UP.parse
                (UP.oneOf
                    [ UP.s "index.html"
                        </> UP.fragment
                                (\mv ->
                                    case mv of
                                        Just "login" ->
                                            LoginPage

                                        Just "upload" ->
                                            UploadPage

                                        Just "settings" ->
                                            SettingsPage

                                        Just "" ->
                                            HomePage

                                        Just _ ->
                                            NotFoundPage

                                        Nothing ->
                                            HomePage
                                )
                    , UP.map HomePage <| UP.s "index.html"
                    , UP.map HomePage UP.top
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

                newModel =
                    { model | page = page }
            in
            case page of
                HomePage ->
                    let
                        ( newRr, cmd ) =
                            RemoteResource.loadIfNecessary model.images <| Api.getImages ImagesLoaded
                    in
                    ( { newModel | images = newRr }, cmd )

                _ ->
                    ( newModel, Cmd.none )

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

        StartUploadPhotoProcess ->
            case model.selectedImageFile of
                Nothing ->
                    ( model, Cmd.none )

                Just file ->
                    ( model
                    , Api.postPhotoMeta { imageType = File.mime file, size = File.size file } PostPhotoMetaCompleted
                    )

        PostPhotoMetaCompleted res ->
            case model.selectedImageFile of
                Nothing ->
                    ( model, Cmd.none )

                Just file ->
                    case res of
                        Err _ ->
                            ( model, Cmd.none )

                        Ok meta ->
                            ( { model | uploadPhotoMeta = Just meta }
                            , Task.perform SelectedImageBytesLoaded <| File.toBytes file
                            )

        SelectedImageBytesLoaded data ->
            case model.uploadPhotoMeta of
                Nothing ->
                    ( model, Cmd.none )

                Just meta ->
                    ( model
                    , Api.uploadPhotoData data meta UploadPhotoCompleted
                    )

        UploadPhotoCompleted res ->
            ( model, Task.perform CurrentTimeGet Time.now )

        CurrentTimeGet now ->
            case model.uploadPhotoMeta of
                Nothing ->
                    ( model, Cmd.none )

                Just meta ->
                    ( model
                    , Api.updatePhotoMeta meta.photoId Uploaded now UploadStatusUpdated
                    )

        UploadStatusUpdated _ ->
            case model.uploadPhotoMeta of
                Nothing ->
                    ( { model
                        | selectedImageFile = Nothing
                        , selectedImageUrl = ""
                        , uploadPhotoMeta = Nothing
                      }
                    , Cmd.none
                    )

                Just meta ->
                    let
                        wm =
                            { model
                                | selectedImageFile = Nothing
                                , selectedImageUrl = ""
                                , uploadPhotoMeta = Nothing
                            }
                    in
                    ( { wm | images = RemoteResource.map (flip (++) [ meta ]) model.images }
                    , Cmd.batch
                        [ Cognito.signup { username = "jabara", email = "ah@jabara.info", password = "pass" }
                        , Nav.pushUrl model.key "/index.html"
                        ]
                    )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


view : Model -> Document Msg
view model =
    let
        doc =
            viewForPage model

        header =
            div [ class "header" ]
                [ div [ class "pure-menu pure-menu-horizontal" ]
                    [ a [ class "pure-menu-heading", href "" ] [ text "Photo Gallery" ]
                    , ul [ class "pure-menu-list" ]
                        [ li [ class "pure-menu-item pure-menu-selected" ] [ a [ class "pure-menu-link", href "#" ] [ text "Home" ] ]
                        , li [ class "pure-menu-item" ] [ a [ class "pure-menu-link", href "#upload" ] [ text "Upload" ] ]
                        , li [ class "pure-menu-item" ] [ a [ class "pure-menu-link", href "#settings" ] [ text "Settings" ] ]
                        , li [ class "pure-menu-item" ] [ a [ class "pure-menu-link", href "#login" ] [ text "Login" ] ]
                        ]
                    ]
                ]

        textHead =
            div [ class "text-box pure-u-1 pure-u-md-1 pure-u-lg-1 pure-u-xl-1" ]
                [ div [ class "l-box" ]
                    [ h1 [ class "text-box-head" ] [ text "Photo Garally" ]
                    , p [ class "text-box-subhead" ] [ text "A collection of various photos from around the world" ]
                    ]
                ]

        footer =
            div [ class "footer" ] [ text "This sample app made by jabaraster." ]
    in
    { title = doc.title
    , body =
        [ header, textHead, div [ class "pure-g" ] doc.body, footer ]
    }


viewForPage : Model -> Document Msg
viewForPage model =
    case model.page of
        HomePage ->
            { title = "Home"
            , body =
                List.map
                    (\image ->
                        div [ class "photo pure-u-1-3 pure-u-md-1-3 pure-u-lg-1-3 pure-u-xl-1-3" ]
                            [ a [ href <| imageUrl image, target "_blank" ]
                                [ img [ src <| imageUrl image ] []
                                ]
                            ]
                    )
                    (RemoteResource.value [] model.images)
            }

        UploadPage ->
            { title = "Upload"
            , body =
                [ div [ class "pure-u-1 form-box" ]
                    [ div [ class "l-box" ]
                        [ h2 [] [ text "Upload a Photo" ]
                        , button [ onClick ImageRequested, class "pure-button" ] [ text "Select" ]
                        , viewPreview model.selectedImageFile model.selectedImageUrl
                        , button [ onClick StartUploadPhotoProcess, class "pure-button pure-button-primary" ] [ text "Upload" ]
                        ]
                    ]
                ]
            }

        SettingsPage ->
            { title = "Settings"
            , body = [ text "Settings" ]
            }

        LoginPage ->
            { title = "Login"
            , body = [ text "Login" ]
            }

        NotFoundPage ->
            { title = "Not found"
            , body = [ text "Not found" ]
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


imageUrlBase =
    "https://jabara-serverless-app-photos.s3-ap-northeast-1.amazonaws.com/"


imageUrl : PhotoMeta -> String
imageUrl image =
    imageUrlBase ++ image.photoId


formatComma : Int -> String
formatComma =
    String.join "," << List.reverse << List.map String.fromList << LS.chunksOfRight 3 << String.toList << String.fromInt


flip : (a -> b -> c) -> b -> a -> c
flip f b a =
    f a b
