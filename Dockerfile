# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
ARG API_URL=https://luigis.cl
RUN flutter build web --release --dart-define=API_URL=${API_URL} --base-href=/app/

# Stage 2: Servir con Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html/app
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
