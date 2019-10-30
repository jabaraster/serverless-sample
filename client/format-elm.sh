#!/bin/sh
elm-format elm/Api.elm --output elm/Api.elm --yes \
  && elm-format elm/Index.elm --output elm/Index.elm --yes \
  && elm-format elm/RemoteResource.elm --output elm/RemoteResource.elm --yes \
  && elm-format elm/Types.elm --output elm/Types.elm --yes \
  && elm-format elm/Cognito.elm --output elm/Cognito.elm --yes