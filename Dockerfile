# ---- Build stage: compile the static site with Node 22 ----
# Use the pinned Node 22 Alpine base image for the builder (never :latest).
FROM node:22-alpine AS builder

# Create a working directory inside the builder image.
WORKDIR /app

# Copy only the dependency manifests first so npm ci can be cached.
COPY package.json package-lock.json ./

# Install exactly the locked dependency versions (no package-lock changes).
RUN npm ci

# Copy the remaining source files (HTML pages and shared stylesheet).
COPY src ./src
COPY styles ./styles

# Build all HTML entry points into /app/dist with relative asset URLs.
RUN npm run build

# ---- Runtime stage: serve the built site with pinned Alpine nginx ----
# Use the pinned nginx 1.27 Alpine base image for the small runtime image.
FROM nginx:1.27-alpine AS runtime

# Serve on the standard HTTP port inside the container.
EXPOSE 80

# Copy only the compiled static output from the builder stage.
COPY --from=builder /app/dist/ /usr/share/nginx/html/

# Start nginx in the foreground so the container stays alive and logs to stdout.
CMD ["nginx", "-g", "daemon off;"]
