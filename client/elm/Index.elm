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
import Json.Decode as JD
import Json.Encode as JE
import List.Extra as LE
import List.Split as LS
import RemoteResource exposing (RemoteResource)
import Task
import Time exposing (Posix)
import Types exposing (AuthenticationFailure, AuthenticationFailureCode(..), PhotoMeta, SignupResponse(..), UploadStatus(..), VerifyResponse(..))
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
    | VerificationPage
    | NotFoundPage


type alias Model =
    { -- General
      key : Key
    , pageState : PageState
    , errorMessages : List String
    , communicating : Bool

    -- Images
    , images : RemoteResource (List PhotoMeta)

    -- Photo select
    , selectedImageFile : Maybe File
    , selectedImageUrl : String

    -- Upload photo process
    , uploadPhotoMeta : Maybe PhotoMeta

    -- Singup or login
    , username : String
    , email : String
    , password : String
    , signupErrorMessage : String
    , verificationCode : String
    , loggedIn : Bool
    }


addErrorMessage : String -> Model -> Model
addErrorMessage s model =
    { model | errorMessages = s :: model.errorMessages }


type Msg
    = -- General
      LinkClicked UrlRequest
    | UrlChanged Url
      -- Images load
    | LoadImages
    | ImagesLoaded (Result Http.Error (List PhotoMeta))
    | ImageRequested
      -- Photo selecs
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
    | SignupCallback (Result JD.Error SignupResponse)
    | VerificationCodeChange String
    | Verify
    | VerifyCallback (Result JD.Error VerifyResponse)
      -- Login
    | Authenticate
    | AuthenticateOnSuccess JE.Value
    | AuthenticateOnFailure (Result JD.Error AuthenticationFailure)
    | AuthenticateNewPasswordRequired JE.Value
    | LoggedInCallback (Result JD.Error Bool)
    | Logout
    | LogoutCallback JE.Value


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    ( { key = key
      , pageState = routing url
      , errorMessages = []
      , communicating = False
      , images = RemoteResource.empty
      , selectedImageFile = Nothing
      , selectedImageUrl = ""
      , uploadPhotoMeta = Nothing
      , username = ""
      , email = ""
      , password = ""
      , signupErrorMessage = ""
      , verificationCode = ""
      , loggedIn = False
      }
    , Cognito.loggedIn ()
    )


basePath =
    "index.html"


pageStateToUrl : PageState -> String
pageStateToUrl page =
    case page of
        HomePage ->
            "/" ++ basePath

        SignupPage ->
            "/" ++ basePath ++ "#signup"

        LoginPage ->
            "/" ++ basePath ++ "#login"

        UploadPage ->
            "/" ++ basePath ++ "#upload"

        SettingsPage ->
            "/" ++ basePath ++ "#settings"

        VerificationPage ->
            "/" ++ basePath ++ "#verification"

        NotFoundPage ->
            "/" ++ basePath


