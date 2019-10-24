lessc less/photo.less > .work/photo.css \
  && cleancss .work/photo.css --output dist/css/photo.min.css \
  && aws s3 cp dist/css/photo.min.css s3://jabara-serverless-app-web/css/photo.min.css