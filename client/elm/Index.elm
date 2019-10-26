module Index exposing (Model, Msg(..), PageState(..), flip, formatComma, imageUrl, imageUrlBase, init, main, routing, subscriptions, update, view, viewForPage, viewMenuLink, viewPreview)

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
import Json.Encode as JE
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


type PageState
    = HomePage
    | SignupPage
    | LoginPage
    | UploadPage
    | SettingsPage
    | NotFoundPage


type alias Model =
    { key : Key
    , pageState : PageState

    -- Images
    , images : RemoteResource (List PhotoMeta)

    -- Photo select
    , selectedImageFile : Maybe File
    , selectedImageUrl : String

    -- Upload photo process
    , uploadPhotoMeta : Maybe PhotoMeta
    , uploading : Bool

    -- Singup or login
    , username : String
    , email : String
    , password : String
    , signupResult : String
    }


type Msg
    = LinkClicked UrlRequest
    | UrlChanged Url
      -- Images load
    | LoadImages
    | ImagesLoaded (Result Http.Error (List PhotoMeta))
    | ImageRequested
      -- Photo select
    | ImageSelected File
    | SelectedImageLoaded String
      -- Upload photo process
    | StartUploadPhotoProcess
    | PostPhotoMetaCompleted (Result Http.Error PhotoMeta)
    | SelectedImageBytesLoaded Bytes
    | CurrentTimeGet Posix
    | UploadPhotoCompleted (Result Http.Error ())
    | UploadStatusUpdated (Result Http.Error ())
      -- Upload photo process
    | UsernameChange String
    | EmailChange String
    | PasswordChange String
      -- Signup
    | Signup
    | SignupCallback JE.Value


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        page =
            routing url

        model =
            { key = key
            , pageState = page
            , images = RemoteResource.empty
            , selectedImageFile = Nothing
            , selectedImageUrl = ""
            , uploadPhotoMeta = Nothing
            , uploading = False
            , username = ""
            , email = ""
            , password = ""
            , signupResult = ""
            }
    in
    case page of
        HomePage ->
            ( { model | images = RemoteResource.startLoading model.images }
            , Api.getImages ImagesLoaded
            )

        _ ->
            ( model, Cmd.none )


routing : Url -> PageState
routing url =
    Maybe.withDefault NotFoundPage <|
        UP.parse
            (UP.oneOf
                [ UP.s "index.html"
                    </> UP.fragment
                            (\mv ->
                                case mv of
                                    Just "login" ->
                                        LoginPage

                                    Just "signup" ->
                                        SignupPage

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
                    routing url

                newModel =
                    { model | pageState = page }
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

        LoadImages ->
            ( { model | images = RemoteResource.startLoading model.images }
            , Api.getImages ImagesLoaded
            )

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
                    ( { model
                        | uploading = True
                      }
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
            let
                newModel =
                    { model
                        | selectedImageFile = Nothing
                        , selectedImageUrl = ""
                        , uploadPhotoMeta = Nothing
                        , uploading = False
                    }
            in
            case model.uploadPhotoMeta of
                Nothing ->
                    ( newModel, Cmd.none )

                Just meta ->
                    ( { newModel
                        | images = RemoteResource.map (flip (++) [ meta ]) model.images
                      }
                    , Nav.pushUrl model.key "/index.html"
                    )

        UsernameChange v ->
            ( { model | username = v }, Cmd.none )

        EmailChange v ->
            ( { model | email = v }, Cmd.none )

        PasswordChange v ->
            ( { model | password = v }, Cmd.none )

        Signup ->
            ( { model | uploading = True }
            , Cognito.signup
                { username = model.username
                , email = model.email
                , password = model.password
                }
            )

        SignupCallback v ->
            Debug.log "" ( { model | signupResult = JE.encode 0 v }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Cognito.signupCallback SignupCallback


view : Model -> Document Msg
view model =
    let
        doc =
            viewForPage model

        loading =
            if isLoading model then
                [ span [ class "fas fa-spinner loading loading-icon" ] [] ]

            else
                []

        header =
            div [ class "header" ]
                [ div [ class "pure-menu pure-menu-horizontal" ]
                    [ a [ class "pure-menu-heading", href "" ] [ text "Photo Gallery" ]
                    , ul [ class "pure-menu-list" ]
                        [ viewMenuLink { currentPageState = model.pageState, menuPageState = HomePage, fragment = "", labelText = "Home" }
                        , viewMenuLink { currentPageState = model.pageState, menuPageState = UploadPage, fragment = "upload", labelText = "Upload" }
                        , viewMenuLink { currentPageState = model.pageState, menuPageState = SettingsPage, fragment = "settings", labelText = "Settings" }
                        , viewMenuLink { currentPageState = model.pageState, menuPageState = SignupPage, fragment = "signup", labelText = "Signup" }
                        , viewMenuLink { currentPageState = model.pageState, menuPageState = LoginPage, fragment = "login", labelText = "Login" }
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
        loading ++ [ header, textHead, div [ class "pure-g" ] doc.body, footer ]
    }


viewMenuLink :
    { currentPageState : PageState
    , menuPageState : PageState
    , fragment : String
    , labelText : String
    }
    -> Html Msg
viewMenuLink arg =
    li [ class "pure-menu-item", classList [ ( "pure-menu-selected", arg.currentPageState == arg.menuPageState ) ] ]
        [ a [ class "pure-menu-link", href <| "#" ++ arg.fragment ] [ text arg.labelText ] ]


viewForPage : Model -> Document Msg
viewForPage model =
    case model.pageState of
        HomePage ->
            { title = "Home"
            , body =
                [ div [] <|
                    List.map
                        (\image ->
                            div [ class "photo pure-u-1-3 pure-u-md-1-3 pure-u-lg-1-3 pure-u-xl-1-3" ]
                                [ a [ href <| imageUrl image, target "_blank" ]
                                    [ img [ src <| imageUrl image ] []
                                    ]
                                ]
                        )
                        (RemoteResource.value [] model.images)
                , button [ class "pure-button", onClick LoadImages ] [ span [ class "fas fa-sync" ] [], text "Reload" ]
                ]
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
            , body =
                [ div [ class "pure-u-1 form-box l-box" ]
                    [ h2 [] [ text "Login" ]
                    , div [ class "pure-form pure-form-stacked" ]
                        [ viewUsername
                        , viewEmail
                        , viewPassword
                        , button [ class "pure-button pure-button-primary" ] [ text "Singup" ]
                        ]
                    ]
                ]
            }

        SignupPage ->
            { title = "Signup"
            , body =
                [ div [ class "pure-u-1 form-box l-box" ]
                    [ h2 [] [ text "Signup" ]
                    , Html.form [ class "pure-form pure-form-stacked" ]
                        [ viewUsername
                        , viewEmail
                        , viewPassword
                        , button [ onClick Signup, class "pure-button pure-button-primary" ] [ text "Singup" ]
                        ]
                    ]
                ]
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


isLoading : Model -> Bool
isLoading model =
    model.images.loading
        || model.uploading


viewUsername =
    label [] [ input [ onInput UsernameChange, type_ "text", placeholder "Username" ] [] ]


viewEmail =
    label [] [ input [ onInput EmailChange, type_ "email", placeholder "Email" ] [] ]


viewPassword =
    label [] [ input [ onInput PasswordChange, type_ "password", placeholder "Password" ] [] ]