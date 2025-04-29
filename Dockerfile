# Build stage - use a more complete Node image
FROM node:20 as build

WORKDIR /app

# Install build essentials and debugging tools
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    make \
    g++ \
    curl \
    procps

# Copy package files first for better caching
COPY package*.json ./

# Try different install approaches with detailed logging
RUN node -v && \
    echo "Attempting npm install with detailed logs..." && \
    npm install --verbose || \
    (echo "Standard install failed, trying with ignore-scripts..." && \
    npm install --ignore-scripts --verbose)

# Copy source code (after dependencies are installed)
COPY . .

# Build with proper error output
RUN echo "Starting build process..." && \
    npm run build || \
    (echo "Build failed. Check logs:" && \
    cat $(find /root/.npm/_logs -type f -name "*-debug-0.log" | sort -r | head -n1) && \
    exit 1)

# Copy .env if it exists (will not fail if file doesn't exist)
COPY .env ./dist/

# Production stage - we only need the dist files
FROM node:20-alpine

WORKDIR /app

# Copy only the built files from build stage
COPY --from=build /app/dist ./dist