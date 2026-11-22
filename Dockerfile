# Build the Flutter web app, then serve it with nginx.
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /src
COPY . .
RUN flutter pub get
RUN flutter build web --release --dart-define=VMS_API_BASE_URL=/api

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/build/web /usr/share/nginx/html
EXPOSE 80
