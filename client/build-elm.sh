#!/bin/sh
./format-elm.sh \
  && elm make elm/Index.elm --output=.work/index.js \
  && uglifyjs .work/index.js --mangle --output dist/js/index.min.js --source-map --compress 'pure_funcs="Elm.Index.init,F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' \
  && aws s3 cp dist/js/index.min.js s3://jabara-serverless-app-web/js/index.min.js \
  && aws s3 cp dist/js/index.min.js.map s3://jabara-serverless-app-web/js/index.min.js.map \
  && tsc \
  && browserify .work/app.js | uglifyjs --mangle --output dist/js/app.min.js --source-map --compress \
  && aws s3 cp dist/js/app.min.js s3://jabara-serverless-app-web/js/app.min.js \
  && aws s3 cp dist/js/app.min.js.map s3://jabara-serverless-app-web/js/app.min.js.map \
  && echo finish!
osascript -e 'display notification "Build finish!" with title ""'