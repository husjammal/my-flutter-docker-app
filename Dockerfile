# --- STAGE 1: The Builder ---
# FROM debian:bookworm-slim AS build-env

# # Install dependencies for Flutter
# # Install essential tools wget
# RUN apt-get update && apt-get install -y curl git unzip xz-utils libglu1-mesa wget


# # Download and Setup Flutter SDK
# # # Download Flutter - Using a specific stable branch is better for production
# RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
# ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"


# # FIX: Tell Flutter to only care about Web and ignore permission errors
# # THE FIX: Disable everything except web to stop the Gradle download
# # This prevents Flutter from trying to download Gradle in the background
# ENV FLUTTER_NO_AUTOMATIC_COMPONENTS=true
# RUN flutter config --no-analytics --no-enable-android --no-enable-ios --enable-web

# # 3. Manually download only the internal Dart SDK for Web
# # We avoid 'flutter precache' entirely because it triggers the Gradle download
# RUN flutter doctor -v

# # Set the working directory
# WORKDIR /app

# # OPTIMIZATION: Copy only pubspec files first to cache dependencies
# # Copy pubspec files individually to avoid folder-depth confusion
# COPY pubspec.yaml /app/pubspec.yaml
# # We skip copying pubspec.lock for a moment to let Flutter resolve the best versions
# # COPY pubspec.lock /app/pubspec.lock

# #'pub get' will download the Dart SDK components without triggering the Gradle download
# RUN flutter pub get

# # Copy the rest of the source code
# COPY . .

# # Using --no-pub ensures we don't trigger background checks
# RUN flutter build web --release --no-pub

# --- STAGE 2: The Production Image ---
# Use a tiny Nginx image
FROM nginx:alpine

# Clean the default directory
RUN rm -rf /usr/share/nginx/html/*

# Copy ONLY the built files from the builder stage
COPY build/web /usr/share/nginx/html
# Expose port 80
EXPOSE 80
# Start Nginx
CMD ["nginx", "-g", "daemon off;"]