routing : Url -> PageState
routing url =
    Maybe.withDefault NotFoundPage <|
        UP.parse
            (UP.oneOf
                [ UP.s basePath
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

                                    Just "verification" ->
                                        VerificationPage

                                    Just "" ->
                                        HomePage

                                    Just _ ->
                                        NotFoundPage

                                    Nothing ->
                                        HomePage
                            )
                , UP.map HomePage <| UP.s basePath
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
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | pageState = routing url }, Cognito.loggedIn () )

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
                        | communicating = True
                      }
                    , Api.postPhotoMeta { imageType = File.mime file, size = File.size file } PostPhotoMetaCompleted
                    )

        PostPhotoMetaCompleted res ->
            case model.selectedImageFile of
                Nothing ->
                    ( { model | communicating = False }, Cmd.none )

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
                    ( { model | communicating = False }, Cmd.none )

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
                        , communicating = False
                    }
            in
            case model.uploadPhotoMeta of
                Nothing ->
                    ( newModel, Cmd.none )

                Just meta ->
                    ( { newModel
                        | images = RemoteResource.map ((::) meta) model.images
                      }
                    , Nav.pushUrl model.key <| pageStateToUrl HomePage
                    )

        UsernameChange v ->
            ( { model | username = v }, Cmd.none )

        EmailChange v ->
            ( { model | email = v }, Cmd.none )

        PasswordChange v ->
            ( { model | password = v }, Cmd.none )

        Signup ->
            ( { model | communicating = True }
            , Cognito.signup
                { username = model.username
                , email = model.email
                , password = model.password
                }
            )

        SignupCallback res ->
            let
                newModel =
                    { model | communicating = False }
            in
            case res of
                Err err ->
                    ( addErrorMessage (JD.errorToString err) newModel, Cmd.none )

                Ok (SignupError err) ->
                    ( { newModel | signupErrorMessage = err.message }, Cmd.none )

                Ok (SignupResult _) ->
                    ( { newModel | signupErrorMessage = "" }
                    , Nav.pushUrl model.key <| pageStateToUrl VerificationPage
                    )

        VerificationCodeChange v ->
            ( { model | verificationCode = v }, Cmd.none )

        Verify ->
            ( { model | communicating = True }
            , Cognito.verify { username = model.username, verificationCode = model.verificationCode }
            )

        VerifyCallback res ->
            let
                newModel =
                    { model | communicating = False }
            in
            case res of
                Err err ->
                    ( addErrorMessage (JD.errorToString err) newModel, Cmd.none )

                Ok (VerifyError err) ->
                    ( { newModel | signupErrorMessage = err.message }, Cmd.none )

                Ok VerifyResult ->
                    ( { newModel
                        | signupErrorMessage = ""
                        , username = ""
                        , email = ""
                        , password = ""
                        , verificationCode = ""
                      }
                    , Nav.pushUrl model.key <| pageStateToUrl LoginPage
                    )

        Authenticate ->
            ( { model | communicating = True }
            , Cognito.authenticate { email = model.email, password = model.password }
            )

        AuthenticateOnSuccess v ->
            ( { model
                | communicating = False
                , loggedIn = True
                , username = ""
                , email = ""
                , password = ""
                , signupErrorMessage = ""
              }
            , Nav.pushUrl model.key <| pageStateToUrl HomePage
            )

        AuthenticateOnFailure res ->
            case res of
                Err err ->
                    ( { model
                        | communicating = False
                        , signupErrorMessage = JD.errorToString err
                      }
                    , Cmd.none
                    )

                Ok fail ->
                    ( { model
                        | communicating = False
                        , signupErrorMessage = Types.authenticationFailureCodeToString fail.code ++ ": " ++ fail.message
                      }
                    , Cmd.none
                    )

        AuthenticateNewPasswordRequired v ->
            ( { model | communicating = False, signupErrorMessage = JE.encode 0 v }, Cmd.none )

        LoggedInCallback res ->
            case res of
                Err err ->
                    ( addErrorMessage (JD.errorToString err) model, Cmd.none )

                Ok True ->
                    case model.pageState of
                        HomePage ->
                            let
                                ( rr, cmd ) =
                                    RemoteResource.loadIfNecessary model.images <| Api.getImages ImagesLoaded
                            in
                            ( { model | images = rr, loggedIn = True }, cmd )

                        _ ->
                            ( { model | loggedIn = True }, Cmd.none )

                Ok False ->
                    case model.pageState of
                        LoginPage ->
                            ( model, Cmd.none )

                        SignupPage ->
                            ( model, Cmd.none )

                        VerificationPage ->
                            ( model, Cmd.none )

                        _ ->
                            ( model, Nav.pushUrl model.key <| pageStateToUrl LoginPage )

        Logout ->
            ( { model
                | communicating = True
              }
            , Cognito.logout ()
            )

        LogoutCallback _ ->
            ( { model
                | loggedIn = False
                , communicating = False
              }
            , Nav.pushUrl model.key <| pageStateToUrl LoginPage
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Cognito.signupCallback (JD.decodeValue Types.signupResponseDecoder) |> Sub.map SignupCallback
        , Cognito.verifyCallback (JD.decodeValue Types.verifyResponseDecoder) |> Sub.map VerifyCallback
        , Cognito.authenticateOnSuccess AuthenticateOnSuccess
        , Cognito.authenticateOnFailure (JD.decodeValue Types.authenticationFailureDecoder) |> Sub.map AuthenticateOnFailure
        , Cognito.authenticateNewPasswordRequired AuthenticateNewPasswordRequired
        , Cognito.loggedInCallback (JD.decodeValue JD.bool) |> Sub.map LoggedInCallback
        , Cognito.logoutCallback LogoutCallback
        ]


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

        menus =
            [ ( model.loggedIn, viewMenuLink { currentPageState = model.pageState, menuPageState = HomePage, labelText = "Home" } )
            , ( model.loggedIn, viewMenuLink { currentPageState = model.pageState, menuPageState = UploadPage, labelText = "Upload" } )
            , ( model.loggedIn, viewMenuLink { currentPageState = model.pageState, menuPageState = SettingsPage, labelText = "Settings" } )
            , ( not model.loggedIn, viewMenuLink { currentPageState = model.pageState, menuPageState = SignupPage, labelText = "Signup" } )
            , ( not model.loggedIn, viewMenuLink { currentPageState = model.pageState, menuPageState = LoginPage, labelText = "Login" } )
            , ( model.loggedIn
              , li [ class "pure-menu-item" ]
                    [ a [ onClick Logout, class "pure-menu-link", href "#logout" ] [ text "Logout" ] ]
              )
            ]

        header =
            div [ class "header" ]
                [ div [ class "pure-menu pure-menu-horizontal" ]
                    [ a [ class "pure-menu-heading", href "" ] [ text "Photo Gallery" ]
                    , ul [ class "pure-menu-list" ] <|
                        List.map Tuple.second <|
                            List.filter Tuple.first menus
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
    , labelText : String
    }
    -> Html Msg
viewMenuLink arg =
    li [ class "pure-menu-item", classList [ ( "pure-menu-selected", arg.currentPageState == arg.menuPageState ) ] ]
        [ a [ class "pure-menu-link", href <| pageStateToUrl arg.menuPageState ] [ text arg.labelText ] ]


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
                        [ viewInput { type_ = "text", value = model.email, inputChange = EmailChange, placeholder = "Username of Email" }
                        , viewPassword model.password
                        , button [ onClick Authenticate, class "pure-button pure-button-primary" ] [ text "Singup" ]
                        ]
                    , hr [] []
                    , span [ class "error" ] [ text model.signupErrorMessage ]
                    ]
                ]
            }

        SignupPage ->
            { title = "Signup"
            , body =
                [ div [ class "pure-u-1 form-box l-box" ]
                    [ h2 [] [ text "Signup" ]
                    , div [ class "pure-form pure-form-stacked" ]
                        [ viewInput { type_ = "text", value = model.username, inputChange = UsernameChange, placeholder = "Username" }
                        , viewInput { type_ = "text", value = model.email, inputChange = EmailChange, placeholder = "Email" }
                        , viewPassword model.password
                        , button [ onClick Signup, class "pure-button pure-button-primary" ] [ text "Singup" ]
                        ]
                    , hr [] []
                    , span [ class "error" ] [ text model.signupErrorMessage ]
                    ]
                ]
            }

        VerificationPage ->
            { title = "Verification"
            , body =
                [ div [ class "pure-u-1 form-box l-box" ]
                    [ h2 [] [ text "Signup verification" ]
                    , p [] [ text "Verification sent your email address." ]
                    , div [ class "pure-form pure-form-stacked" ]
                        [ input [ type_ "text", value model.verificationCode, onInput VerificationCodeChange, placeholder "Verification code" ] []
                        , button [ onClick Verify, class "pure-button pure-button-primary" ] [ text "Confirm" ]
                        ]
                    , hr [] []
                    , span [ class "error" ] [ text model.signupErrorMessage ]
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
    "https://jabara-serverless-app-photobucket-18s89yqnj4w3.s3-ap-northeast-1.amazonaws.com/"


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
        || model.communicating


viewInput :
    { value : String
    , type_ : String
    , placeholder : String
    , inputChange : String -> Msg
    }
    -> Html Msg
viewInput arg =
    label [] [ input [ onInput arg.inputChange, value arg.value, type_ arg.type_, placeholder arg.placeholder ] [] ]


viewPassword : String -> Html Msg
viewPassword val =
    viewInput { type_ = "password", value = val, inputChange = PasswordChange, placeholder = "Password" }
