# --- STAGE 1: The Builder ---
FROM debian:bookworm-slim AS build-env

# Install dependencies for Flutter
# Install essential tools wget
RUN apt-get update && apt-get install -y curl git unzip xz-utils libglu1-mesa wget


# Download and Setup Flutter SDK
# # Download Flutter - Using a specific stable branch is better for production
# RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
# ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
# 1. Download Flutter SDK as a package (more stable for Render)
RUN wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
# 2. Extract while forcing it to ignore ownership/permission errors
RUN tar -xf flutter_linux_3.24.3-stable.tar.xz -C /usr/local --no-same-owner
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# FIX: Tell Flutter to only care about Web and ignore permission errors
RUN flutter config --no-analytics
RUN flutter config --enable-web

# OPTIMIZATION: Instead of 'flutter doctor', we only fetch the web-sdk
RUN flutter precache --web

# Set the working directory
WORKDIR /app

# OPTIMIZATION: Copy only pubspec files first to cache dependencies
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
