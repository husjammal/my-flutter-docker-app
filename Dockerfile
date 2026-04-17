# --- STAGE 1: The Builder ---
FROM debian:bookworm-slim AS build-env

# Install dependencies for Flutter
RUN apt-get update && apt-get install -y curl git unzip xz-utils libglu1-mesa

# Download and Setup Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor to initialize
RUN flutter doctor

# Set the working directory
WORKDIR /app

# OPTIMIZATION: Copy only pubspec files first to cache dependencies
#(The asterisk * tells Docker: "Copy pubspec.lock if it exists, but don't crash if it doesn't.")
# COPY pubspec.yaml pubspec.lock* ./ 
# RUN flutter pub get

# Copy pubspec files individually to avoid folder-depth confusion
COPY pubspec.yaml /app/pubspec.yaml
COPY pubspec.lock /app/pubspec.lock

# Get dependencies
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Build the web app
RUN flutter build web --release

# --- STAGE 2: The Production Image ---
FROM nginx:alpine

# Copy ONLY the built files from the builder stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

##################
# # Use a tiny Nginx image
# FROM nginx:alpine
# # Remove default Nginx static assets
# RUN rm -rf /usr/share/nginx/html/*
# # Copy the Flutter build files to the Nginx server directory
# COPY build/web /usr/share/nginx/html
# # Expose port 80
# EXPOSE 80
# # Start Nginx
# CMD ["nginx", "-g", "daemon off;"]
##################
